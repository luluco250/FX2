#include "FX2.Common.fxh"

#ifndef FX2_BLOOM_SAMPLES
#define FX2_BLOOM_SAMPLES 7
#endif

#ifndef FX2_BLOOM_DOWNSCALE
#define FX2_BLOOM_DOWNSCALE 4
#endif

namespace FX2
{
	uniform float Amount
	<
		ui_type = "slider";
		ui_min = 0.0;
		ui_max = 1.0;
		ui_step = 0.01;
	> = 1.0;

	uniform float Scale
	<
		ui_type = "slider";
		ui_min = 0.0;
		ui_max = 3.0;
		ui_step = 0.1;
	> = 1.0;

	uniform float Sigma
	<
		ui_type = "slider";
		ui_min = 1.0;
		ui_max = 3.0;
		ui_step = 0.1;
	> = 1.0;

	uniform int Tonemapper
	<
		ui_type = "combo";
		ui_items = "Reinhard\0BakingLabACES\0";
	> = 0;

	texture PingTex < pooled = true; >
	{
		Width = BUFFER_WIDTH / FX2_BLOOM_DOWNSCALE;
		Height = BUFFER_HEIGHT / FX2_BLOOM_DOWNSCALE;
		Format = RGBA16F;
	};

	texture PongTex < pooled = true; >
	{
		Width = BUFFER_WIDTH / FX2_BLOOM_DOWNSCALE;
		Height = BUFFER_HEIGHT / FX2_BLOOM_DOWNSCALE;
		Format = RGBA16F;
	};

