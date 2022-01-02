#if !defined(FX2_COMMON_FXH)
#define FX2_COMMON_FXH

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif

#ifndef RESHADE_DEPTH_MULTIPLIER
#define RESHADE_DEPTH_MULTIPLIER 1
#endif

#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif

#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
#define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif

#ifndef RESHADE_DEPTH_INPUT_X_SCALE
#define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif

#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET
#define RESHADE_DEPTH_INPUT_Y_OFFSET 0
#endif

#ifndef RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
#define RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET 0
#endif

#ifndef RESHADE_DEPTH_INPUT_X_OFFSET
#define RESHADE_DEPTH_INPUT_X_OFFSET 0
#endif

#ifndef RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
#define RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET 0
#endif

#define FX2_HELP(text) \
uniform int _Help \
< \
	ui_category = "Help"; \
	ui_category_closed = true; \
	ui_label = " "; \
	ui_type = "radio"; \
	ui_text = text; \
>

namespace FX2
{
	texture ColorTex : COLOR;
	texture DepthTex : DEPTH;

#ifdef FX2_USE_SHARED_TEXTURES
	texture SharedTex1
	{
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA16F;
	};

	texture SharedTex2
	{
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA16F;
	};
#endif

	sampler ColorPoint
	{
		Texture = ColorTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	};

