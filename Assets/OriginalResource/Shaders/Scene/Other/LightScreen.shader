Shader "MC/Scene/LightScreen"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        [HDR]_EdgeColor ("EdgeColor", Color) = (1,1,1,1)
        _DepthEdgeWidth("_DepthEdgeWidth",Range(0,1))=0.1
        _UVEdgeWidth("_UVEdgeWidth",Range(0,1))=0.1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull off

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                // UNITY_FOG_COORDS(2)
                half fogFactor : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            half4 _Color;
            half4 _EdgeColor;
            half _DepthEdgeWidth;
            half _UVEdgeWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.projPos = ComputeScreenPos (o.vertex);
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.projPos.z = -TransformWorldToView(positionWS).z;
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 noise = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float sceneZ = LinearEyeDepth (SampleSceneDepth( i.projPos.xy / i.projPos.w),_ZBufferParams);
                float partZ = i.projPos.z;
                bool isDepthEdge = abs(sceneZ - partZ) < _DepthEdgeWidth;
                // bool2 isUVEdgeXY = abs(i.uv.xy-0.5) > (0.5 - _UVEdgeWidth);
                // bool isUVEdge = isUVEdgeXY.x || isUVEdgeXY.y;
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                // half4 col = (isDepthEdge || isUVEdge) ? _EdgeColor : half4(_Color.rgb*noise, _Color.a);
                half4 col = isDepthEdge ? _EdgeColor : half4(_Color.rgb*noise, _Color.a);

                col.rgb = MixFog(col.rgb,i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
