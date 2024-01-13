// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "MC/Scene/Skybox/Cubemap"
{
    Properties
    {
        _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest+50" "RenderType"="Background" "PreviewType"="Skybox"
        }
        Cull Off ZWrite Off

        Pass
        {

            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // samplerCUBE _Tex;
            TEXTURECUBE(_Tex);
            SAMPLER(sampler_Tex);
            half4 _Tex_HDR;
            half4 _Tint;
            half _Exposure;
            float _Rotation;

            float3 RotateAroundYInDegrees(float3 vertex, float degrees)
            {
                float alpha = degrees * PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

            struct appdata_t
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 rotated = RotateAroundYInDegrees(v.vertex.xyz, _Rotation);
                o.vertex = TransformObjectToHClip(rotated.xyz);
                o.texcoord = v.vertex.xyz;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURECUBE(_Tex, sampler_Tex, i.texcoord);
                // half3 c = DecodeHDR (tex, _Tex_HDR);
                half3 c = DecodeHDREnvironment(tex, _Tex_HDR);
                // c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
                c = c * _Tint.rgb * half3(4.59479380, 4.59479380, 4.59479380);
                c *= _Exposure;
                return half4(c, 1);
            }
            ENDHLSL
        }
    }


    Fallback Off

}