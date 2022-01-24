#include "FX2.Common.fxh"

#ifndef FX2_MAGNIFY_ALWAYS_ON
	#define FX2_MAGNIFY_ALWAYS_ON 0
#elif FX2_MAGNIFY_ALWAYS_ON != 0 && FX2_MAGNIFY_ALWAYS_ON != 1
	#warning "FX2_MAGNIFY_ALWAYS_ON should be set to 0 or 1. Falling back to 0."
	#undef FX2_MAGNIFY_ALWAYS_ON
	#define FX2_MAGNIFY_ALWAYS_ON 0
#endif

#ifndef FX2_MAGNIFY_LINEAR
	#define FX2_MAGNIFY_LINEAR 1
#elif FX2_MAGNIFY_LINEAR != 0 && FX2_MAGNIFY_LINEAR != 1
	#warning "FX2_MAGNIFY_LINEAR should be set to 0 or 1. Falling back to 1."
	#undef FX2_MAGNIFY_LINEAR
	#define FX2_MAGNIFY_LINEAR 1
#endif

#if FX2_MAGNIFY_ALWAYS_ON
	#undef FX2_MAGNIFY_SMOOTH
	#undef FX2_MAGNIFY_KEY
	#undef FX2_MAGNIFY_MOUSE_BUTTON
	#undef FX2_MAGNIFY_TOGGLE
	#define FX2_MAGNIFY_SMOOTH 0
	#define FX2_MAGNIFY_KEY 0
	#define FX2_MAGNIFY_MOUSE_BUTTON -1
	#define FX2_MAGNIFY_TOGGLE 0
#else
	#ifndef FX2_MAGNIFY_SMOOTH
		#define FX2_MAGNIFY_SMOOTH 1
	#elif FX2_MAGNIFY_SMOOTH != 0 && FX2_MAGNIFY_SMOOTH != 1
		#warning "FX2_MAGNIFY_SMOOTH should be set to 0 or 1. Falling back to 1."
		#undef FX2_MAGNIFY_SMOOTH
		#define FX2_MAGNIFY_SMOOTH 1
	#endif

	#ifndef FX2_MAGNIFY_KEY
		#define FX2_MAGNIFY_KEY FX2_KEY_ALT
	#endif

	#ifndef FX2_MAGNIFY_MOUSE_BUTTON
		#define FX2_MAGNIFY_MOUSE_BUTTON -1
	#elif FX2_MAGNIFY_MOUSE_BUTTON < -1 || FX2_MAGNIFY_MOUSE_BUTTON > 4
		#warning "FX2_MAGNIFY_MOUSE_BUTTON should be set between -1 and 4. Falling back to -1."
		#undef FX2_MAGNIFY_MOUSE_BUTTON
		#define FX2_MAGNIFY_MOUSE_BUTTON -1
	#endif

	#ifndef FX2_MAGNIFY_TOGGLE
		#define FX2_MAGNIFY_TOGGLE 0
	#elif FX2_MAGNIFY_TOGGLE != 0 && FX2_MAGNIFY_TOGGLE != 1
		#warning "FX2_MAGNIFY_MOUSE_BUTTON should be set to 0 or 1. Falling back to 0."
		#undef FX2_MAGNIFY_TOGGLE
		#define FX2_MAGNIFY_TOGGLE 0
	#endif
#endif

#if FX2_MAGNIFY_LINEAR
	#define _COLOR_SAMPLER ColorLinear
#else
	#define _COLOR_SAMPLER ColorPoint
#endif

namespace FX2
{
	#if FX2_MAGNIFY_ALWAYS_ON
		#define _ALWAYS_ON_HELP ""
	#else
		#define _ALWAYS_ON_HELP \
			"Follow Cursor:\n" \
			"  Default: Off\n" \
			"  If turned on, the effect with center on the cursor location " \
			"on the screen.\n" \
			"\n" \
			"FX2_MAGNIFY_SMOOTH:\n" \
			"  Default: On\n" \
			"  Set to 1 to enable a smooth zooming animation or 0 for an " \
			"instant effect.\n" \
			"\n" \
			"FX2_MAGNIFY_KEY:\n" \
			"  Default: FX2_KEY_ALT\n" \
			"  Sets the key that activates the effect.\n" \
			"  Values should be virtual keycodes or one of the available " \
			"values defined in FX2.Common.fxh (which start with " \
			"\"FX2_KEY_\").\n" \
			"\n" \
			"FX2_MAGNIFY_MOUSE_BUTTON:\n" \
			"  Default: -1\n" \
			"  Set to a value between 0 through 4 to use a mouse button " \
			"instead of a keyboard key to activate the effect.\n" \
			"  Set to -1 to disable this feature.\n" \
			"\n" \
			"FX2_MAGNIFY_TOGGLE:\n" \
			"  Default: Off\n" \
			"  Set to 1 to have the effect toggle between active and " \
			"inactive when the set key or mouse button is pressed.\n" \
			"  Set to 0 to disable this feature.\n" \
			"\n"
	#endif

