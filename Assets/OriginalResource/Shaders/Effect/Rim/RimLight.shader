

Shader "MC/Effect/RimLight" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        [HDR]_Color ("Main Color", Color) = (1,1,1,1)
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimWidth ("Rim Width", Float) = 0.7
    }
    SubShader {
		Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
        Pass {
       		Lighting Off
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                struct appdata {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    half2 texcoord : TEXCOORD0;
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    half2 uv : TEXCOORD0;
                    half3 color : COLOR;
                };

                
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                float4 _MainTex_ST;
                half4 _RimColor;
                float _RimWidth;

                v2f vert (appdata v) {
                    v2f o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);

                    float3 viewDir = normalize(TransformWorldToObject(GetCameraPositionWS()) - v.vertex.xyz);
                    float dotProduct = 1 - dot(v.normal, viewDir);
                   
                    o.color = smoothstep(1 - _RimWidth, 1.0, dotProduct);
                    o.color *= _RimColor.rgb;

                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    return o;
                }

                 half4 _Color;

                half4 frag(v2f i) : COLOR {
                    half4 texcol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                    texcol *= _Color;
                    texcol.rgb += i.color;
                    return texcol;
                }
            ENDHLSL
        }
    }
}
