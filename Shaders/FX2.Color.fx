/*
	Based on John Hable's article on Minimal Color Grading Tools:
	http://filmicworlds.com/blog/minimal-color-grading-tools/
*/

#include "FX2.Common.fxh"

#ifndef FX2_COLOR_SRGB
#define FX2_COLOR_SRGB 0
#endif

namespace FX2
{
	static const float3 LumaWeights = float3(0.25, 0.5, 0.25);
	static const float LogMidpoint = 0.18;
	static const float Epsilon = 0.00001;

	uniform float Exposure
	<
		ui_type = "slider";
		ui_min = -5.0;
		ui_max = 5.0;
		ui_step = 0.1;
	> = 0.0;

	uniform float Contrast
	<
		ui_type = "slider";
		ui_min = -3.0;
		ui_max = 3.0;
		ui_step = 0.1;
	> = 0.0;

	uniform float Saturation
	<
		ui_type = "slider";
		ui_min = 0.0;
		ui_max = 3.0;
		ui_step = 0.1;
	> = 1.0;

// #if !FX2_COLOR_SRGB
	uniform float Gamma
	<
		ui_type = "slider";
		ui_min = 1.0;
		ui_max = 5.0;
		ui_step = 0.1;
	> = 2.2;
// #endif

	uniform float3 ColorFilter
	<
		ui_type = "color";
	> = 1.0;

	sampler Color
	{
		Texture = ColorTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	#if FX2_COLOR_SRGB
		SRGBTexture = true;
	#endif
	};

	void ApplyExposure(inout float3 color)
	{
		color.rgb *= exp2(Exposure) * ColorFilter;
	}

	void ApplySaturation(inout float3 color)
	{
		float3 gray = dot(color.rgb, LumaWeights);
		color.rgb = saturate(gray + (color.rgb - gray) * Saturation);
	}

	void ApplyContrast(inout float3 color)
	{
		float3 logColor = log2(color + Epsilon);
		float3 adjust = LogMidpoint + (logColor - LogMidpoint) * exp2(Contrast);
		color.rgb = max(0.0, exp2(adjust) - Epsilon);
	}

	float4 MainPS(ShaderParams p) : SV_TARGET
	{
		float4 color = tex2D(Color, p.uv);
	// #if !FX2_COLOR_SRGB
	// #endif

		ApplyExposure(color.rgb);
		ApplySaturation(color.rgb);
		ApplyContrast(color.rgb);

	// #if !FX2_COLOR_SRGB
		color.rgb = pow(abs(color.rgb), 2.2);
		color.rgb = pow(abs(color.rgb), 1.0 / Gamma);
	// #endif
		return color;
	}

	technique FX2_Color
	{
		pass
		{
			VertexShader = ScreenVS;
			PixelShader = MainPS;
		#if FX2_COLOR_SRGB
			SRGBWriteEnable = true;
		#endif
		}
	}
}
