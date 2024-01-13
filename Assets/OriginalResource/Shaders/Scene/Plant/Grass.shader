Shader "MC/Scene/Grass"
{
    Properties
    {
		[Header(Grass Color)]
		_Grass ("草纹理", 2D) = "white" {}
		[HDR] _Color ("颜色",color) = (1,1,1,1)
		_Cutout("透明度裁剪阈值",Range(0,1)) = 1
		[Space]
		[Header(Ambient Color)]
		[Toggle(_AMBIENT_ON)] _AmbientToggle("开启环境光", Int) = 0
		[Space]
		[Header(Grass Motion)]
		_WindSpeed("风速",Range(0,1)) = 1
		_WindRandom("风强",Range(0,1)) = 1
		[Space]
		[Header(Grass Interactive)]
		_Strength("弯曲强度", float) = 1
        _PushRadius("弯曲系数", float) = 1
		[Space]
		[Header(Grass Rippling)]
		[Toggle(_Rippling_ON)]_RipplingToggle("开启麦浪", Int) = 0
		_Rippling("麦浪噪声", 2D) = "white" {}
		[HDR]_RipplingColor("麦浪颜色", Color) = (1,1,1,1)
		_Ripplingspeed("麦浪摆动速度", Range( 0 , 10)) = 0
		_RipplingFluctuation("摆动强度", Range( 0 , 1)) = 0 
		_VerticalPower("根部固定系数",Range(0,1)) = 1
		_Angle("摆动角度", Range( 0 , 360)) = 0
		_Gradual ("渐变", Range( 0 , 5)) = 0
		[Space]
		[Header(FakeLight Motion)]
		[Toggle(FAKELIGHT_ON)]_FakeLight ("伪光", Float) = 0
        _FakeLightDirection("伪光方向向量", Vector) = (0,0,0)
        _FakeLightColor("伪光颜色", Color) = (1,1,1,1)
        _FakeLightColorStrength("伪光强度",Range(0.1,1.9)) = 1
		_End("结束距离",Range(0,100)) = 1
		_Start("开始距离",Range(0,100)) = 1
		[Space]
		[Toggle(SelfLuminous_ON)]_SelfLuminous ("自发光", Float) = 0
		[Space]
		[Header(Lightning)]
		_LightningIntensity ("雷光强度", Range(0,1)) = 1
    }

    SubShader
    {
    	Tags {"Queue" = "AlphaTest" "RenderType" = "Grass" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
    	Cull Off
    	
    	HLSLINCLUDE

    	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    	#include "../../CommonInclude.hlsl"

    	#define PERLIN_NOISE_CONST float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439)

    	sampler2D _Grass;
    	float3 _PlayerPos;
    	sampler2D _Rippling;
    	half3 _LightningColor;
    	float3 _LightDirection;
    	
    	CBUFFER_START(UnityPerMaterial)
    	half4 _Grass_ST;
    	half4 _Color;
    	half _Cutout;
    	half _VerticalPower;
    	half _WindSpeed, _WindRandom;
		half _Strength, _PushRadius;

    	half4 _Rippling_ST;
    	half3 _RipplingColor;
    	half _Ripplingspeed, _RipplingFluctuation, _Angle, _Gradual;

    	half _End, _Start;
    	half4 _FakeLightDirection;
    	half3 _FakeLightColor;
    	half _FakeLightColorStrength;
    	half _LightningIntensity;

    	CBUFFER_END

    	float2 Mod2D289(float2 x)
    	{
    		return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0;
    	}

    	float3 Mod2D289(float3 x)
    	{
    		return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0;
    	}

    	float3 Permute( float3 x )
    	{
    		return Mod2D289((x * 34.0 + 1.0) * x);
    	}

    	float PerlinNoise(half2 v)
    	{
			float2 i = floor(v + dot(v, PERLIN_NOISE_CONST.yy));
			float2 x0 = v - i + dot(i, PERLIN_NOISE_CONST.xx);
    		half x0Step = step(x0.x, x0.y);
			half2 i1 = half2(1 - x0Step, x0Step);
			float4 x12 = x0.xyxy + PERLIN_NOISE_CONST.xxzz;
			x12.xy -= i1;
			i = Mod2D289(i);
			float3 p = Permute(Permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
			float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac(p * PERLIN_NOISE_CONST.www) - 1.0;
			float3 h = abs(x) - 0.5;
			float3 ox = floor(x + 0.5);
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 100.0 * dot(m, g);
    	}

		float3 PushDown(float3 worldPos, float height)
		{
			float dis = distance(_PlayerPos, worldPos);
			float pushDown = saturate((1 - dis + _PushRadius) * height * 0.23 * _Strength);
			float3 direction = normalize(worldPos.xyz - _PlayerPos.xyz);
			worldPos.xyz += direction * pushDown;
			return worldPos;
		}

		float2 RotateUV(float2 uv, float radians)
		{
			float s, c;
			sincos(radians, s, c);
			float2x2 rotate = float2x2(float2(c, -s), float2(s, c));
			return mul(rotate, uv);
		}

	    struct GrassVertexInput
	    {
		    float4 positionOS : POSITION;
    		half3 normalOS : NORMAL;
    		half2 texcoord : TEXCOORD0;
    		UNITY_VERTEX_INPUT_INSTANCE_ID
	    };

    	struct GrassV2F
    	{
    		float4 positionCS : SV_POSITION;
    		half2 uv : TEXCOORD0;
    		half3 vertexSH : TEXCOORD1;
    		float3 positionWS : TEXCOORD2; // 顶点坐标(世界)
			half3 normalWS : TEXCOORD3; // 法线(世界)
    		half4 fogFactorAndVertexLight : TEXCOORD5; // x: 雾效, yzw: 次要光源(逐顶点)
    		float4 shadowCoord : TEXCOORD6; // 阴影纹理坐标
		// #if _Rippling_ON
    		half4 ripplingParams : TEXCOORD7; // 麦浪效果相关参数
		// #endif
    		UNITY_VERTEX_INPUT_INSTANCE_ID
    	};

		struct GrassInputData
    	{
    	    float3 positionWS;
    	    half3 normalWS;
    	    float4 shadowCoord;
    	    half fogCoord;
    	    half3 vertexLighting; // 实时多光源的Lambert光照结果的叠加
    	    half4 shadowMask;
    	};

		GrassInputData InitializeGrassInputData(GrassV2F input)
    	{
    	    GrassInputData inputData = (GrassInputData)0;
    	    inputData.positionWS = input.positionWS;
    	    inputData.normalWS = normalize(input.normalWS);
    	    inputData.shadowCoord = input.shadowCoord;
    	    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    	    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    	    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
    	    return inputData;
    	}

		half4 GrassRender(GrassInputData inputData, half4 albedo, GrassV2F fragmentInput)
    	{
			float distance = length(inputData.positionWS - _WorldSpaceCameraPos);
			// 获取主光源
    	    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
		#if FAKELIGHT_ON
			mainLight.direction = _FakeLightDirection.xyz / _FakeLightDirection.w;
			mainLight.color = _FakeLightColor * _FakeLightColorStrength;
		#endif
			
			mainLight.color += _LightningColor * _LightningIntensity;
			half3 diffuse;
			
		#if SelfLuminous_ON
			diffuse = (1 + _LightningColor * _LightningIntensity) * albedo;
		#else
			half nDotL = max(0,dot(inputData.normalWS, mainLight.direction)) * 0.5 + 0.5;
			diffuse = mainLight.color * albedo.rgb * nDotL;
		#endif

		#if _Rippling_ON
			float dFactor = (_End - abs(distance)) / (_End - _Start);
			half rippling = saturate(pow(saturate(fragmentInput.ripplingParams.w) * 2.3, _Gradual * 2.3));
			diffuse += rippling * _RipplingColor * saturate(dFactor);
		#endif

		#if _AMBIENT_ON
			diffuse += albedo.rgb * fragmentInput.vertexSH;
		#endif
			
    	    half3 diffuseColor = 0;
    	    // 逐像素多光源
    	#ifdef _ADDITIONAL_LIGHTS
    	    uint pixelLightCount = GetAdditionalLightsCount();
    	    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    	    {
    	        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
    	        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    	        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);
    	    }
    	#endif
    	    // 逐顶点多光源
    	#ifdef _ADDITIONAL_LIGHTS_VERTEX
    	    diffuseColor += inputData.vertexLighting;
    	#endif
    	    half3 finalColor = diffuseColor * albedo.rgb + diffuse;
    	    return half4(finalColor, 1);
    	}

    	GrassV2F GrassVertex(GrassVertexInput input)
    	{
    		GrassV2F output = (GrassV2F)0;
			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_TRANSFER_INSTANCE_ID(input, output);

    		output.uv = TRANSFORM_TEX(input.texcoord, _Grass);
    		
    		half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
			output.normalWS = normalWS;

    		half verticalMove = pow(saturate(input.texcoord.y), _VerticalPower * 5);

    		float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

    		half2 tempCast = _Time.yy * 0.25;
    		float simplePerlin = PerlinNoise(tempCast) * 2;
    		float randomDirection = sin(simplePerlin * _WindSpeed * 8 + positionWS.z) * _WindRandom;

    		positionWS.xz += randomDirection * verticalMove;
    		positionWS.xyz = PushDown(positionWS, input.positionOS.y);

		#if _Rippling_ON
    		// 麦浪效果
    		half angle = radians(_Angle);
    		output.ripplingParams.xy = TRANSFORM_TEX(RotateUV(positionWS.xz, angle), _Rippling);
    		float4 ripplingLodUV = float4(output.ripplingParams.xy + _Time.x * 0.25 * _Ripplingspeed, 0, 0);
    		half4 rippling = tex2Dlod(_Rippling, ripplingLodUV);
    		float rs = rippling.r * _RipplingFluctuation * verticalMove;
    		positionWS.xz -= rs;

    		output.ripplingParams.z = rippling.r;
    		output.ripplingParams.w = input.texcoord.y;
		#endif

    		output.positionWS = positionWS;
    		output.positionCS = TransformWorldToHClip(positionWS);

			// 对次要光源逐个计算光照(兰伯特模型), 结果相加
			half3 vertexLight = VertexLighting(positionWS, normalWS);
    		half fogFactor = ComputeFogFactor(output.positionCS.z);

			output.vertexSH = SampleSH(output.normalWS);

    		output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    		output.shadowCoord = TransformWorldToShadowCoord(positionWS);
    		return output;
    	}

    	half4 GrassFragment(GrassV2F input) : SV_Target
    	{
    		UNITY_SETUP_INSTANCE_ID(input);
    		half4 albedo = tex2D(_Grass, input.uv) * _Color;
    		clip(albedo.a - _Cutout);
    		GrassInputData inputData = InitializeGrassInputData(input);

    		half4 color = GrassRender(inputData, albedo, input);

			color.rgb = MixFog(color.rgb, inputData.fogCoord);
			return color;
    	}

    	struct ShadowCasterVertexInput
		{
    		float4 positionOS   : POSITION;
    		half2 texcoord : TEXCOORD0;
    		float3 normalOS     : NORMAL;
    		UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct CutoffShadowCasterVertexOutput
		{
		    float4 positionCS   : SV_POSITION;
		    half2 uv : TEXCOORD0;
		};

		float4 GetShadowPositionHClip(ShadowCasterVertexInput input)
		{
		    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
		    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
		
		    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
		
		    #if UNITY_REVERSED_Z
		    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
		    #else
		    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
		    #endif
		
		    return positionCS;
		}

    	CutoffShadowCasterVertexOutput CutoffShadowVertex(ShadowCasterVertexInput input)
		{
    		CutoffShadowCasterVertexOutput output;
    		UNITY_SETUP_INSTANCE_ID(input);
    		output.positionCS = GetShadowPositionHClip(input);
    		output.uv = TRANSFORM_TEX(input.texcoord, _Grass);
    		return output;
		}

		half4 CutoffShadowFragment(CutoffShadowCasterVertexOutput input) : SV_TARGET
		{
		    half alpha = tex2D(_Grass, input.uv).a * _Color.a;
		    clip(alpha - _Cutout);
		    return 0;
		}
    	ENDHLSL

        Pass
        {
            Name "Grass"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        	Cull Back
        	
        	HLSLPROGRAM

        	#pragma shader_feature_local _AMBIENT_ON
        	#pragma shader_feature_local _Rippling_ON
        	#pragma shader_feature_local FAKELIGHT_ON
        	#pragma shader_feature_local SelfLuminous_ON

        	#pragma multi_compile_instancing
        	// #pragma multi_compile_fog
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

        	#pragma skip_variants FOG_EXP FOG_EXP2
			#pragma skip_variants DIRLIGHTMAP_COMBINED LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_SHADOWMASK

			#pragma vertex GrassVertex
			#pragma fragment GrassFragment

        	ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma multi_compile_instancing

            #pragma vertex CutoffShadowVertex
            #pragma fragment CutoffShadowFragment

            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}