Shader "MC/UI/UIModleWithAlpha"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1, 1, 1, 1)
        [MaterialToggle] PixelSnap("Pixel snap", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Fog
        {
            Mode Off
        }
        Blend One SrcAlpha

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile DUMMY PIXELSNAP_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
                half2 texcoord : TEXCOORD0;
            };

            half4 _Color;

            inline float4 UnityPixelSnap(float4 pos)
            {
                float2 hpc = _ScreenParams.xy * 0.5f;
                #if  SHADER_API_PSSL
    float2 temp = ((pos.xy / pos.w) * hpc) + float2(0.5f,0.5f);
    float2 pixelPos = float2(floor(temp.x), floor(temp.y));
                #else
                float2 pixelPos = round((pos.xy / pos.w) * hpc);
                #endif
                pos.xy = pixelPos / hpc * pos.w;
                return pos;
            }

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color * _Color;
                #ifdef PIXELSNAP_ON
                OUT.vertex = UnityPixelSnap(OUT.vertex);
                #endif

                return OUT;
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            half4 frag(v2f IN) : SV_Target
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.texcoord) * IN.color;
                return c;
            }
            ENDHLSL
        }
    }
}