	sampler Ping
	{
		Texture = PingTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

	sampler PingBorder
	{
		Texture = PingTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = BORDER;
		AddressV = BORDER;
	};

	sampler Pong
	{
		Texture = PongTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

	sampler PongBorder
	{
		Texture = PongTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = BORDER;
		AddressV = BORDER;
	};

	sampler Color
	{
		Texture = ColorTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		SRGBTexture = true;
	};

	float3 Tonemap(float3 c)
	{
		switch (Tonemapper)
		{
			case 0: return Reinhard(c);
			case 1: return BakingLabACES(c);
			default: return c;
		}
	}

	float3 TonemapInv(float3 c)
	{
		switch (Tonemapper)
		{
			case 0: return ReinhardInv(c);
			case 1: return BakingLabACESInv(c);
			default: return c;
		}
	}

#define _FX2_BLOOM_DEF_BLUR_SHADER(index, scale, inputX, inputY) \
	float4 Blur##index##XPS(ShaderParams p): SV_TARGET \
	{ \
		return GaussianBlur( \
			inputX, \
			p.uv, \
			float2(GetPixelSize().x, 0.0) * scale * Scale, \
			Sigma, \
			FX2_BLOOM_SAMPLES \
		); \
	} \
	\
	float4 Blur##index##YPS(ShaderParams p): SV_TARGET \
	{ \
		return GaussianBlur( \
			inputY, \
			p.uv, \
			float2(0.0, GetPixelSize().y) * scale * Scale, \
			Sigma, \
			FX2_BLOOM_SAMPLES \
		); \
	}

#define _FX2_BLOOM_DEF_DOWNSAMPLE_SHADER(index, inputScale, inputPivot, outputScale, outputPivot, input) \
	float4 Downsample##index##PS(ShaderParams p): SV_TARGET \
	{ \
		float2 uv = ScaleUV(p.uv, outputScale, outputPivot); \
		uv = ScaleUV(uv, 1.0 / inputScale, inputPivot); \
		return tex2D(input, uv) + tex2D(input, p.uv); \
	}

	float4 PreparePS(ShaderParams p): SV_TARGET
	{
		float4 color = tex2D(Color, p.uv);
		color.rgb = TonemapInv(color.rgb);
		return color;
	}

	_FX2_BLOOM_DEF_BLUR_SHADER(1, 2.0, Ping, Pong)

	float4 Downsample1PS(ShaderParams p): SV_TARGET
	{
		return tex2D(PingBorder, ScaleUV(p.uv, 2.0, 0.0));
	}

	_FX2_BLOOM_DEF_BLUR_SHADER(2, 3.0, Pong, Ping)
	_FX2_BLOOM_DEF_DOWNSAMPLE_SHADER(2, 2.0, 0.0, 3.0, 1.0, PongBorder)
	_FX2_BLOOM_DEF_BLUR_SHADER(3, 4.0, Ping, Pong)
	_FX2_BLOOM_DEF_DOWNSAMPLE_SHADER(3, 3.0, 1.0, 4.0, float2(1.0, 0.0), PingBorder)
	_FX2_BLOOM_DEF_BLUR_SHADER(4, 5.0, Pong, Ping)
	_FX2_BLOOM_DEF_DOWNSAMPLE_SHADER(4, 4.0, float2(1.0, 0.0), 5.0, float2(0.0, 1.0), PongBorder)
	_FX2_BLOOM_DEF_BLUR_SHADER(5, 6.0, Ping, Pong)

	float4 BlendPS(ShaderParams p): SV_TARGET
	{
	#if 0
		return tex2D(Ping, p.uv);
	#else
		float4 color = tex2D(Color, p.uv);
		color.rgb = TonemapInv(color.rgb);

		float4 bloom =
			tex2D(Ping, ScaleUV(p.uv, 1.0 / 2.0, 0.0)) +
			tex2D(Ping, ScaleUV(p.uv, 1.0 / 3.0, 1.0)) +
			tex2D(Ping, ScaleUV(p.uv, 1.0 / 4.0, float2(1.0, 0.0))) +
			tex2D(Ping, ScaleUV(p.uv, 1.0 / 5.0, float2(0.0, 1.0)));
		bloom /= 4;
		color.rgb += bloom.rgb * Amount;
		// color.rgb = lerp(color.rgb, bloom.rgb, Amount);
		color.rgb = Tonemap(color.rgb);
		return color;
	#endif
	}

#undef _FX2_BLOOM_DEF_DOWNSAMPLE_SHADER
#undef _FX2_BLOOM_DEF_BLUR_SHADER

	technique FX2_Bloom
	{

	#define _FX2_BLOOM_DEF_BLUR_PASS(index, outputX, outputY) \
		pass \
		{ \
			VertexShader = ScreenVS; \
			PixelShader = Blur##index##XPS; \
			RenderTarget = outputX; \
		} \
		pass \
		{ \
			VertexShader = ScreenVS; \
			PixelShader = Blur##index##YPS; \
			RenderTarget = outputY; \
		}

	#define _FX2_BLOOM_DEF_DOWNSAMPLE_PASS(index, output) \
		pass \
		{ \
			VertexShader = ScreenVS; \
			PixelShader = Downsample##index##PS; \
			RenderTarget = output; \
		}

		pass
		{
			VertexShader = ScreenVS;
			PixelShader = PreparePS;
			RenderTarget = PingTex;
		}

		_FX2_BLOOM_DEF_BLUR_PASS(1, PongTex, PingTex)
		_FX2_BLOOM_DEF_DOWNSAMPLE_PASS(1, PongTex)
		_FX2_BLOOM_DEF_BLUR_PASS(2, PingTex, PongTex)
		_FX2_BLOOM_DEF_DOWNSAMPLE_PASS(2, PingTex)
		_FX2_BLOOM_DEF_BLUR_PASS(3, PongTex, PingTex)
		_FX2_BLOOM_DEF_DOWNSAMPLE_PASS(3, PongTex)
		_FX2_BLOOM_DEF_BLUR_PASS(4, PingTex, PongTex)
		_FX2_BLOOM_DEF_DOWNSAMPLE_PASS(4, PingTex)
		_FX2_BLOOM_DEF_BLUR_PASS(5, PongTex, PingTex)

		pass
		{
			VertexShader = ScreenVS;
			PixelShader = BlendPS;
			SRGBWriteEnable = true;
		}

	#undef _FX2_BLOOM_DEF_BLUR_PASS
	#undef _FX2_BLOOM_DEF_DOWNSAMPLE_PASS

	}
}
