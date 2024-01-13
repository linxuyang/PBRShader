Shader "MC/Effect/DissolveDistortMask"
{
    Properties
    {
        [Enum(One, 1, Alpha, 5)] _SrcAlphaMode ("自身透明度模式", Float) = 1
        [Enum(Additive, 1, Alpha Blend, 10)] _BlendMode ("透明混合模式", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcAlphaBlend("Src透明通道混合", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstAlphaBlend("Dst透明通道混合", Float) = 10
        [HDR]_TintColor ("Tint Color", Color) = (1,1,1,1)
        //_HighColor ("高光颜色A：灰度开启", Color) = (1,1,1,0)
        //_ShadowColor ("阴影颜色A：比重", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("主帖图(RGBA)", 2D) = "white" {}
        [Enum(UV1, 1, UV2, 2, screen, 3)] _MainUVMode ("UV模式", int) = 1
        [Toggle] _IfDissA ("溶解按主纹理A方向?", int) = 0
        _CDistBlend ("主帖图扭曲过渡", Range(0, 1)) = 0
        _Mdis ("主纹理UV扭曲/溶解值/溶解硬度", vector) = (0,0,0,1)

        //[Header(溶解)]
        [Toggle(_DISS_ON)] _DissOn ("开启溶解?", int) = 0
        _DissSrc ("溶解(R||G||B)", 2D) = "white" {}
        [Toggle] _DissChange ("溶解变扭曲?", int) = 0
        _DDistBlend ("溶解图扭曲过渡", Range(0, 1)) = 0
        _DissP ("溶解UV扭曲/溶解UV流动速度", vector) = (0,0,0,0)

        //[Header(遮罩)]
        [Toggle(_MASK_ON)] _MaskOn("开启遮罩?", int) = 0
        _MaskSrc ("遮罩(R||G||B)", 2D) = "white" {}
        [Enum(UV1, 1, UV2, 2)] _MaskUVMode ("UV模式", int) = 1
        [Toggle] _IfDissM ("溶解按遮罩方向?", int) = 0
        _MDistBlend ("遮罩图扭曲过渡", Range(0, 1)) = 0
        _MaskP ("遮罩UV扭曲/遮罩UV流动速度", vector) = (0,0,0,0)

        //[Header(扭曲)]
        [Toggle(_DIST_ON)] _DistOn("开启扭曲?", int) = 0
        _DistSrc ("扭曲(R||G||B)", 2D) = "white" {}
        _DistP ("遮罩强度/对比/扭曲UV流动速度", vector) = (1,1,0,0)
        [Space(10)]
        _UVRotate ("主/溶解/遮罩/扭曲旋转", vector) = (0,0,0,0)
        _Clamp ("主/溶解/遮罩/扭曲UVclamp,0或1", vector) = (0,0,0,0)
        [Space(10)]
        [Toggle] _IfDissVA ("溶解按顶点ALPHA方向?", int) = 0
        [Toggle(_FRESNEL_ON)] _Fresnel ("菲涅尔?", int) = 0
        _RimP ("菲涅尔过渡/硬度(负数为反向)/偏移", vector) = (1,1,0,1)
        [Space(20)]
        [Toggle] _IfVertStream ("依赖粒子顶点流?", int) = 1
        [Toggle] _IfRandomDist ("每粒子随机扭曲UV", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", int) = 0
        [Enum(RGBA,15,RGB,14)]_ColorMask("颜色输出模式", Float) = 15


        [Toggle(SOFTPARTICLES_ON)]_SoftParticlesEnabled ("软粒子开关", Float) = 0.0
        _InvFade ("软粒子深度系数", Range(0.01,3.0)) = 1.0
        
        [Space]
		[Toggle(UNITY_UI_CLIP_RECT)]_UnityUIClipRect ("开启UI遮罩", Float) = 0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        Blend [_SrcAlphaMode] [_BlendMode],[_SrcAlphaBlend] [_DstAlphaBlend]
        Cull [_Cull] Lighting Off
        ZWrite Off
        ColorMask [_ColorMask]
        ZTest [_ZTest]

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma multi_compile _ SOFTPARTICLES_ON

            #pragma shader_feature_local _FRESNEL_ON
            #pragma shader_feature_local _DISS_ON
            #pragma shader_feature_local _MASK_ON
            #pragma shader_feature_local _DIST_ON
            #pragma shader_feature UNITY_UI_CLIP_RECT


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../../CommonUtil.hlsl"


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;

            half4 _TintColor;
            int _IfVertStream;
            half _IfDissVA, _IfDissA, _IfDissM, _MainUVMode, _CDistBlend, _DissChange;
            half4 _Mdis, _DistP, _UVRotate, _Clamp;
            half3 _RimP;
            half _AlphaScale;
            
            #if _DISS_ON
            TEXTURE2D(_DissSrc);
            SAMPLER(sampler_DissSrc);
            half4 _DissSrc_ST, _DissP;
            half _DDistBlend;
            #endif

            #if _MASK_ON
            TEXTURE2D(_MaskSrc);
            SAMPLER(sampler_MaskSrc);
            half4 _MaskSrc_ST, _MaskP;
            half _MaskUVMode, _MDistBlend;
            #endif

            #if _DIST_ON
            TEXTURE2D(_DistSrc);
            SAMPLER(sampler_DistSrc);
            half4 _DistSrc_ST;
            half _IfRandomDist;
            #endif
            
            #if SOFTPARTICLES_ON
			half _InvFade;
            #endif


            float4 _ClipRect;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;

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
                float4 uv : TEXCOORD0;
                float4 duv : TEXCOORD1;
                float4 duv1 : TEXCOORD2;
                #if _FRESNEL_ON
				float3 normal : NORMAL;
				float3 objViewDir : TEXCOORD3;
                #endif
                #if SOFTPARTICLES_ON
                float eyeDepth : TEXCOORD4;
                #endif
                half fogFactor : TEXCOORD5;
                #ifdef UNITY_UI_CLIP_RECT
                half2 rectMask : TEXCOORD6;
                #endif
            };


            v2f vert(appdata_t v)
            {
                v2f o;
                ZERO_INITIALIZE(v2f, o);
                v.uv.zw = lerp(v.uv1.xy, v.uv.zw, _IfVertStream);

                v.uv2 *= _IfVertStream;
                
                float time = fmod(_Time.y, 60000);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.color = v.color;

                #if _FRESNEL_ON
				o.normal = v.normal;
				o.objViewDir = TransformWorldToObject(GetCameraPositionWS()) - v.vertex.xyz;
                #endif

                //screenuv放到frag下计算
                half uvMode3 = step(3, _MainUVMode);
                half uvMode2 = (1 - uvMode3) * step(2, _MainUVMode);
                half uvMode1 = 1 - uvMode3 - uvMode2;
                half2 uvOffset = v.uv2.xy + _MainTex_ST.zw;
                half2 uv1 = uvMode1 * (v.uv.xy * _MainTex_ST.xy + uvOffset);
                half2 uv2 = uvMode2 * (v.uv.zw * _MainTex_ST.xy + uvOffset);
                half2 uv3 = uvMode3 * v.uv2.xy;
                o.uv.xy = uv1 + uv2 + uv3;

                o.uv.zw = max(v.uv1.xy * _IfVertStream, 0.001);

                o.duv.zw = ComputeScreenPos(o.vertex).xy;

                o.uv.xy = Rotate2D(o.uv.xy - 0.5, radians(_UVRotate.x)) + 0.5;
                
                #if _DISS_ON
                o.duv.xy = v.uv.xy * _DissSrc_ST.xy + v.uv2.zw + _DissP.zw * time + _DissSrc_ST.zw; //溶解图的UV
                o.duv.xy = Rotate2D(o.duv.xy - 0.5, radians(_UVRotate.y)) + 0.5;
                #endif

                #if _MASK_ON
                //MASK图的UV
                uvMode1 = step(_MaskUVMode, 1);
                o.duv1.zw = lerp(v.uv.zw, v.uv.xy, uvMode1);
                o.duv1.zw = o.duv1.zw * _MaskSrc_ST.xy + _MaskP.zw * time + _MaskSrc_ST.zw;
                o.duv1.zw = Rotate2D(o.duv1.zw - 0.5, radians(_UVRotate.z)) + 0.5;
                #endif

                #if _DIST_ON
                //扭曲图的UV  //v.uv3.x增加每粒子随机UV
                v.uv3 *= _IfVertStream;
                v.uv3.x *= _IfRandomDist;
                o.duv1.xy = v.uv.xy * _DistSrc_ST.xy + _DistP.zw * time + _DistSrc_ST.zw + v.uv3.xx;
                o.duv1.xy = Rotate2D(o.duv1.xy - 0.5, radians(_UVRotate.w)) + 0.5;
                #endif
                
                #if SOFTPARTICLES_ON
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.eyeDepth = -TransformWorldToView(positionWS).z;
                #endif
                o.fogFactor = ComputeFogFactor(o.vertex.z);

                #ifdef UNITY_UI_CLIP_RECT
                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                // 在屏幕空间计算当前顶点相对RectMask中心点的偏移Vector2(这里计算出来的结果是实际偏移的两倍, 后续的相关计算也同样都是两倍)
                o.rectMask = o.duv.zw / o.vertex.w * _ScreenParams.xy * 2 - clampedRect.xy - clampedRect.zw;
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half mask = 1;

                #ifdef UNITY_UI_CLIP_RECT
                // 对接UI的RectMask2D遮罩，以下计算都是基于屏幕空间坐标系
                // 计算当前位置在XY轴上与裁剪边界的距离(在边界内为正数, 在边界外为负数, 计算得到的结果是实际数值的两倍)
                half2 rectMask = _ClipRect.zw - _ClipRect.xy - abs(i.rectMask);
                // 根据柔性遮罩的数值做过渡处理, 在边界内，距离边界越远则越不透明, 距离大于_UIMaskSoftness则不受影响
                rectMask /= half2(_UIMaskSoftnessX, _UIMaskSoftnessY);
                rectMask = saturate(rectMask);
                mask *= rectMask.x * rectMask.y;
                clip(mask - 0.001);
                #endif
                
                half4 camp = ceil(saturate(_Clamp));
                
                half3 distTex = half3(1, 1, 1);
                half distort = 1;
                #if _DIST_ON
                    i.duv1.xy = lerp(i.duv1.xy, clamp(i.duv1.xy, 0, 1), camp.w);
                    distTex = SAMPLE_TEXTURE2D(_DistSrc,sampler_DistSrc,i.duv1.xy).rgb;
                    distort = max(distTex.r, max(distTex.g, distTex.b)); //niuqu
                #endif
                
                half diss = 1;
                #if _DISS_ON
                    i.duv.xy += distort * _DissP.xy;
                    i.duv.xy = lerp(i.duv.xy, distTex.rg, _DDistBlend);
                    i.duv.xy = lerp(i.duv.xy, clamp(i.duv.xy, 0, 1), camp.y);
                    half3 dissTex = SAMPLE_TEXTURE2D(_DissSrc,sampler_DissSrc,i.duv.xy).rgb;
                    diss = max(dissTex.r, max(dissTex.g, dissTex.b)); //rongjie
                #endif
                
                i.uv.xy += _Mdis.xy * (distort + _DissChange * diss);
                i.uv.xy = lerp(i.uv.xy, distTex.rg, _CDistBlend);
                i.uv.xy = lerp(i.uv.xy, clamp(i.uv.xy, 0, 1), camp.x);

                float2 screenuv = i.duv.zw / i.vertex.w;
                i.uv.xy += step(3, _MainUVMode) * (screenuv * _MainTex_ST.xy + _MainTex_ST.zw);
                
                #if _MASK_ON
                    i.duv1.zw += distort * _MaskP.xy;
                    i.duv1.zw = lerp(i.duv1.zw, distTex.rg, _MDistBlend);
                    i.duv1.zw = lerp(i.duv1.zw, clamp(i.duv1.zw, 0, 1), camp.z);
                    half3 maskTex = SAMPLE_TEXTURE2D(_MaskSrc,sampler_MaskSrc,i.duv1.zw).rgb;
                    mask = max(maskTex.r, max(maskTex.g, maskTex.b));
                #endif
                
                mask = pow(mask * _DistP.x, _DistP.y);

                half4 base = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                diss -= i.uv.z + _Mdis.z; //粒子系统customdata 1
                half ClipTex = mask * _IfDissM + base.a * _IfDissA + i.color.a * _IfDissVA + diss;
                //_DissA控制是否跟随A通道溶解 _DissF控制是否跟随fresnel溶解
                ClipTex = saturate(ClipTex * _Mdis.w);

                half4 color = base * _TintColor * i.color;
                color.a *= ClipTex;
                
                #if _FRESNEL_ON
                    half fresnel = pow(abs(dot(normalize(i.normal), normalize(i.objViewDir))), _RimP.x) * _RimP.y + _RimP.z;
                    color.a *= fresnel;
                #endif
                
                color.a = saturate(color.a);

                mask = lerp(mask, 1, _IfDissM);
                color.rgb *= color.a * mask * _AlphaScale;
                color.a *= saturate(mask);
                color.a *= _AlphaScale;
                color.rgb = pow(color.rgb, i.uv.w + 1);
                
                color.rgb = MixFog(color.rgb,i.fogFactor);

                #if SOFTPARTICLES_ON
                    float sceneZ =  LinearEyeDepth(SampleSceneDepth( i.duv.zw / i.vertex.w),_ZBufferParams);
                    float fade = saturate(_InvFade * (sceneZ - i.eyeDepth));
                    color *= fade;
                #endif
                return color;
            }
            ENDHLSL
        }
    }
    //	CustomEditor "EffectShaderGUI"
}
