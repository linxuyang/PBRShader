// Upgrade NOTE: upgraded instancing buffer 'MyProperties' to new syntax.

// Upgrade NOTE: upgraded instancing buffer 'MyProperties' to new syntax.

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "MC/Effect/ParticleAdditiveHdr"
{
    Properties
    {
        [HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("Particle Texture", 2D) = "white" {}
        [HDR]_Color ("Color", Color) = (0.5,0.5,0.5,0.5)
        _Speed ("Speed", float) = 0
        [Toggle(ALPHALIGHT_ON)] _AlphaLight ("AlphaLight", Float) = 0
        _AlphaLightSpeed ("AlphaLightSpeed", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("DstBlend 目标混合方式", float) = 5 // SrcAlpha
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 0 //"Off"
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 0 //"Off"

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
        Blend SrcAlpha [_DstBlend]
        ColorMask RGB
        Cull [_Cull]
        Lighting Off ZWrite [_ZWrite]

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
                #pragma multi_compile_instancing
                #pragma shader_feature ALPHALIGHT_ON
                #pragma multi_compile _ SOFTPARTICLES_ON

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                half4 _Color;
                half _Speed;
                half4 _TintColor;
                half _AlphaLightSpeed;
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
                    float3 wordpos : TEXCOORD3;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };


                float4 _MainTex_ST;

                v2f vert(appdata_t v)
                {
                    v2f o;
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, o);

                    float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                    o.vertex = TransformWorldToHClip(positionWS);
                    #ifdef SOFTPARTICLES_ON
                    o.projPos = ComputeScreenPos (o.vertex);
                   o.projPos.z = -TransformWorldToView(positionWS).z;
                    #endif
                    o.wordpos = positionWS;
                    o.color = v.color;
                    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                    o.fogFactor = ComputeFogFactor(o.vertex.z);
                    return o;
                }

                float _InvFade;

                half4 frag(v2f i) : SV_Target
                {
                    UNITY_SETUP_INSTANCE_ID(i);

                    #ifdef SOFTPARTICLES_ON
                    float sceneZ = LinearEyeDepth(SampleSceneDepth( i.projPos.xy / i.projPos.w),_ZBufferParams);
                    float partZ = i.projPos.z;
                    float fade = saturate (_InvFade * (sceneZ-partZ));
                    i.color.a *= fade;
                    #endif


                    half time = (sin(_Time.y * _Speed + i.wordpos.x) * 0.5 + 0.5);
                    half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                    #ifdef ALPHALIGHT_ON
                    half Alphatime = (sin(_Time.y * _AlphaLightSpeed));
                    half pd = step(0, Alphatime) * 0.5 + 0.5; //pd 1或非1;
                    pd = tex.a > 0 && (pd == tex.a || pd != 1 && tex.a != 1) ? 1 : 0;
                    return half4(tex.rgb + pd * tex.rgb, 1) * i.color * _TintColor;
                    #endif

                    half4 col = i.color * _TintColor * tex;
                    col = lerp(_Color, col, time);
                    col.a = saturate(col.a);
                    // alpha should not have double-brightness applied to it, but we can't fix that legacy behaior without breaking everyone's effects, so instead clamp the output to get sensible HDR behavior (case 967476)
                    col.a *= _AlphaScale;

                    col.rgb = MixFog(col.rgb, i.fogFactor);
                    return col;
                }
                ENDHLSL
            }
        }
    }
}