Shader "MC/Scene/Skybox/MilkyWay"
{
	Properties
	{
		_SkyColor("天空底色", Color) = (0, 0, 0, 1)

		[Header(Cloud1 Setting)]
		_CloudTex("云纹理1", 2D) = "white" {}
		_CloudColor("云颜色1", Color) = (0.12214, 1, 0.81485, 0)
		_CloudSpeed("UV动画速度", Range(-10, 10)) = -0.004
		_CloudTexUV2Coord("二次采样Tiling", Vector) = (0.7, 0.7, 0, 0)

		[Header(Cloud2 Setting)]
		_Cloud02Tex("云纹理2", 2D) = "white" {}
		_Cloud02Color("云颜色2", Color) = (0, 0.18782, 0.60383, 0)
		_Cloud02Speed("UV动画速度", Range(-10, 10)) = 0.005
		_CloudTex02UV2Coord("二次采样Tiling", Vector) = (2, 2, 0, 0)

		[Header(Cloud Mix Setting)]
		_MixNoiseTex("混合噪声纹理", 2D) = "white" {}
		_NoiseTexUV2Coord("二次采样Tiling", Vector) = (1, 1, 0, 0)
		_NoiseSpeed("UV动画速度", Range(-1, 1)) = -0.002
		_NoiseBrightness("噪声强度", Range(0, 5)) = 1

		[Header(ColorPalette Setting)]
		_ColorPalette("调色板", 2D) = "white" {}
		_ColorPaletteSpeed("色谱变化速度", Range(-1, 1)) = -0.2
		_Saturate("颜色饱和度", Range(0, 1)) = 0

		[Header(Star Setting)]
		_StarTex("星星纹理", 2D) = "black" {}
		_StarTexUV2Coord("二次采样Tiling", Vector) = (6, 6, 0, 0)
		_StarUVSpeed1("UV动画速度1", Range(-0.1, 0.1)) = 0.015
		_StarUVSpeed2("UV动画速度2", Range(-0.1, 0.1)) = 0.015
		_StarBrightness("星星亮度", Range(0, 20)) = 15
	}

	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#define GAMMA_POW_1 0.45
	#define GAMMA_POW_2 2.2

	half4 _SkyColor;
	// 云2参数
	TEXTURE2D(_Cloud02Tex);
	SAMPLER(sampler_Cloud02Tex);
	half4 _Cloud02Tex_ST;
	half4 _Cloud02Color;
	half _Cloud02Speed;
	half2 _CloudTex02UV2Coord;
	// 云1参数
	TEXTURE2D(_CloudTex);
	SAMPLER(sampler_CloudTex);
	half4 _CloudTex_ST;
	half4 _CloudColor;
	half _CloudSpeed;
	half2 _CloudTexUV2Coord;
	// 云1和云2的混合参数
	TEXTURE2D(_MixNoiseTex);
	SAMPLER(sampler_MixNoiseTex);
	half4 _MixNoiseTex_ST;
	half2 _NoiseTexUV2Coord;
	half  _NoiseSpeed, _NoiseBrightness;

	// 星星参数
	TEXTURE2D(_StarTex);
	SAMPLER(sampler_StarTex);
	TEXTURE2D(_ColorPalette);
	SAMPLER(sampler_ColorPalette);
	half4 _StarTex_ST, _ColorPalette_ST;
	half2 _StarTexUV2Coord;
	half _StarUVSpeed1, _StarUVSpeed2, _StarBrightness, _ColorPaletteSpeed, _Saturate;


	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord0 : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		float4 uv : TEXCOORD0;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = TransformObjectToHClip(v.vertex.xyz);
		o.uv = float4(v.texcoord0, v.texcoord1);
		return o;
	}


	half4 frag(v2f i) : Color
	{
		float2 uv0 = i.uv.xy;
		float2 uv1 = i.uv.zw;
		// 根据UV0的Y分量计算梯度值(越靠近球面上下极越大，越靠近黄道面越小)
		half gradient = abs(uv0.y - 0.5) * 2;

		// 色谱变化
		half2 colorPaletteUv = TRANSFORM_TEX(uv0, _ColorPalette);
		colorPaletteUv = colorPaletteUv + half2(_Time.y * _ColorPaletteSpeed, 0);
		half3 paletteCol = SAMPLE_TEXTURE2D(_ColorPalette,sampler_ColorPalette,colorPaletteUv);
		paletteCol = pow(paletteCol, GAMMA_POW_1);
		paletteCol = lerp(paletteCol, half3(1, 1, 1), gradient);
		half desaturateDot = dot(paletteCol, half3(0.299, 0.587, 0.114));
		paletteCol = lerp(half3(desaturateDot, desaturateDot, desaturateDot), paletteCol, _Saturate);
		// 云2
		half cloud2UvOffset = _Time.y * _Cloud02Speed;
		half2 cloud2Uv = uv1 * _CloudTex02UV2Coord;
		cloud2Uv = cloud2Uv + half2(cloud2UvOffset, cloud2UvOffset);
		half cloud02TexVal_1 = SAMPLE_TEXTURE2D(_Cloud02Tex,sampler_Cloud02Tex,cloud2Uv).r;
		cloud02TexVal_1 = pow(cloud02TexVal_1, GAMMA_POW_1);
		cloud2Uv = TRANSFORM_TEX(uv0, _Cloud02Tex);
		cloud2Uv = cloud2Uv + half2(cloud2UvOffset, cloud2UvOffset);
		half cloud02TexVal_2 = SAMPLE_TEXTURE2D(_Cloud02Tex,sampler_Cloud02Tex,cloud2Uv).r;
		cloud02TexVal_2 = pow(cloud02TexVal_2, GAMMA_POW_1);
		half cloud02TexVal = lerp(cloud02TexVal_2, cloud02TexVal_1, gradient);
		cloud02TexVal = saturate(cloud02TexVal);
		half3 cloud02Col = lerp(_SkyColor.rgb, paletteCol * _Cloud02Color.rgb, cloud02TexVal);
		
		// 云1
		half cloud1UvOffset = _Time.y * _CloudSpeed;
		half2 cloud1Uv = uv1 * _CloudTexUV2Coord;
		cloud1Uv = cloud1Uv + half2(cloud1UvOffset, cloud1UvOffset);
		half cloud01TexVal_1 = SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,cloud1Uv).r;
		cloud01TexVal_1 = pow(cloud01TexVal_1, GAMMA_POW_1);
		cloud1Uv = TRANSFORM_TEX(uv0, _CloudTex);
		cloud1Uv = cloud1Uv + half2(cloud1UvOffset, cloud1UvOffset);
		half cloud01TexVal_2 = SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,cloud1Uv).r;
		cloud01TexVal_2 = pow(cloud01TexVal_2, GAMMA_POW_1);
		half cloud01TexVal = lerp(cloud01TexVal_2, cloud01TexVal_1, gradient);
		cloud01TexVal = saturate(cloud01TexVal);
		half3 cloud01Col = cloud01TexVal * _CloudColor.rgb;

		// 噪声
		half2 noiseUv = uv1 * _NoiseTexUV2Coord + half2(0, _Time.y * _NoiseSpeed);
		half noiseVal_1 = SAMPLE_TEXTURE2D(_MixNoiseTex,sampler_MixNoiseTex,noiseUv).r;
		noiseVal_1 = pow(noiseVal_1, GAMMA_POW_1);
		noiseUv = TRANSFORM_TEX(uv0, _MixNoiseTex) + half2(0, _Time.y * _NoiseSpeed);
		half noiseVal_2 = SAMPLE_TEXTURE2D(_MixNoiseTex,sampler_MixNoiseTex,noiseUv).r;
		noiseVal_2 = pow(noiseVal_2, GAMMA_POW_1);
		half finalNoiseVal = lerp(noiseVal_2, noiseVal_1, gradient);
		finalNoiseVal = finalNoiseVal * _NoiseBrightness;
		finalNoiseVal = saturate(finalNoiseVal);

		// 云1 + 云2
		half totalCouldVal = cloud02TexVal * cloud01TexVal;
		half3 totalCloudCol = lerp(cloud01Col, cloud02Col, finalNoiseVal);

		// 星光
		half2 starTexUv = uv1 * _StarTexUV2Coord;
		half starUvOffset = _StarUVSpeed1 * _Time.y;
		starTexUv = starTexUv + half2(starUvOffset, 0);
		half starTexVal_1 = SAMPLE_TEXTURE2D(_StarTex,sampler_StarTex,starTexUv).r;
		starTexVal_1 = pow(starTexVal_1, GAMMA_POW_1);

		starTexUv = TRANSFORM_TEX(uv0, _StarTex);
		starUvOffset = _Time.y * _StarUVSpeed2;
		starTexUv = starTexUv + half2(starUvOffset, 0);
		half starTexVal_2 = SAMPLE_TEXTURE2D(_StarTex,sampler_StarTex,starTexUv).g;
		starTexVal_2 = pow(starTexVal_2, GAMMA_POW_1);
		half3 starCol = starTexVal_1 * paletteCol + starTexVal_2 * (1 - gradient);
		starCol = starCol * _StarBrightness * totalCouldVal;

		half3 finalCol = totalCloudCol + starCol;
		finalCol = pow(finalCol, GAMMA_POW_2);
		return half4(finalCol, 1);
	}
	ENDHLSL

	SubShader
	{
		Tags {"RenderType" = "Background" "RenderPipeline" = "UniversalPipeline" "Queue" = "AlphaTest+50" "PreviewType"="Skybox"}
		ZWrite On
		Cull Back
		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}
	Fallback Off
}
