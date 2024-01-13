Shader "MC/UI/TextShaderMask"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _SpriteTex("Sprite Texture", 2D) = "white" {}
        
        [Toggle(OUT_LINE)]_OutLine("OutLine", Float) = 0
        _OutlineColor("OutLineColor", Color) =  (0, 0, 0, 0)
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"}
        LOD 100
        Cull Off
		Lighting Off
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha

        Stencil
        {
            Ref 1
            Comp equal
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ OUT_LINE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
                half2 uv2 : TEXCOORD1;
                half4 color : COLOR;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                half2 uv2 : TEXCOORD1;
                half4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _SpriteTex;
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            half4 _SpriteTex_ST;
            half3 _OutlineColor;
            CBUFFER_END

            half DrawOutLine(half x, half y, half2 uv)
            {
                //不支持调整描边宽度，写死0.5
                half2 uvOffset = half2(x , y);
                uvOffset *= _MainTex_TexelSize.xy * 0.5;
                return tex2D(_MainTex, uv + uvOffset).a;
			}

            v2f vert(appdata input)
            {
                v2f output = (v2f) 0;
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv2 = TRANSFORM_TEX(input.uv2, _SpriteTex);
                output.color = input.color;
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                half4 spriteCol = tex2D(_SpriteTex, input.uv2);
                spriteCol.a *= input.color.a;
                half4 color;
                half mainAlpha = tex2D(_MainTex, input.uv).a;
            #ifdef OUT_LINE
                half sum = DrawOutLine(1, 1, input.uv) + DrawOutLine(-1, -1, input.uv) + DrawOutLine(1, -1, input.uv)
                           + DrawOutLine(-1, 1, input.uv);
                color.rgb = _OutlineColor * (1 - mainAlpha) + mainAlpha * input.color.rgb;
                color.a = saturate(sum + mainAlpha) * input.color.a;
            #else
                color.rgb = input.color.rgb;
                color.a = mainAlpha;
            #endif
                half4 col = lerp(spriteCol, color, input.uv2.x == 0);
                return col;
            }
            ENDHLSL
        }
    }
}
