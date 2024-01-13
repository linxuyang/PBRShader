
Shader "MC/Effect/DissolveDistortMaskClip" 
{
	Properties 
	{
		_AlphaCut("Alpha Cutout", Range(0, 1)) = 0
		[HDR]_TintColor ("Tint Color", Color) = (1,1,1,1)
		//_HighColor ("高光颜色A：灰度开启", Color) = (1,1,1,0)
		//_ShadowColor ("阴影颜色A：比重", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("主帖图(RGBA)", 2D) = "white" {}
		[Enum(UV1, 1, UV2, 2, screen, 3)] _MainUVMode ("UV模式", int) = 1
		//[Toggle] _MainUseUV2 ("使用UV2?", int) = 0
		[Toggle] _IfDissA ("溶解按主纹理A方向?", int) = 0
		_CDistBlend ("主帖图扭曲过渡", Range(0, 1)) = 0
        _Mdis ("主纹理UV扭曲/溶解值/溶解硬度",vector) = (0,0,0,1)
		
		//[Header(溶解)]
		_DissSrc ("溶解(R||G||B)", 2D) = "white" {}
		[Enum(UV1, 1, UV2, 2, screen, 3)] _DissUVMode ("UV模式", int) = 1
		//[Toggle] _DissUseUV2 ("使用UV2?", int) = 0
		[Toggle] _DissChange ("溶解变扭曲?", int) = 0
		_DDistBlend ("溶解图扭曲过渡", Range(0, 1)) = 0
		_Adis ("反向溶解",Range(0,1)) = 0
		_DissP ("溶解UV扭曲/溶解UV流动速度",vector) = (0,0,0,0)

		//[Header(遮罩)]
		_MaskSrc ("遮罩(R||G||B)", 2D) = "white" {}
		[Enum(UV1, 1, UV2, 2, screen, 3)] _MaskUVMode ("UV模式", int) = 1
	//	[Toggle] _MaskUseUV2 ("使用UV2?", int) = 0
		[Toggle] _IfDissM ("溶解按遮罩方向?", int) = 0
		_MDistBlend ("遮罩图扭曲过渡", Range(0, 1)) = 0
		_MaskP ("遮罩UV扭曲/遮罩UV流动速度",vector) = (0,0,0,0)
		
		//[Header(扭曲)]
		_DistSrc ("扭曲(R||G||B)", 2D) = "white" {}
		[Enum(UV1, 1, UV2, 2, screen, 3)] _DistUVMode ("UV模式", int) = 1
		//[Toggle] _DistUseUV2 ("使用UV2?", int) = 0
		_DistP ("遮罩强度/对比/扭曲UV流动速度",vector) = (1,1,0,0)
		[Space(10)]
		_UVRotate ("主/溶解/遮罩/扭曲旋转",vector) = (0,0,0,0)
		_Clamp ("主/溶解/遮罩/扭曲UVclamp,0或1",vector) = (0,0,0,0)
		[Space(10)]
		[Toggle] _IfDissVA ("溶解按顶点ALPHA方向?", int) = 0
		[Toggle(_FRESNEL_ON)] _Fresnel ("菲涅尔?", int) = 0
		[Toggle] _IfDissF ("溶解按菲尼尔方向?", int) = 0
		_RimP ("菲涅尔过渡/硬度(负数为反向)/偏移",vector) = (1,1,0,1)
		[Space(20)]
		//_add ("add",Range(0,1)) = 0
		[Toggle] _IfVertStream ("依赖粒子顶点流?", int) = 1
		[Toggle] _IfRandomDist ("每粒子随机扭曲UV", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", int) = 0
		[Enum(RGBA,15,RGB,14)]_ColorMask("颜色输出模式", Float) = 15
	
		
		[Toggle(SOFTPARTICLES_ON)]_SoftParticlesEnabled ("软粒子开关", Float) = 0.0
		_InvFade ("软粒子深度系数", Range(0.01,3.0)) = 1.0

		
	}

	SubShader 
		{

		Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest" "RenderType"="TransparentCutout" "IgnoreProjector"="True" "PreviewType"="Plane"}
		Cull [_Cull] Lighting Off Fog { Mode Off }
		ZWrite On
		ColorMask [_ColorMask]
		ZTest [_ZTest]
		//ColorMask RGB

			Pass 
			{
				Tags{"LightMode" = "UniversalForward"}
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile _ SOFTPARTICLES_ON
				
				#pragma shader_feature_local _FRESNEL_ON

            	// #pragma multi_compile_fog
				#pragma skip_variants FOG_EXP FOG_EXP2
				

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
				#include "../../CommonUtil.hlsl"

				half _AlphaCut;
				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);
				TEXTURE2D(_DissSrc);
				SAMPLER(sampler_DissSrc);
				TEXTURE2D(_MaskSrc);
				SAMPLER(sampler_MaskSrc);
				TEXTURE2D(_DistSrc);
				SAMPLER(sampler_DistSrc);
				half4 _MainTex_ST,_DissSrc_ST,_MaskSrc_ST,_DistSrc_ST;
				
				half4 _TintColor;
				int _IfVertStream,_IfRandomDist;
				half _Adis,_IfDissVA,_IfDissA,_IfDissM,_IfDissF,_MainUVMode,_DissUVMode,_MaskUVMode,_DistUVMode,_CDistBlend,_DDistBlend,_MDistBlend,_DissChange;
				half4 _Mdis,_DissP,_DistP,_MaskP,_RimP,_UVRotate,_Clamp;

			#if SOFTPARTICLES_ON
				float _InvFade;
			#endif

				struct appdata_t 
				{
					float4 vertex : POSITION;
					half4 color : COLOR;
					half4 uv : TEXCOORD0;
				#if _FRESNEL_ON
					float3 normal : NORMAL;
				#endif	
					half4 uv1: TEXCOORD1;
					half4 uv2: TEXCOORD2;
					half4 uv3: TEXCOORD3;
				};

				struct v2f 
				{
					float4 vertex : SV_POSITION;
					half4 color : COLOR;
					half4 uv : TEXCOORD0;
					half4 duv : TEXCOORD1;
					half4 duv1 : TEXCOORD2;
					
				#if _FRESNEL_ON
					float3 normal : NORMAL;
					float3 objViewDir : TEXCOORD3;
				#endif	
				
                #if SOFTPARTICLES_ON
                    float4 screenPos : TEXCOORD4;
                #endif
                    half fogFactor : TEXCOORD5;
				};
				
				

				v2f vert (appdata_t v)
				{
					v2f o;
					
				
					v.uv.zw = v.uv.zw*_IfVertStream + v.uv1.xy*(1-_IfVertStream);
				
					v.uv2 *= _IfVertStream;
					v.uv3 *= _IfVertStream;
					float time = fmod(_Time.y,60000);
					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.color = v.color;
					#if _FRESNEL_ON
					o.normal = v.normal;
					o.objViewDir = TransformWorldToObject(GetCameraPositionWS()) - v.vertex.xyz;
					#endif	
				#if UNITY_UV_STARTS_AT_TOP
					float scale = -1.0;
				#else
					float scale = 1.0;
				#endif
					half2 screenuv = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
					//screenuv放到frag下计算
					o.uv = half4(_MainUVMode==3 ? v.uv2.xy : ((_MainUVMode==1?v.uv.xy:v.uv.zw) * _MainTex_ST.xy + v.uv2.xy + _MainTex_ST.zw),v.uv1.xy*_IfVertStream);

					o.duv.xy = _DissUVMode==3 ? v.uv2.zw : ((_DissUVMode==1?v.uv.xy:v.uv.zw) * _DissSrc_ST.xy + v.uv2.zw + _DissP.zw * time + _DissSrc_ST.zw); //溶解图的UV
					o.duv.zw = screenuv; 

					v.uv3.x = _IfRandomDist ? v.uv3.x : 0;
					o.duv1.xy =_DistUVMode==3 ? v.uv3.xx : ((_DistUVMode==1 ? v.uv.xy : v.uv.zw) * _DistSrc_ST.xy  + _DistP.zw * time + _DistSrc_ST.zw + v.uv3.xx); //扭曲图的UV  //v.uv3.x增加每粒子随机UV
					o.duv1.zw = (_MaskUVMode==1 ? v.uv.xy : v.uv.zw) * _MaskSrc_ST.xy  + _MaskP.zw * time + _MaskSrc_ST.zw; //MASK图的UV
					
					o.uv.xy = Rotate2D(o.uv.xy - 0.5, radians(_UVRotate.x)) + 0.5;
					o.duv.xy = Rotate2D(o.duv.xy - 0.5, radians(_UVRotate.y)) + 0.5;
					o.duv1.zw = Rotate2D(o.duv1.zw - 0.5, radians(_UVRotate.z)) + 0.5;
					o.duv1.xy = Rotate2D(o.duv1.xy - 0.5, radians(_UVRotate.w)) + 0.5;

                #if SOFTPARTICLES_ON
					float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                    o.screenPos = ComputeScreenPos(o.vertex);
                    o.screenPos.z = -TransformWorldToView(positionWS).z;
                #endif
                    o.fogFactor = ComputeFogFactor(o.vertex.z);
					return o;
				}
			
				half4 frag (v2f i) : SV_Target
				{
					float time = fmod(_Time.y,60000);

					
					i.duv1.xy =_Clamp.w?clamp(i.duv1.xy,0,1):i.duv1.xy;

					half fresnel = 1;
					#if _FRESNEL_ON
					
					fresnel = pow(abs(dot(normalize(i.normal),normalize(i.objViewDir))),_RimP.x) * _RimP.y + _RimP.z;
					
               		#endif
					//half3 SecTex;					 
					half2 screenuv = i.duv.zw / i.vertex.w;
					

					//screenuv不考虑CLAMP
					i.duv1.xy = _DistUVMode==3 ? (screenuv * _DistSrc_ST.xy + _DistP.zw * time + _DistSrc_ST.zw + i.duv1.xy) : i.duv1.xy;

					half3 distTex = SAMPLE_TEXTURE2D(_DistSrc,sampler_DistSrc,i.duv1.xy).rgb; 
					half distort = max(distTex.r,max(distTex.g,distTex.b)); //niuqu
					
					            
					i.duv.xy += distort * _DissP.xy;
					i.duv1.zw += distort * _MaskP.xy;

					
					i.duv.xy = lerp(i.duv.xy,distTex.rg,_DDistBlend);
					i.duv1.zw = lerp(i.duv1.zw,distTex.rg,_MDistBlend);

					
					i.duv.xy =_Clamp.y ? clamp(i.duv.xy,0,1) : i.duv.xy;
					i.duv1.zw = _Clamp.z ? clamp(i.duv1.zw,0,1) : i.duv1.zw;
					//screenuv不考虑CLAMP
					i.duv.xy =	_DissUVMode==3 ? (i.duv.xy + screenuv * _DissSrc_ST.xy  + _DissP.zw * time + _DissSrc_ST.zw) : i.duv.xy;
					i.duv1.zw = _MaskUVMode==3 ? (screenuv * _MaskSrc_ST.xy + _MaskP.zw * time + _MaskSrc_ST.zw) : i.duv1.zw;
					

					half3 dissTex = SAMPLE_TEXTURE2D(_DissSrc,sampler_DissSrc,i.duv.xy).rgb;
					half diss = max(dissTex.r,max(dissTex.g,dissTex.b)); //rongjie


					i.uv.xy += _DissChange ? (diss+distort)*_Mdis.xy : distort*_Mdis.xy;  
					i.uv.xy = lerp(i.uv.xy,distTex.rg,_CDistBlend);    
					i.uv.xy = _Clamp.x ? clamp(i.uv.xy,0,1) : i.uv.xy;
					i.uv.xy = _MainUVMode==3 ? (screenuv * _MainTex_ST.xy + _MainTex_ST.zw + i.uv.xy) : i.uv.xy;
					half4 base = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);

					diss -= i.uv.z + _Mdis.z; //粒子系统customdata 1

				    half3 maskTex = SAMPLE_TEXTURE2D(_MaskSrc,sampler_MaskSrc,i.duv1.zw).rgb;
					half mask = max(maskTex.r,max(maskTex.g,maskTex.b));  
					
					mask =	pow(mask * _DistP.x , _DistP.y);
				    half ClipTex;
					

		 
					ClipTex = lerp(mask * _IfDissM + base.a * _IfDissA + fresnel * _IfDissF + i.color.a * _IfDissVA + diss , diss - i.color.a * _IfDissVA - base.a * _IfDissA - fresnel * _IfDissF - mask * _IfDissM,_Adis); //_DissA控制是否跟随A通道溶解 _DissF控制是否跟随fresnel溶解
					ClipTex = saturate(ClipTex*_Mdis.w);

					mask = _IfDissM ? 1 : mask;
			

					//half gray = Luminance(base.rgb); 

  					//half3 high = lerp(gray * _ShadowColor.rgb,_HighColor.rgb, smoothstep(_ShadowColor.a,1,gray));//基于灰度图变色
					// 
			
					//base.rgb = lerp(base.rgb + _ShadowColor.rgb ,high,_HighColor.a);
					half4 color = half4(base.rgb, base.a * ClipTex) * _TintColor * i.color;
				
					color.a = saturate(color.a * fresnel)  ;
					color.rgb *= color.a * mask;
					color.a *= saturate(mask);
					
                #if SOFTPARTICLES_ON
                    float sceneZ = LinearEyeDepth(SampleSceneDepth( i.screenPos.xy / i.screenPos.w),_ZBufferParams);
                    float partZ = i.screenPos.z;
                    float fade = saturate(_InvFade * (sceneZ-partZ));
                    color.a *= fade;
                    clip(color.a - _AlphaCut);
					return half4(pow(color.rgb,i.uv.w+1)*fade, color.a);
                #endif
				    clip(color.a - _AlphaCut);
				    color.rgb = MixFog(color.rgb,i.fogFactor);
	                return half4(pow(color.rgb,i.uv.w+1), color.a);

				}
				ENDHLSL 
			}
		}
	//	CustomEditor "EffectShaderGUI"
}
