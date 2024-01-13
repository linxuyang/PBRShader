// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MC/PostEffect/BlurDark"
{
 
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_RunTime("RunTime", float) = 1
	}

 
	//开始SubShader
	SubShader
	{
		ZTest Always
		Cull Off
		ZWrite Off
		Fog{ Mode Off }

		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#pragma vertex vert_blur
			#pragma fragment frag_blur

			struct appdata
			{
			    float4 vertex : POSITION;
			    half2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv  : TEXCOORD0;		
				float4 uv01 : TEXCOORD1;	
				float4 uv23 : TEXCOORD2;	
				float4 uv45 : TEXCOORD3;	
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			float4 _MainTex_TexelSize;
			float4 _offsets;
			float _RunTime;
 
			v2f vert_blur(appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.texcoord.xy;
 
				_offsets *= _MainTex_TexelSize.xyxy;
		
				o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
				o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
				o.uv45 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;
 
				return o;
			}
 
			half4 frag_blur(v2f i) : SV_Target
			{
				half4 color = half4(0,0,0,0);
				color += 0.4 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
				color += 0.15 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.xy);
				color += 0.15 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.zw);
				color += 0.10 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.xy);
				color += 0.10 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.zw);
				color += 0.05 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.xy);
				color += 0.05 * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.zw);

				color = color * _RunTime;
				return color;
			}
 
			ENDHLSL
		}
 
	}
}
