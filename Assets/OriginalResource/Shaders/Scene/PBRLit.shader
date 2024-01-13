Shader "Mc/Scene/PBRLit"
{
    Properties
    {
        _BaseColor ("颜色", Color) = (1,1,1,1)
        _EmiColor ("自发光颜色", Color) = (0,0,0,1)
        _BaseMap ("贴图", 2D) = "white" { }
        _NormalMetalSmoothMap ("法线(RG) 金属(B) 光滑(A)", 2D) = "white" { }
        _EmissiveAOMap ("自发光(RGB) AO(A)", 2D) = "white" { }
        [Toggle] _EmissiveFollowDayNight ("_EmissiveFollowDayNight", Float) = 1
        [Toggle(_RECEIVE_SHADOWS_OFF)] _ReceiveShadowOff ("_ReceiveShadowOff", Float) = 0
        _Cutoff ("透贴强度", Range(0, 1)) = 0.5
        _Transparent ("透明度", Range(0, 1)) = 1
        _Metallic ("金属", Range(0, 1)) = 0
        _Smoothness ("光滑", Range(0, 1)) = 0.5
        _AOStrength ("AO强度", Range(0, 1)) = 1
        _NormalScale ("法线强度", Range(-2, 2)) = 1
        _SpecularTint ("非金属反射着色", Range(0, 1)) = 0.5
        _SpecularStrength ("反射强度", Range(0, 4)) = 0.5
        _FresnelStrength ("菲涅尔强度", Range(0, 8)) = 1
        [ToggleUI] _NewLight ("切换新旧光照", Float) = 0
        [ToggleUI] _IgnoreTextureAlpha ("忽略贴图alpha", Float) = 0
        _BlendMode ("_BlendMode", Float) = 0
        _SrcBlend ("_SrcBlend", Float) = 1
        _DstBlend ("_DstBlend", Float) = 0
        _ZWrite ("_ZWrite", Float) = 1
        [Toggle] _TransparentZWrite ("_TransparentZWrite", Float) = 0
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" { }
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // sample the texture
                return half4(1, 1, 1, 1);
            }
            ENDHLSL
        }
    }
}