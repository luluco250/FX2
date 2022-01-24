#include "FX2.Common.fxh"

#ifndef FX2_CHROMATIC_SAMPLES
#define FX2_CHROMATIC_SAMPLES 1
#endif

#if FX2_CHROMATIC_SAMPLES < 1
	#warning "FX2_CHROMATIC_SAMPLES must be greater than 0. Falling back to 1."
	#undef FX2_CHROMATIC_SAMPLES
	#define FX2_CHROMATIC_SAMPLES 1
#endif

namespace FX2
{
	static const float BasePan = 1.0;
	static const float BaseScale = 5.0;

	FX2_HELP(
		"Mode:\n"
		"  Default: Scale\n"
		"  Determines how the color channels will be shifted:\n"
		"    - Pan: Shift color channels diagonally.\n"
		"    - Scale: Shift color channels radially (\"zooming in\").\n"
		"\n"
		"Scale:\n"
		"  Default: 1.0\n"
		"  Determines how much to spread the color channels.\n"
		"\n"
		"Channels:\n"
		"  Default: (1, 0, -1)\n"
		"  Determines how each color channel is shifted.\n"
		"  The first value controls the red, second green and third blue.\n"
		"  Values of 1 or -1 shift the channel in a positive or negative "
		"direction respectively. 0 keeps the color channel untouched.\n"
		"\n"
		"FX2_CHROMATIC_SAMPLES:\n"
		"  Default: 1\n"
		"  If greater than 1, sets how many samples to accumulate from the "
		"image to create a smoother/blurred effect.\n"
		"  Set to 1 to disable this feature.\n"
	);

	uniform int Mode
	<
		ui_type = "combo";
		ui_items = "Pan\0Scale\0";
	> = 1;

	uniform float Scale
	<
		ui_type = "slider";
		ui_min = 0;
		ui_max = 10;
		ui_step = 0.1;
	> = 1.0;

	uniform float3 Channels
	<
		ui_type = "slider";
		ui_min = -1;
		ui_max = 1;
		ui_step = 1;
	> = float3(1, 0, -1);

	float ApplyPan(int comp, float2 uv, float2 ps)
	{
		return tex2D(
			ColorLinear,
			uv - Channels[comp] * ps * Scale * BasePan
		)[comp];
	}

	float ApplyScale(int comp, float2 uv, float2 ps)
	{
		return tex2D(
			ColorLinear,
			ScaleUV(uv, 1.0 + ps * Channels[comp] * Scale * BaseScale)
		)[comp];
	}

	float4 MainPS(ShaderParams p) : SV_Target
	{
		float4 color = 0.0;
		float2 ps = GetPixelSize();

		#define _FOR_COMP(i) \
			[unroll] \
			for (int i = 0; i < 3; ++i)
		#define _FOR_SAMPLES(i) \
			[unroll] \
			for (int i = 1; i <= FX2_CHROMATIC_SAMPLES; ++i)

		float4 curr;

		// Pan
		if (Mode == 0)
		{
			_FOR_SAMPLES(i)
			{
				float2 scale = ps * i / FX2_CHROMATIC_SAMPLES;

				_FOR_COMP(j)
				{
					curr[j] = ApplyPan(j, p.uv, scale);
				}

				color += curr;
			}
		}
		// Scale
		else
		{
			_FOR_SAMPLES(i)
			{
				float2 scale = ps * i / FX2_CHROMATIC_SAMPLES;

				_FOR_COMP(j)
				{
					curr[j] = ApplyScale(j, p.uv, scale);
				}

				color += curr;
			}
		}

		color /= FX2_CHROMATIC_SAMPLES;

		#undef _FOR_COMP
		#undef _FOR_SAMPLES

		return color;
	}

	technique FX2_Chromatic
	<
		tooltip =
			"Transforms RGB color channels individually for a chromatic"
			"aberration lens effect."
			;
	>
	{
		pass
		{
			VertexShader = ScreenVS;
			PixelShader = MainPS;
		}
	}
}
