Shader "MC/Effect/SimpleDissolveMask"
{
    Properties
    {
        [Enum(Additive, 1, Alpha Blend, 10)] _BlendMode ("透明混合模式", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcAlphaBlend("Src透明通道混合", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstAlphaBlend("Dst透明通道混合", Float) = 10
        [HDR]_TintColor ("Tint Color", Color) = (1,1,1,1)
        _MainTex ("主帖图(RGBA)", 2D) = "white" {}
        [Enum(UV1, 1, UV2, 2, screen, 3)] _MainUVMode ("UV模式", int) = 1
        _UVRotate ("主贴图UV旋转", Float) = 0
        [Toggle]_Clamp ("主UVclamp,0或1", int) = 0
        [Space(10)]
        [Toggle] _IfDissA ("溶解按主纹理A方向?", int) = 0
        [Toggle] _IfDissVA ("溶解按顶点ALPHA方向?", int) = 0
        _DissValue("溶解值", Float) = 0
        _DissRate("溶解硬度", Float) = 1
        [Space(10)]
        _Mask ("遮罩强度", Float) = 1
        [Space(20)]
        [Toggle] _IfVertStream ("依赖粒子顶点流?", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", int) = 0
        [Enum(RGBA,15,RGB,14)]_ColorMask("颜色输出模式", Float) = 15
        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        Blend One [_BlendMode],[_SrcAlphaBlend] [_DstAlphaBlend]
        Cull [_Cull] Lighting Off Fog
        {
            Mode Off
        }
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

            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half4 _TintColor;
            int _IfVertStream, _MainUVMode;
            half _IfDissVA, _IfDissA, _DissValue, _DissRate;
            half _Mask, _UVRotate, _Clamp;
            half _AlphaScale;

            struct appdata_t
            {
                float4 vertex : POSITION;
                half4 color : COLOR;
                half4 uv : TEXCOORD0;
                half2 uv1: TEXCOORD1;
                half4 uv2: TEXCOORD2;
                half4 uv3: TEXCOORD3;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
                half fogFactor : TEXCOORD1;
            };


            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.color = v.color;
                
                // 判断选择了哪种UV模式
                int uvMode1 = _MainUVMode == 1;
                int uvMode2 = _MainUVMode == 2;
                int uvMode3 = _MainUVMode == 3;

                // 第一套UV
                half2 uv1 = uvMode1 * v.uv.xy;
                // 第二套UV
                // 如果用了粒子顶点流，则第二套UV储存在TEXCOORD0(即v.uv)的zw分量中，否则储存在TEXCOORD1(即v.uv1)中
                half2 uv2 = uvMode2 * lerp(v.uv1, v.uv.zw, _IfVertStream);
                // 屏幕UV
                half2 screenPos = uvMode3 * ComputeScreenPos(o.vertex).xy / half(o.vertex.w);
                half2 uv = uv1 + uv2 + screenPos;
                uv = uv * _MainTex_ST.xy + v.uv2.xy * _IfVertStream + _MainTex_ST.zw;
                // 以(0.5, 0.5)为中心对uv进行旋转
                uv = Rotate2D(uv - 0.5, radians(_UVRotate)) + 0.5;
                o.uv.xy = uv;
                // 如果用了粒子顶点流，则TEXCOORD1(即v.uv1)存储的是粒子顶点流传进来的数据
                // 若没有使用粒子顶点流，则使用默认值代替
                // o.uv.z:每粒子的溶解值，会在材质球的溶解值参数基础上叠加溶解
                // o.uv.w:控制亮度和颜色对比，可以让亮的地方更亮
                // _DissValue是材质控制的溶解度
                o.uv.zw = max(v.uv1 * _IfVertStream, 0.001);
                // o.uv.z做一次反转(透明度 = 1 - 溶解度), 若勾选了溶解按顶点alpha方向(_IfDissVA)则需叠加上顶点透明度
                o.uv.z = 1 - o.uv.z + v.color.a * _IfDissVA - _DissValue;
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // 勾选了_Clamp的话要把主贴图UV限制在0~1之间
                i.uv.xy = lerp(i.uv.xy, saturate(i.uv.xy), _Clamp);
                
                half4 mainCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy);
                half4 color = mainCol * _TintColor * i.color;
                // 勾选了溶解按主贴图透明度方向(_IfDissA)则需叠加上主贴图的透明度
                half clipTex = mainCol.a * _IfDissA + i.uv.z;
                clipTex = saturate(clipTex * _DissRate);
                color.a *= clipTex;
                
                color.rgb *= color.a * _Mask;
                color.a *= saturate(_Mask);
                color *= _AlphaScale;
                color.rgb = pow(color.rgb, i.uv.w + 1);
                color.rgb = MixFog(color.rgb,i.fogFactor);

                return color;
            }
            ENDHLSL
        }
    }
    //	CustomEditor "EffectShaderGUI"
}