	#if FX2_MAGNIFY_SMOOTH
		#define _SMOOTHNESS_HELP \
			"Smoothness:\n" \
			"  Default: 1.0\n" \
			"  Time in seconds for the zooming animation.\n" \
			"\n"
	#else
		#define _SMOOTHNESS_HELP ""
	#endif

	FX2_HELP(
		"Magnification:\n"
		"  Default: 1.5\n"
		"  Multiplies the magnification effect.\n"
		"\n"
		_SMOOTHNESS_HELP
		_ALWAYS_ON_HELP
		"FX2_MAGNIFY_ALWAYS_ON:\n"
		"  Default: Off\n"
		"  Set to 1 to have the effect be always active.\n"
		"  Set to 0 to disable this feature.\n"
		"  Useful for using ReShade's own hotkey feature instead of "
		"the shader's.\n"
		"\n"
		"FX2_MAGNIFY_LINEAR:\n"
		"  Default: 1\n"
		"  Set to 1 for linear filtering or 0 for nearest-point.\n"
		"  No performance impact.\n"
	);

	#undef _SMOOTHNESS_HELP

	uniform float Magnification
	<
		ui_type = "slider";
		ui_min = 1.0;
		ui_max = 10.0;
		ui_step = 0.1;
	> = 1.5;

#if FX2_MAGNIFY_SMOOTH
	uniform float Smoothness
	<
		ui_type = "slider";
		ui_min = 0.1;
		ui_max = 3.0;
		ui_step = 0.1;
	> = 1.0;

	uniform float FrameTime < source = "frametime"; >;
#endif

	uniform bool FollowCursor < ui_label = "Follow Cursor"; > = false;

	uniform float2 CursorPos < source = "mousepoint"; >;

#if !FX2_MAGNIFY_ALWAYS_ON
	uniform bool KeyPressed
	<
	#if FX2_MAGNIFY_MOUSE_BUTTON >= 0
		source = "mousebutton";
		keycode = FX2_MAGNIFY_MOUSE_BUTTON;
	#else
		source = "key";
		keycode = FX2_MAGNIFY_KEY;
	#endif
	#if FX2_MAGNIFY_TOGGLE
		mode = "toggle";
	#endif
	>;
#endif

#if FX2_MAGNIFY_SMOOTH
	texture LastTex { Format = R16F; };

	texture ValueTex { Format = R16F; };

	sampler Value { Texture = ValueTex; };

	sampler Last { Texture = LastTex; };
#endif

#if FX2_MAGNIFY_SMOOTH
	float2 TransformUV(float2 uv, float value)
#else
	float2 TransformUV(float2 uv, bool keyPressed)
#endif
	{
		float2 center = FollowCursor ? CursorPos * GetPixelSize() : 0.5;
		float mag = 1.0 / Magnification;
	#if FX2_MAGNIFY_SMOOTH
		mag = lerp(1.0, 1.0 / Magnification, value);
		return ScaleUV(uv, mag, center);
	#else
		return keyPressed ? ScaleUV(uv, mag, center) : uv;
	#endif
	}

#if FX2_MAGNIFY_SMOOTH
	float GetValuePS(float4 p : SV_Position) : SV_Target
	{
		float t = FrameTime * 0.01 / Smoothness;
		return lerp(tex2Dfetch(Last, 0).x, KeyPressed, t);
	}

	float SaveValuePS(float4 p : SV_Position) : SV_Target
	{
		return tex2Dfetch(Value, 0).x;
	}
#endif

	float4 MainPS(ShaderParams p) : SV_Target
	{
	#if FX2_MAGNIFY_SMOOTH
		float value = tex2Dfetch(Value, 0).x;
	#elif FX2_MAGNIFY_ALWAYS_ON
		bool value = true;
	#else
		bool value = KeyPressed;
	#endif
		return tex2D(_COLOR_SAMPLER, TransformUV(p.uv, value));
	}

	technique FX2_Magnify
	{
	#if FX2_MAGNIFY_SMOOTH
		pass
		{
			VertexShader = EmptyVS;
			PixelShader = GetValuePS;
			RenderTarget = ValueTex;
		}
		pass
		{
			VertexShader = EmptyVS;
			PixelShader = SaveValuePS;
			RenderTarget = LastTex;
		}
	#endif
		pass
		{
			VertexShader = ScreenVS;
			PixelShader = MainPS;
		}
	}
}
