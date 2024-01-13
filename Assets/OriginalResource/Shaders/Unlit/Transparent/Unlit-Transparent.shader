// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "MC/Unit/Transparent/Unlit-Transparent"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _AlphaTex("AlphaTex",2D) = "white"{}

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }
    SubShader
    {

        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"
        }
        LOD 100
        Lighting Off
        // ZTest Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_AlphaTex);
            SAMPLER(sampler_AlphaTex);

            CBUFFER_START(UnityPerMaterial)
            float _AlphaFactor;
            half _AlphaScale;
            half4 _MainTex_ST;
            half4 _AlphaTex_ST;
            CBUFFER_END

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color :COLOR;
                half fogFactor : TEXCOORD1;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.texcoord;
                o.color = v.color;
                o.fogFactor = ComputeFogFactor(o.pos.z);
                return o;
            }

            half4 frag(v2f i) : COLOR
            {
                half4 texcol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                half4 alphacol = SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex,i.uv);
                half4 result = texcol;
                result.a = alphacol.a;
                result.a *= _AlphaScale;
                result.rgb = MixFog(result.rgb, i.fogFactor);
                return result;
            }
            ENDHLSL
        }
    }
}
