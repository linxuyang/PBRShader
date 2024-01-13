Shader "MC/Scene/Cloud/SkyCloud"
{
	Properties
	{
		_MainTex("主贴图", 2D) = "black" {}
		_MainSpeed("主贴图 横向速度", Float) = 0.1
		[HDR]_TopColor("主贴图 顶部颜色", Color) = (1,1,1,1)
		[HDR]_BottomColor("主贴图 底部颜色", Color) = (1,1,1,1)

		[Space]
		 [Toggle(_CLOUD1_ON)] _cloud1On ("云层1开关", int) = 0
		_Cloud1Tex("云层1贴图", 2D) = "white" {}
		_Cloud1Speed("云层1 横向速度", Float) = 0.1
		[HDR]_Cloud1TopColor("云层1 顶部颜色", Color) = (1,1,1,1)
		[HDR]_Cloud1BottomColor("云层1 底部颜色", Color) = (1,1,1,1)
		
		[Space]
		 [Toggle(_CLOUD2_ON)] _cloud2On ("云层2开关", int) = 0
		_Cloud2Tex("云层2 贴图", 2D) = "white" {}
		_Cloud2Speed("云层2 横向速度", Float) = 0.1
		[HDR]_Cloud2TopColor("云层2 顶部颜色", Color) = (1,1,1,1)
		[HDR]_Cloud2BottomColor("云层2 底部颜色", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags { "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		Blend SrcAlpha OneMinusSrcAlpha 
	 	// ColorMask RGB
		// BlendOp ADD
		Cull Back 
		Lighting Off 
		ZWrite Off
	
		Pass
		{
			Tags
            {
                "LightMode" = "UniversalForward"
            }
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile _ UBPA_FOG_ENABLE
			// #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma shader_feature_local _ _CLOUD1_ON
			#pragma shader_feature_local _ _CLOUD2_ON

			sampler2D _MainTex;
			half4 _MainTex_ST;
			half _MainSpeed;
			half4 _TopColor;
			half4 _BottomColor;

			sampler2D _Cloud1Tex;
			half4 _Cloud1Tex_ST;
			half _Cloud1Speed;
			half4 _Cloud1TopColor;
			half4 _Cloud1BottomColor;


			sampler2D _Cloud2Tex;
			half4 _Cloud2Tex_ST;
			half _Cloud2Speed;
			half4 _Cloud2TopColor;
			half4 _Cloud2BottomColor;
	
			// float _CloudDistortion;
			// float _CloudOpacity;

			struct appdata_t {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
			    // half2 uv : TEXCOORD0;  
				float2 rectangular : TEXCOORD0;
		        float3 texcoord : TEXCOORD1;
				// float2 polar : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				float3 texcoord : TEXCOORD1;
			
				// UBPA_FOG_COORDS(4)
				half fogFactor : TEXCOORD4;
				// UNITY_FOG_COORDS(4)
			};


			v2f vert(appdata_t v) {
				v2f o;

				float3 t = v.vertex.xyz * _ProjectionParams.z + _WorldSpaceCameraPos.xyz;

				// o.pos = UnityObjectToClipPos(v.vertex);
				o.pos = TransformObjectToHClip(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.rectangular, _MainTex);
				// o.uv.zw = TRANSFORM_TEX(v.texcoord, _StarsNoiseTex);
				o.texcoord = v.texcoord;
				// UBPA_TRANSFER_FOG(o,v.vertex);
				// UNITY_TRANSFER_FOG(o,v.vertex);
				o.fogFactor = ComputeFogFactor(o.pos.z); 
				return o;
			}


			half4 frag(v2f i) : SV_Target {
				float time = fmod(_Time.y,60000);

				//叠加颜色
				half4 mainColor = lerp( _BottomColor , _TopColor , i.uv.y);
				float mainSpeed = time * _MainSpeed * 0.01;

				float2 mainuv = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				mainuv.x += mainSpeed;
				
				half4 col = tex2D(_MainTex, mainuv) * mainColor; 


				#if _CLOUD1_ON 
					half4 cloud1Color = lerp( _Cloud1BottomColor , _Cloud1TopColor , i.uv.y);
					float cloud1Speed = time * _Cloud1Speed * 0.01;

					float2 cloud1uv = i.uv.xy * _Cloud1Tex_ST.xy + _Cloud1Tex_ST.zw;
					cloud1uv.x += cloud1Speed;
					// cloud1uv += temp_output_100_0;

					float4 cloud1Col = tex2D(_Cloud1Tex, cloud1uv) * cloud1Color;

					col += cloud1Col;
				#endif

				#if _CLOUD2_ON 
					half4 cloud2Color = lerp( _Cloud2BottomColor , _Cloud2TopColor , i.uv.y);
					float cloud2Speed = time * _Cloud2Speed * 0.01;

					float2 cloud2uv = i.uv.xy * _Cloud2Tex_ST.xy + _Cloud2Tex_ST.zw;
					cloud2uv.x += cloud2Speed;

					float4 cloud2Col = tex2D(_Cloud2Tex, cloud2uv) * cloud2Color;

					col += cloud2Col;
				#endif

				// UBPA_APPLY_FOG(i.fogCoord,col);
				// UNITY_APPLY_FOG(i.fogCoord,col);
				col.rgb = MixFog(col.rgb, i.fogFactor);
				
				return col;
			}

			ENDHLSL
		}
	}
}