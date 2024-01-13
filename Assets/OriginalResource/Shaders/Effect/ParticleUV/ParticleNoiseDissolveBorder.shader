Shader "MC/Effect/ParticleNoiseDissolveBorder"
{
    Properties
    {
        _Offset_Z("Z Offset-深度偏移", Float) = 0
        [HDR]_MainColor("Color", Color) = (1, 1, 1, 1)
        [Toggle]_AlphaOnR("Alpha On R-透明度采用R通道", Float) = 0
        _MainTex("MainTex", 2D) = "white" {}
        _MainSpeed_U("U Speed", Float) = 0
        _MainSpeed_V("V Speed", Float) = 0
        [Space]
        [Toggle(_UV1_ON)]_UV_1_On("开启粒子顶点流", Float) = 0
        [Space]
        [Header(Border)]
        [HDR]_BorderColor("Border Color-勾边颜色", Color) = (1, 1, 1, 1)
        _BorderAlphaClipRange("Border Width-勾边宽度", Range(0.001, 0.1)) = 0.001
        _BorderAlphaClip("Border Begin-勾边起始位置", Range(0.001, 0.5)) = 0.001
        [Space]
        [Header(UV Noise)]
        [Toggle(_NOISE_ON)]_NoiseOn("开启噪声纹理", Float) = 0
        _DistorFator("NoiseStrength-噪声强度", Float) = 1
		_NoiseTex("NoiseTex-噪声纹理", 2D) = "black" {}
		_NoiseSpeed_U("U Speed", Float) = 0
		_NoiseSpeed_V("V Speed", Float) = 0
        [Space]
        [Header(Dissolve)]
        [Toggle(_DISSOLVE_ON)]_DissolveOn("开启溶解纹理", Float) = 0
        _DissolveTex("DissolveTex-溶解纹理", 2D) = "white" {}
		_DissolveSpeed_U("U Speed", Float) = 0
		_DissolveSpeed_V("V Speed", Float) = 0
		_Power("SmoothRange-平滑区间", Range(0.5 , 1)) = 0.5
        [Space]
        [Header(Alpha Mask)]
        [Toggle(_MASK_ON)]_MaskOn("开启透明遮罩", Float) = 0
		_Mask("Alpha Mask-透明遮罩", 2D) = "white" {}
		_MaskSpeed("UV Speed", Vector) = (0, 0, 0, 0)
        [Space]
        [Header(Blend Mode)]
        [Enum(Off, 0, Front, 1, Back, 2)]_Cull("Cull Mode-裁剪模式", Float) = 2
        [Enum(One, 1, SrcAlpha, 5)] _ColorSrc("Src Blend-目标混合系数", Float) = 5
        [Enum(One, 1, OneMinusSrcAlpha, 10)] _ColorDst("Dst Blend-背景混合系数", Float) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent"
        }

        Cull [_Cull]
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            Blend[_ColorSrc][_ColorDst]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _UV1_ON
            #pragma shader_feature_local _NOISE_ON
            #pragma shader_feature_local _DISSOLVE_ON
            #pragma shader_feature_local _MASK_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half4 color : COLOR;
                half4 texcoord1 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half4 uv : TEXCOORD0;
                half4 texcoord1 : TEXCOORD1;
                half4 uv1 : TEXCOORD2;
                half4 color : TEXCOORD3;
            };

            half _Offset_Z;
            half4 _MainColor;
            half _AlphaOnR;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half _MainSpeed_U, _MainSpeed_V;
            
            half4 _BorderColor;
            half _BorderAlphaClipRange, _BorderAlphaClip;
            
            half _DistorFator;
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            half4 _NoiseTex_ST;
            half _NoiseSpeed_U, _NoiseSpeed_V;

            TEXTURE2D(_DissolveTex);
            SAMPLER(sampler_DissolveTex);
            half4 _DissolveTex_ST;
            half _DissolveSpeed_U, _DissolveSpeed_V;
            half _Power;
            
            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);
            half4 _Mask_ST;
            half4 _MaskSpeed;

            //根据透明度值返回勾边颜色
            half3 BorderColor(half alpha)
            {
                //计算透明度与勾边起始透明度值的差
                half dis = alpha - _BorderAlphaClip;
                //根据勾边范围(即宽度)计算出勾边颜色强度
                half borderVal = (_BorderAlphaClipRange - dis) / _BorderAlphaClipRange;
                //将勾边效果限制在透明度范围 [_BorderAlphaClip, _BorderAlphaClip + _BorderAlphaClipRange] 内 
                borderVal = step(0, dis) * max(borderVal, 0);
                return _BorderColor * borderVal;
            }

            v2f vert(appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                //在(顶点->摄像机)方向做偏移
                float3 offsetVector = normalize(GetCameraPositionWS() - worldPos);
                worldPos += offsetVector * _Offset_Z;
                //顶点坐标从世界空间转换到裁剪空间
                o.vertex = TransformWorldToHClip(worldPos.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex); //主纹理拉伸、偏移后的UV
                o.color = v.color;
                
                #if _MASK_ON
                o.uv.zw = TRANSFORM_TEX(v.uv, _Mask); //遮罩纹理拉伸、偏移后的UV
                #endif

                #if _NOISE_ON
                o.uv1.xy = TRANSFORM_TEX(v.uv, _NoiseTex); //噪声纹理拉伸、偏移后的UV
                #endif

                #if _DISSOLVE_ON
                o.uv1.zw = TRANSFORM_TEX(v.uv, _DissolveTex); //溶解纹理拉伸、偏移后的UV
                #endif

                o.texcoord1 = v.texcoord1;
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                half time = _Time.y;
                half2 uv;

                half2 noise = 0;
                #if _NOISE_ON
                //噪声纹理01UV叠加时间偏移
                uv = i.uv1.xy + time * half2(_NoiseSpeed_U, _NoiseSpeed_V);
                noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,uv);
                //根据_DistorFator缩放噪声数据
                noise *= _DistorFator;
                #endif
                
                #if _UV1_ON
                //根据i.texcoord1.y(通过顶点粒子流传入)缩放噪声数据
                noise *= i.texcoord1.y;
                //主纹理UV叠加i.texcoord1.zw(通过顶点粒子流传入)
                uv = i.uv.xy + i.texcoord1.zw + noise;
                #else     
                //主纹理UV叠加时间偏移与噪声偏移
                uv = i.uv.xy + time * half2(_MainSpeed_U, _MainSpeed_V) + noise;
                #endif
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);
                //开启了_AlphaOnR的情况下, 使用主纹理的R通道作为透明度输出
                col.a = lerp(col.a, col.r, _AlphaOnR);
                col *= _MainColor * i.color;

                #if _DISSOLVE_ON
                //溶解纹理UV叠加时间偏移
                uv = i.uv1.zw + time * half2(_DissolveSpeed_U, _DissolveSpeed_V);
                half dissolve = SAMPLE_TEXTURE2D(_DissolveTex,sampler_DissolveTex,uv);
                dissolve = saturate(dissolve + 1 - 2 * i.texcoord1.x);
                dissolve = smoothstep(1 - _Power, _Power, dissolve);
                col.a *= dissolve;
                #endif

                #if _MASK_ON
                //遮罩纹理UV叠加时间偏移
                uv = i.uv.zw + time * _MaskSpeed;
                half mask = SAMPLE_TEXTURE2D(_Mask,sampler_Mask,uv);
                //在透明度上应用遮罩和溶解效果
                col.a *= mask;
                #endif

                //应用透明度勾边效果
                col.rgb += BorderColor(col.a);

                return col;
            }
            ENDHLSL
        }
    }
}
