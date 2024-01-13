// 纯粹的球形天空盒，和BackGround一样，但存在真实的球
Shader "MC/Scene/Skybox/SphereSky" {
	Properties {
		_MainTex ("Texture (R)", 2D) = "white" {}
		// _HorizonOffset("Offset", Range(0,50)) = 50
		// [HDR]_BottomColor("Bottom Horizon Color", Color) = (0.37,0.78,0.92,1)
		// _Bottom("Bottom Horizon Level", Float) = 0
	}

	SubShader {
		Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest+50" "RenderType"="Background" }

		ZWrite ON

		Pass {
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			half4 _MainTex_ST;

			// uniform float _RotateSpeed;
			
			// float _Bottom, _HorizonOffset;
			// fixed4 _BottomColor;

			struct appdata_t {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 rectangular : TEXCOORD0;
				float2 polar : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(appdata_t v) {
				v2f o=(v2f)0;
				float3 t = v.vertex.xyz;
				// o.worldPos = mul(UNITY_MATRIX_M, float4(t,1));
				// o.pos = UnityWorldToClipPos(float4(o.worldPos, 1));
				o.pos = TransformObjectToHClip(t.xyz);
				o.uv = TRANSFORM_TEX(v.rectangular, _MainTex);

				return o;
			}

			half4 frag(v2f i) : SV_Target {
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
				return col;

			}
			ENDHLSL

		}
	}

	Fallback Off
}
