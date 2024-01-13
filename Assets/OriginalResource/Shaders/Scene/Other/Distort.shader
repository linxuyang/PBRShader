Shader "MC/Scene/Distort"
{
    Properties
    {
        _MainTex ("纹理(a:自发光遮罩)", 2D) = "white" {}
        [HDR]_EmissionColor("自发光颜色", Color) = (0,0,0,0)
        _NoiseTex ("噪声", 2D) = "black" {}
        _FlowParam("流动参数(xy:速度 z：强度 w )", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                // UBPA_FOG_COORDS(1)
                half fogFactor : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            float4 _NoiseTex_ST;
            half3 _FlowParam;
            half3 _EmissionColor;

            v2f vert (appdata v)
            {
                v2f o;
                half3 param = _FlowParam / 100;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex) + param.xy * _Time.y;
                // UBPA_TRANSFER_FOG(o, v.vertex)
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 param = _FlowParam / 100;
                // sample the texture
                half noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv.zw) * 2 -1;
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy+noise*param.z);
                col.rgb += _EmissionColor * col.a;
                col.a = 1;
                // apply fog
                // UBPA_APPLY_FOG(i.fogCoord, col);
                col.rgb = MixFog(col.rgb,i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
