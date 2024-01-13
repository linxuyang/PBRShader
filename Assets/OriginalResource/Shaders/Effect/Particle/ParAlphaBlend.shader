Shader "MC/Effect/ParticleAlphaBlend"
{
    Properties
    {
        [HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("Particle Texture", 2D) = "white" {}

        [Space]
        [Toggle(SOFTPARTICLES_ON)]_SoftParticlesEnabled ("软粒子开关", Float) = 0.0
        _InvFade ("软粒子深度系数", Range(0.01,3.0)) = 1.0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }

    Category
    {
        Tags
        {
            "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        // ColorMask RGB
        BlendOp ADD
        Cull Off Lighting Off ZWrite Off

        SubShader
        {
            Pass
            {
                Tags
                {
                    "LightMode"="UniversalForward"
                }

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0
                #pragma multi_compile_particles
                // #pragma multi_compile_fog
                #pragma skip_variants FOG_EXP FOG_EXP2
                #pragma multi_compile _ SOFTPARTICLES_ON

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                half4 _TintColor;
                half _AlphaScale;

                struct appdata_t
                {
                    float4 vertex : POSITION;
                    half4 color : COLOR;
                    float2 texcoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    half4 color : COLOR;
                    float2 texcoord : TEXCOORD0;
                    half fogFactor : TEXCOORD1;
                    #ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD2;
                    #endif
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                float4 _MainTex_ST;

                v2f vert(appdata_t v)
                {
                    v2f o;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                    o.vertex = TransformWorldToHClip(positionWS);
                    #ifdef SOFTPARTICLES_ON
				        o.projPos = ComputeScreenPos (o.vertex);
				        o.projPos.z = -TransformWorldToView(positionWS).z;
                    #endif
                    o.color = v.color * _TintColor;
                    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                    o.fogFactor = ComputeFogFactor(o.vertex.z);
                    return o;
                }

                float _InvFade;

                half4 frag(v2f i) : SV_Target
                {
                    #ifdef SOFTPARTICLES_ON
				        float sceneZ = LinearEyeDepth(SampleSceneDepth( i.projPos.xy / i.projPos.w),_ZBufferParams);
				        float partZ = i.projPos.z;
				        float fade = saturate (_InvFade * (sceneZ-partZ));
				        i.color.a *= fade;
                    #endif

                    half4 col = 2.0f * i.color * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                    col.a = saturate(col.a);
                    col.a *= _AlphaScale;

                    col.rgb = MixFog(col.rgb, i.fogFactor);
                    return col;
                }
                ENDHLSL
            }
        }
    }
}