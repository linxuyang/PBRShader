// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Custom shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material color
Shader "MC/Effect/FlowLight" {
	Properties {
		[HDR]_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
	  	// //流光遮罩纹理  
	  	_FlowMaskTex("Flow Mask Texture",2D)="white"{}  
		//流光 改版
		_FlowLightTex ("Flow Light Texture", 2D) = "white" {}
		[HDR]_FlowLightColor ("Flow Light Color", Color) = (0.5, 0.5, 0.5, 1)	
		_FlowSpeedX("_FlowSpeedX", Float) = 1
		_FlowSpeedY("_FlowSpeedY", Float) = 0
		[Enum(One,1,SrcAlpha,5)] _SrcBlend("SrcBlend 源混合方式", float) = 5 // SrcAlpha
        [Enum(One,1,OneMinusSrcAlpha,10)] _DstBlend("DstBlend 目标混合方式", float) = 1 // One

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
	}

	SubShader {
		Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    	LOD 100
		ZWrite On
		ZTest On
    	Blend [_SrcBlend] [_DstBlend]

		Pass {
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct appdata_t {
					half4 vertex : POSITION;
					half3 normal : NORMAL;
					half2 uv : TEXCOORD0;  
				};

				struct v2f {
					half4 vertex : SV_POSITION;
					half2 uv : TEXCOORD0;  
					half2 uv1 : TEXCOORD1;
				};

				half4 _Color;
				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);
				half4 _MainTex_ST;	
                TEXTURE2D(_FlowMaskTex);
                SAMPLER(sampler_FlowMaskTex);
				//流光
				TEXTURE2D(_FlowLightTex);
				SAMPLER(sampler_FlowLightTex);
				half4 _FlowLightTex_ST;
				half4 _FlowLightColor;
				half _FlowSpeedX;
				half _FlowSpeedY;
				half _AlphaScale;

				v2f vert (appdata_t v)
				{
					v2f o;
					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);  
					o.uv1 = TRANSFORM_TEX(v.uv, _FlowLightTex);
					return o;
				}


				half4 frag (v2f i) : SV_Target
				{
					half4 col;
					half maskA = SAMPLE_TEXTURE2D(_FlowMaskTex,sampler_FlowMaskTex,i.uv).a;  

					half2 uvTmp = i.uv1 * 0.5;
					uvTmp.x += _Time.y * _FlowSpeedX;  
					uvTmp.y += _Time.y * _FlowSpeedY;  
					half4 lightTex = SAMPLE_TEXTURE2D(_FlowLightTex,sampler_FlowLightTex,uvTmp);
					half3 flow = lightTex.rgb * lightTex.a * _FlowLightColor.rgb *  _FlowLightColor.a * maskA;

					col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Color;
					col.rgb += flow.rgb;
					col.a *= _AlphaScale;


					return col;
				}
			ENDHLSL
		}
	}
}