	sampler ColorLinear
	{
		Texture = ColorTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

	sampler DepthPoint
	{
		Texture = DepthTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	};

	sampler DepthLinear
	{
		Texture = DepthTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

#ifdef FX2_USE_SHARED_TEXTURES
	sampler Shared1
	{
		Texture = SharedTex1;
	};

	sampler Shared2
	{
		Texture = SharedTex2;
	};
#endif

	struct ShaderParams
	{
		float4 position : SV_Position;
		float2 uv : TEXCOORD;
	};

	float4 GetScreenParams()
	{
		return float4(
			BUFFER_WIDTH,
			BUFFER_HEIGHT,
			BUFFER_RCP_WIDTH,
			BUFFER_RCP_HEIGHT
		);
	}

	float2 GetResolution()
	{
		return float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	}

	float2 GetPixelSize()
	{
		return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	}

	float GetDepth(sampler depthSampler, float2 uv, float mip)
	{
		#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
			uv.y = 1.0 - uv.y;
		#endif

		uv.x /= RESHADE_DEPTH_INPUT_X_SCALE;
		uv.y /= RESHADE_DEPTH_INPUT_Y_SCALE;

		#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
			uv.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
		#else
			uv.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
		#endif

		#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
			uv.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
		#else
			uv.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
		#endif

		float depth = tex2Dlod(depthSampler, float4(uv, 0, mip)).x * RESHADE_DEPTH_MULTIPLIER;

		#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
			const float C = 0.01;
			depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
		#endif

		#if RESHADE_DEPTH_INPUT_IS_REVERSED
			depth = 1.0 - depth;
		#endif

		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
	}

	float GetDepth(float2 uv, float mip)
	{
		return GetDepth(DepthPoint, uv, mip);
	}

	float GetDepth(float2 uv)
	{
		return GetDepth(uv, 0.0);
	}

	float2 ScaleUV(float2 uv, float2 scale, float2 center)
	{
		return (uv - center) * scale + center;
	}

	float2 ScaleUV(float2 uv, float2 scale)
	{
		return ScaleUV(uv, scale, 0.5);
	}

	void EmptyVS(uint id : SV_VertexID, out float4 p : SV_Position)
	{
		p.x = id == 2 ? 3.0 : 0.0;
		p.y = id == 1 ? -3.0 : 0.0;
		p.z = 0.0;
		p.w = 1.0;
	}

	void PostProcessVS(
		uint id : SV_VertexID,
		out float4 pos : SV_Position,
		out float2 uv : TEXCOORD)
	{
		uv.x = id == 2 ? 2.0 : 0.0;
		uv.y = id == 1 ? 2.0 : 0.0;
		pos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}
}

#define FX2_KEY_LBUTTON 0x01
#define FX2_KEY_RBUTTON 0x02
#define FX2_KEY_CANCEL 0x03
#define FX2_KEY_MBUTTON 0x04
#define FX2_KEY_XBUTTON1 0x05
#define FX2_KEY_XBUTTON2 0x06
#define FX2_KEY_BACK 0x08
#define FX2_KEY_TAB 0x09
#define FX2_KEY_CLEAR 0x0C
#define FX2_KEY_RETURN 0x0D
#define FX2_KEY_ENTER FX2_KEY_RETURN
#define FX2_KEY_SHIFT 0x10
#define FX2_KEY_CONTROL 0x11
#define FX2_KEY_MENU 0x12
#define FX2_KEY_ALT FX2_KEY_MENU
#define FX2_KEY_PAUSE 0x13
#define FX2_KEY_CAPITAL 0x14
#define FX2_KEY_KANA 0x15
#define FX2_KEY_HANGUEL 0x15
#define FX2_KEY_HANGUL 0x15
#define FX2_KEY_IME_ON 0x16
#define FX2_KEY_JUNJA 0x17
#define FX2_KEY_FINAL 0x18
#define FX2_KEY_HANJA 0x19
#define FX2_KEY_KANJI 0x19
#define FX2_KEY_IME_OFF 0x1A
#define FX2_KEY_ESCAPE 0x1B
#define FX2_KEY_CONVERT 0x1C
#define FX2_KEY_NONCONVERT 0x1D
#define FX2_KEY_ACCEPT 0x1E
#define FX2_KEY_MODECHANGE 0x1F
#define FX2_KEY_SPACE 0x20
#define FX2_KEY_PRIOR 0x21
#define FX2_KEY_PAGE_UP FX2_KEY_PRIOR
#define FX2_KEY_PAGEUP FX2_KEY_PAGE_UP
#define FX2_KEY_NEXT 0x22
#define FX2_KEY_PAGE_DOWN FX2_KEY_NEXT
#define FX2_KEY_PAGEDOWN FX2_KEY_PAGE_DOWN
#define FX2_KEY_END 0x23
#define FX2_KEY_HOME 0x24
#define FX2_KEY_LEFT 0x25
#define FX2_KEY_UP 0x26
#define FX2_KEY_RIGHT 0x27
#define FX2_KEY_DOWN 0x28
#define FX2_KEY_SELECT 0x29
#define FX2_KEY_PRINT 0x2A
#define FX2_KEY_EXECUTE 0x2B
#define FX2_KEY_SNAPSHOT 0x2C
#define FX2_KEY_INSERT 0x2D
#define FX2_KEY_DELETE 0x2E
#define FX2_KEY_HELP 0x2F
#define FX2_KEY_ZERO 0x30
#define FX2_KEY_ONE 0x31
#define FX2_KEY_TWO 0x32
#define FX2_KEY_THREE 0x33
#define FX2_KEY_FOUR 0x34
#define FX2_KEY_FIVE 0x35
#define FX2_KEY_SIX 0x36
#define FX2_KEY_SEVEN 0x37
#define FX2_KEY_EIGHT 0x38
#define FX2_KEY_NINE 0x39
#define FX2_KEY_A 0x41
#define FX2_KEY_B 0x42
#define FX2_KEY_C 0x43
#define FX2_KEY_D 0x44
#define FX2_KEY_E 0x45
#define FX2_KEY_F 0x46
#define FX2_KEY_G 0x47
#define FX2_KEY_H 0x48
#define FX2_KEY_I 0x49
#define FX2_KEY_J 0x4A
#define FX2_KEY_K 0x4B
#define FX2_KEY_L 0x4C
#define FX2_KEY_M 0x4D
#define FX2_KEY_N 0x4E
#define FX2_KEY_O 0x4F
#define FX2_KEY_P 0x50
#define FX2_KEY_Q 0x51
#define FX2_KEY_R 0x52
#define FX2_KEY_S 0x53
#define FX2_KEY_T 0x54
#define FX2_KEY_U 0x55
#define FX2_KEY_V 0x56
#define FX2_KEY_W 0x57
#define FX2_KEY_X 0x58
#define FX2_KEY_Y 0x59
#define FX2_KEY_Z 0x5A
#define FX2_KEY_LWIN 0x5B
#define FX2_KEY_RWIN 0x5C
#define FX2_KEY_APPS 0x5D
#define FX2_KEY_SLEEP 0x5F
#define FX2_KEY_NUMPAD0 0x60
#define FX2_KEY_NUMPAD1 0x61
#define FX2_KEY_NUMPAD2 0x62
#define FX2_KEY_NUMPAD3 0x63
#define FX2_KEY_NUMPAD4 0x64
#define FX2_KEY_NUMPAD5 0x65
#define FX2_KEY_NUMPAD6 0x66
#define FX2_KEY_NUMPAD7 0x67
#define FX2_KEY_NUMPAD8 0x68
#define FX2_KEY_NUMPAD9 0x69
#define FX2_KEY_MULTIPLY 0x6A
#define FX2_KEY_ADD 0x6B
#define FX2_KEY_SEPARATOR 0x6C
#define FX2_KEY_SUBTRACT 0x6D
#define FX2_KEY_DECIMAL 0x6E
#define FX2_KEY_DIVIDE 0x6F
#define FX2_KEY_F1 0x70
#define FX2_KEY_F2 0x71
#define FX2_KEY_F3 0x72
#define FX2_KEY_F4 0x73
#define FX2_KEY_F5 0x74
#define FX2_KEY_F6 0x75
#define FX2_KEY_F7 0x76
#define FX2_KEY_F8 0x77
#define FX2_KEY_F9 0x78
#define FX2_KEY_F10 0x79
#define FX2_KEY_F11 0x7A
#define FX2_KEY_F12 0x7B
#define FX2_KEY_F13 0x7C
#define FX2_KEY_F14 0x7D
#define FX2_KEY_F15 0x7E
#define FX2_KEY_F16 0x7F
#define FX2_KEY_F17 0x80
#define FX2_KEY_F18 0x81
#define FX2_KEY_F19 0x82
#define FX2_KEY_F20 0x83
#define FX2_KEY_F21 0x84
#define FX2_KEY_F22 0x85
#define FX2_KEY_F23 0x86
#define FX2_KEY_F24 0x87
#define FX2_KEY_NUMLOCK 0x90
#define FX2_KEY_NUM_LOCK FX2_KEY_NUMLOCK
#define FX2_KEY_SCROLL 0x91
#define FX2_KEY_LSHIFT 0xA0
#define FX2_KEY_RSHIFT 0xA1
#define FX2_KEY_LCONTROL 0xA2
#define FX2_KEY_RCONTROL 0xA3
#define FX2_KEY_LMENU 0xA4
#define FX2_KEY_RMENU 0xA5
#define FX2_KEY_BROWSER_BACK 0xA6
#define FX2_KEY_BROWSER_FORWARD 0xA7
#define FX2_KEY_BROWSER_REFRESH 0xA8
#define FX2_KEY_BROWSER_STOP 0xA9
#define FX2_KEY_BROWSER_SEARCH 0xAA
#define FX2_KEY_BROWSER_FAVORITES 0xAB
#define FX2_KEY_BROWSER_HOME 0xAC
#define FX2_KEY_VOLUME_MUTE 0xAD
#define FX2_KEY_VOLUME_DOWN 0xAE
#define FX2_KEY_VOLUME_UP 0xAF
#define FX2_KEY_MEDIA_NEXT_TRACK 0xB0
#define FX2_KEY_MEDIA_PREV_TRACK 0xB1
#define FX2_KEY_MEDIA_STOP 0xB2
#define FX2_KEY_MEDIA_PLAY_PAUSE 0xB3
#define FX2_KEY_LAUNCH_MAIL 0xB4
#define FX2_KEY_LAUNCH_MEDIA_SELECT 0xB5
#define FX2_KEY_LAUNCH_APP1 0xB6
#define FX2_KEY_LAUNCH_APP2 0xB7
#define FX2_KEY_OEM_1 0xBA
#define FX2_KEY_OEM_PLUS 0xBB
#define FX2_KEY_OEM_COMMA 0xBC
#define FX2_KEY_OEM_MINUS 0xBD
#define FX2_KEY_OEM_PERIOD 0xBE
#define FX2_KEY_OEM_2 0xBF
#define FX2_KEY_OEM_3 0xC0
#define FX2_KEY_OEM_4 0xDB
#define FX2_KEY_OEM_5 0xDC
#define FX2_KEY_OEM_6 0xDD
#define FX2_KEY_OEM_7 0xDE
#define FX2_KEY_OEM_8 0xDF
#define FX2_KEY_OEM_102 0xE2
#define FX2_KEY_BACKSLASH FX2_KEY_OEM_102
#define FX2_KEY_PROCESSKEY 0xE5
#define FX2_KEY_PACKET 0xE7
#define FX2_KEY_ATTN 0xF6
#define FX2_KEY_CRSEL 0xF7
#define FX2_KEY_EXSEL 0xF8
#define FX2_KEY_EREOF 0xF9
#define FX2_KEY_PLAY 0xFA
#define FX2_KEY_ZOOM 0xFB
#define FX2_KEY_NONAME 0xFC
#define FX2_KEY_PA1 0xFD
#define FX2_KEY_OEM_CLEAR 0xFE

#endif // Include guard.
