Shader "MC/Scene/Skybox/StarlitSkybox"
{
	Properties
	{
		_MainTex("主贴图", 2D) = "black" {}
		[HDR]_TopColor("主贴图 顶部颜色", Color) = (1,1,1,0)
		[HDR]_BottomColor("主贴图 底部颜色", Color) = (0,0,0,0)

		[Space]
		[Toggle(_STARS_ON)] _starsOn ("星星开关（特别耗性能请慎开）", int) = 0
		// _StarsTex("星星贴图", 2D) = "white" {}
		// _StarsColor("星星颜色", Color) = (1,1,1,0)
		// _StarsSpeed("星星 横向速度", Float) = 0.1
		// _StarsBrightness("星星亮度", Float) = 1
        [HDR]_StarColor ("星星颜色", Color) = (1,1,1,0)
        // _StarsNoiseTex("星星噪声贴图", 2D) = "white" {}
        _StarSize("星星大小", Range(0,5)) = 1
        _StarIntensity("星星强度", Range(0,1)) = 0.5
        _StarSpeed("星星移动速度", Range(0,1)) = 0.5
	
		[Space]
		 [Toggle(_CLOUD1_ON)] _cloud1On ("云层1开关", int) = 0
		_Cloud1Tex("云层1贴图", 2D) = "white" {}
		_Cloud1Speed("云层1 横向速度", Float) = 0.1
		[HDR]_Cloud1TopColor("云层1 顶部颜色", Color) = (1,1,1,0)
		[HDR]_Cloud1BottomColor("云层1 底部颜色", Color) = (0,0,0,0)
		
		[Space]
		 [Toggle(_CLOUD2_ON)] _cloud2On ("云层2开关", int) = 0
		_Cloud2Tex("云层2 贴图", 2D) = "white" {}
		_Cloud2Speed("云层2 横向速度", Float) = 0.1
		[HDR]_Cloud2TopColor("云层2 顶部颜色", Color) = (1,1,1,0)
		[HDR]_Cloud2BottomColor("云层2 底部颜色", Color) = (0,0,0,0)

		// _CloudDistortion("云层扭曲", Float) = 0
		
	}

	SubShader
	{
		Tags{ "RenderType"="Background"  "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest+50" "PreviewType"="Skybox" }
		// Cull Back
		Cull Off ZWrite Off


		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile _ UBPA_FOG_ENABLE
			// #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "../../CommonUtil.hlsl"

			#pragma shader_feature_local _STARS_ON
			#pragma shader_feature_local _CLOUD1_ON
			#pragma shader_feature_local _CLOUD2_ON

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			half4 _MainTex_ST;
			half4 _TopColor;
			half4 _BottomColor;

			// sampler2D _StarsTex;
			// half4 _StarsTex_ST;
			// half4 _StarsColor;
			// half _StarsSpeed;
			// half _StarsBrightness;

			//星星 
			// sampler2D _StarsNoiseTex;
			// half4 _StarsNoiseTex_ST;
		    half4 _StarColor;
		    half _StarIntensity;
		    half _StarSpeed;
		    half _StarSize;
		
			
			TEXTURE2D(_Cloud1Tex);
			SAMPLER(sampler_Cloud1Tex);
			half4 _Cloud1Tex_ST;
			half _Cloud1Speed;
			half4 _Cloud1TopColor;
			half4 _Cloud1BottomColor;


			TEXTURE2D(_Cloud2Tex);
			SAMPLER(sampler_Cloud2Tex);
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
			
				half fogFactor : TEXCOORD2;
			};


			v2f vert(appdata_t v) {
				v2f o;

				float3 t = v.vertex.xyz * _ProjectionParams.z + GetCameraPositionWS().xyz;

				o.pos = TransformObjectToHClip(t);
#if SHADER_API_D3D11 || SHADER_API_METAL || SHADER_API_VULKAN
				o.pos.z = 0;
#else
				o.pos.z = o.pos.w;
#endif
				o.uv.xy = TRANSFORM_TEX(v.rectangular, _MainTex);
				// o.uv.zw = TRANSFORM_TEX(v.texcoord, _StarsNoiseTex);
				o.texcoord = v.texcoord;
				o.fogFactor = ComputeFogFactor(o.pos.z);
				return o;
			}

			 // 星空散列哈希
		    float StarAuroraHash(float3 x) {
			    float3 p = float3(dot(x,float3(214.1 ,127.7,125.4)),
					        dot(x,float3(260.5,183.3,954.2)),
		                    dot(x,float3(209.5,571.3,961.2)) );

			    return -0.001 + _StarIntensity * frac(sin(p)*43758.5453123);
		    }

		    // 星空噪声
		    float StarNoise(float3 st){
		        // 卷动星空
		        st += float3(0,_Time.y*_StarSpeed,0);

		        // fbm
		        float3 i = floor(st);
		        float3 f = frac(st);
		    
			    float3 u = f*f*(3.0-1.0*f);

		        return lerp(lerp(dot(StarAuroraHash( i + float3(0.0,0.0,0.0)), f - float3(0.0,0.0,0.0) ), 
		                         dot(StarAuroraHash( i + float3(1.0,0.0,0.0)), f - float3(1.0,0.0,0.0) ), u.x),
		                    lerp(dot(StarAuroraHash( i + float3(0.0,1.0,0.0)), f - float3(0.0,1.0,0.0) ), 
		                         dot(StarAuroraHash( i + float3(1.0,1.0,0.0)), f - float3(1.0,1.0,0.0) ), u.y), u.z) ;
		    }



	

			half4 frag(v2f i) : SV_Target {
				float time = fmod(_Time.y,60000);

				//叠加颜色
				half4 mainColor = lerp( _BottomColor , _TopColor , i.uv.y);

				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy) * mainColor; 

				//星星方案1，使用原始图
				// #if _STARS_ON 
				// 	//流动
				// 	half starsSpeed = _Time.y * _StarsSpeed * 0.01;
				// 	//UV
				// 	half2 starsuv = i.uv.xy * _StarsTex_ST.xy + _StarsTex_ST.zw;
				// 	starsuv.x += starsSpeed;
					
				// 	half4 starCol = tex2D(_StarsTex, starsuv) * _StarsColor * _StarsBrightness;

				// 	col += starCol;
				// #endif

				//星星方案2，计算得出
				#if _STARS_ON 
					// 星星
				 	int reflection = i.texcoord.y < 0 ? -1 : 1;
			        half star = StarNoise(float3(i.texcoord.x,i.texcoord.y * reflection,i.texcoord.z) * 128 * _StarSize);

			        // half2 starNoise = tex2D(_StarsNoiseTex, i.uv.zw);
			        // half star = starNoise.x * _StarIntensity;
			        half4 starOriCol = half4(_StarColor.r + 3.25 * sin(i.texcoord.x) + 2.45 * (sin(time * _StarSpeed) + 1)*0.5,
			                                   _StarColor.g + 3.85 * sin(i.texcoord.y) + 1.45 * (sin(time * _StarSpeed) + 1)*0.5,
			                                   _StarColor.b + 3.45 * sin(i.texcoord.z) + 4.45 * (sin(time * _StarSpeed) + 1)*0.5,
			                                   _StarColor.a + 3.85 * star);
			        star = star > 0.8 ? star:smoothstep(0.81,0.98,star);

			        half4 starCol = half4((starOriCol * star).rgb,star);

	                starCol = reflection==1?starCol:starCol*0.5;
        			col = col*(1 - starCol.a) + starCol * starCol.a;
				#endif


				#if _CLOUD1_ON 
					half4 cloud1Color = lerp( _Cloud1BottomColor , _Cloud1TopColor , i.uv.y);
					float cloud1Speed = time * _Cloud1Speed * 0.01;

					float2 cloud1uv = i.uv.xy * _Cloud1Tex_ST.xy + _Cloud1Tex_ST.zw;
					cloud1uv.x += cloud1Speed;
					// cloud1uv += temp_output_100_0;

					float4 cloud1Col = SAMPLE_TEXTURE2D(_Cloud1Tex,sampler_Cloud1Tex,cloud1uv) * cloud1Color;

					col += cloud1Col;
				#endif

				#if _CLOUD2_ON 
					half4 cloud2Color = lerp( _Cloud2BottomColor , _Cloud2TopColor , i.uv.y);
					float cloud2Speed = time * _Cloud2Speed * 0.01;

					float2 cloud2uv = i.uv.xy * _Cloud2Tex_ST.xy + _Cloud2Tex_ST.zw;
					cloud2uv.x += cloud2Speed;

					float4 cloud2Col = SAMPLE_TEXTURE2D(_Cloud2Tex,sampler_Cloud2Tex,cloud2uv) * cloud2Color;

					col += cloud2Col;
				#endif

				// UNITY_APPLY_FOG(i.fogCoord,col);
				
				return col;
			}

			ENDHLSL
		}
	}
}
