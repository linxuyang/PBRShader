Shader "MC/Scene/Skybox/BackGround"
{
    Properties
    {
        _MainTex ("Texture (R)", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "Queue"="AlphaTest+50" "RenderType"="Background"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Zwrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            half4 _MainTex_ST;
            uniform float _RotateSpeed;


            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 rectangular : TEXCOORD0;
                float2 polar : TEXCOORD1;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                // UBPA_FOG_COORDS(1)
            };

            v2f vert(appdata_t v)
            {
                v2f o;

                float3 t = v.vertex.xyz * _ProjectionParams.z + _WorldSpaceCameraPos.xyz;

                o.pos = TransformObjectToHClip(t);
                #if SHADER_API_D3D11 || SHADER_API_METAL || SHADER_API_VULKAN
                o.pos.z = 0;
                #else
				o.pos.z = o.pos.w;
                #endif
                o.uv = TRANSFORM_TEX(v.rectangular, _MainTex);
                // UBPA_TRANSFER_FOG(o, v.vertex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                // UBPA_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL

        }
    }

    Fallback Off
}