Shader "MC/Effect/ParticleAdditiveHdrEx"
{
    Properties
    {
        [Header(Base)]
        [HDR]_TintColor ("Color", Color) = (.5,.5,.5,.5)
        _MainTex ("Texture(RGBA) 主纹理", 2D) = "white" {}
        _AlphaCut("Alpha Cutout", Range(0, 1)) = 0
        [Header(UV Animation)]
        _SpeedX("Speed X 主纹理UV移动速度", float) = 0
        _SpeedY("Speed Y 主纹理UV移动速度", float) = 0
        [Space(10)]
        [Header(Noise)]
        [ToggleOff(_NOISE_OFF)]_NoiseToggle("Use Noise 使用噪波", float) = 0
        _NoiseTex("Noise(RGBA) 噪波纹理", 2D) = "black"{}
        _NoisePower("Noise Power 噪波强度", Range(0, 2)) = 0
        _NoiseSpeedX("Speed X 噪波UV移动速度", float) = 0
        _NoiseSpeedY("Speed Y 噪波UV移动速度", float) = 0
        [Header(Noise Influence)]
        [ToggleOff(_NOISECHANNEL_RGB_OFF)]_NoiseChannelRGBToggle("Noise On RGB 噪波影响RGB通道", float) = 1
        [KeywordEnum(Multiply, Additive, Subtractive)]_NoiseRGBFunc("Noise Function On RGB 噪波叠加方式", float) = 0
        [ToggleOff(_NOISECHANNEL_ALPHA_OFF)]_NoiseChannelAToggle("Noise On Alpha 噪波影响A通道", float) = 0
        [KeywordEnum(Multiply, Additive, Subtractive, Set)]_NoiseAFunc("Noise Function On Alpha 噪波叠加方式", float) = 0
        [Header(Noise UV Shift)]
        [ToggleOff(_NOISECHANNEL_UV_OFF)]_NoiseChannelUVToggle("Noise On UV 噪波使纹理UV偏移", float) = 0
        _UV_X("UV U轴最大偏移(对应噪波最大值)", Range(-1, 1)) = 0
        _UV_Y("UV V轴最大偏移(对应噪波最大值)", Range(-1, 1)) = 0
        [Header(Noise Vertex Extrude)]
        [ToggleOff(_NOISECHANNEL_EXTRUDE_OFF)]_NoiseChannelVertexExtrToggle("Noise On Vertex 噪波使顶点延法线挤出", float) = 0
        _ExtrudeScale("Extrude Scale 最大顶点挤出幅度(对应噪波最大值)", Float) = 0
        [KeywordEnum(Disable, Main Texture Alpha, Mask Texture Red)]_NoiseChannelVertexExtrMask("Vertex Extrude Mask 顶点挤出的遮罩", float) = 0
        [NoScaleOffset]_ExtrudeMaskTex ("Extrude Mask(R) 顶点挤出幅度遮罩", 2D) = "white" {}
        [Space(20)]
        [Toggle(SOFTPARTICLES_ON)]_SoftParticlesEnabled ("软粒子开关", Float) = 0.0
        _InvFade ("Soft Particles Factor 软例子系数", Range(0.01,3.0)) = 1.0
        [Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("SrcBlend 源混合方式", float) = 5 // SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("DstBlend 目标混合方式", float) = 1 // One
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 0 //"Off"
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 0 //"Off"
        [Space(20)]
        [KeywordEnum(Disable, Noise)]_Debug("Debug 调试模式", float) = 0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest On
        Lighting Off // no lighting
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma multi_compile_particles
            #pragma multi_compile_instancing
            #pragma shader_feature_local _NOISE_OFF
            #pragma shader_feature_local _NOISECHANNEL_RGB_OFF _NOISERGBFUNC_MULTIPLY _NOISERGBFUNC_ADDITIVE _NOISERGBFUNC_SUBTRACTIVE
            #pragma shader_feature_local _NOISECHANNEL_ALPHA_OFF _NOISEAFUNC_MULTIPLY _NOISEAFUNC_ADDITIVE _NOISEAFUNC_SUBTRACTIVE _NOISEAFUNC_SET
            #pragma shader_feature_local _NOISECHANNEL_UV_OFF
            #pragma shader_feature_local _NOISECHANNEL_EXTRUDE_OFF
            #pragma shader_feature_local _NOISECHANNELVERTEXEXTRMASK_DISABLE _NOISECHANNELVERTEXEXTRMASK_MAIN_TEXTURE_ALPHA _NOISECHANNELVERTEXEXTRMASK_MASK_TEXTURE_RED
            #pragma multi_compile _ SOFTPARTICLES_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            half4 _TintColor;
            float _AlphaCut;
            half _SpeedX;
            half _SpeedY;
            float _InvFade;
            half _AlphaScale;
            #ifndef _NOISE_OFF
                TEXTURE2D(_NoiseTex);
                SAMPLER(sampler_NoiseTex);
                float4 _NoiseTex_ST;
                half _NoisePower;
                half _NoiseSpeedX;
                half _NoiseSpeedY;
            #ifndef _NOISECHANNEL_UV_OFF
                    float _UV_X;
                    float _UV_Y;
            #endif
            #ifndef _NOISECHANNEL_EXTRUDE_OFF
                    half _ExtrudeScale;
            #if _NOISECHANNELVERTEXEXTRMASK_MASK_TEXTURE_RED
                        TEXTURE2D(_ExtrudeMaskTex);
                        SAMPLER(sampler_ExtrudeMaskTex);
            #endif
            #endif
            #endif

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_INSTANCING_BUFFER_END(Props)


            struct appdata_t
            {
                float4 vertex : POSITION;
                half4 color : COLOR;
                float4 uv0 : TEXCOORD0;
                #ifndef _NOISECHANNEL_EXTRUDE_OFF
                    float3 normal : NORMAL;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half4 color : COLOR;
                #ifndef _NOISE_OFF
                    float4 uv : TEXCOORD0;
                #else
                float2 uv : TEXCOORD0;
                #endif
                half fogFactor : TEXCOORD1;
                #ifdef SOFTPARTICLES_ON
                    float4 projPos : TEXCOORD2;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifndef _NOISE_OFF
            #ifndef _NOISECHANNEL_UV_OFF
                    void uv_shift2(inout float2 uv, float noise)
                    {
                        noise = noise * 2 - 1; // [-1, 1]
                        uv.x += _UV_X * noise;
                        uv.y += _UV_Y * noise;
                    }
                    void uv_shift(inout float2 uv, float2 noise_uv)
                    {
                        half3 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex,noise_uv) * _NoisePower;
                        uv_shift2(uv, noise.r);
                    }
            #endif
            #endif

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.color = v.color;
                o.uv.xy = TRANSFORM_TEX(v.uv0.xy, _MainTex);
                o.uv.x += _Time.y * _SpeedX * .1;
                o.uv.y += _Time.y * _SpeedY * .1;
                #ifndef _NOISE_OFF
                    o.uv.zw = TRANSFORM_TEX(v.uv0.xy, _NoiseTex);
                    o.uv.z += _Time.y * _NoiseSpeedX * .1;
                    o.uv.w += _Time.y * _NoiseSpeedY * .1;
                #ifndef _NOISECHANNEL_EXTRUDE_OFF
                        float3 noise = SAMPLE_TEXTURE2D_LOD(_NoiseTex,sampler_NoiseTex,o.uv.zw,0)* _NoisePower;
                        float2 main_uv = o.uv.xy;
                #if _NOISECHANNELVERTEXEXTRMASK_MAIN_TEXTURE_ALPHA
                #ifndef _NOISECHANNEL_UV_OFF
                                uv_shift2(main_uv, noise.r);
                #endif
                            float noise_mask = SAMPLE_TEXTURE2D_LOD(_MainTex,sampler_MainTex,main_uv,0).a;
                #elif _NOISECHANNELVERTEXEXTRMASK_MASK_TEXTURE_RED
                            float noise_mask =SAMPLE_TEXTURE2D_LOD(_ExtrudeMaskTex,sampler_ExtrudeMaskTex,main_uv,0).r;
                #elif _NOISECHANNELVERTEXEXTRMASK_DISABLE
                            float noise_mask = 1;
                #endif
                        v.vertex.xyz += noise_mask * normalize(v.normal) * _ExtrudeScale * noise.r;
                #endif
                #endif
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(positionWS);
                #ifdef SOFTPARTICLES_ON
                    o.projPos = ComputeScreenPos (o.pos);
                    o.projPos.z = -TransformWorldToView(positionWS).z;
                #endif

                o.fogFactor = ComputeFogFactor(o.pos.z);
                return o;
            }

            #ifndef _NOISE_OFF
                void frag_noise(inout half4 col, float2 noise_uv)
                {
                    half3 noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex, noise_uv) * _NoisePower;
            #if _DEBUG_NOISE
                        col.rgb = noise;
            #else
            #ifndef _NOISECHANNEL_RGB_OFF
            #if _NOISERGBFUNC_MULTIPLY
                                col.rgb *= noise;
            #elif _NOISERGBFUNC_ADDITIVE
                                col.rgb += noise;
            #elif _NOISERGBFUNC_SUBTRACTIVE
                                col.rgb -= noise;
                                col.rgb = max(0, col.rgb);
            #endif
            #endif
            #ifndef _NOISECHANNEL_ALPHA_OFF
            #if _NOISEAFUNC_MULTIPLY
                                col.a *= noise.r;
            #elif _NOISEAFUNC_ADDITIVE
                                col.a += noise.r;
            #elif _NOISEAFUNC_SUBTRACTIVE
                                col.a -= noise.r;
                                col.a = max(0, col.a);
            #elif _NOISEAFUNC_SET
                                col.a = noise.r;
            #endif
            #endif
            #endif
                    return;
                }
            #endif

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i)

                #ifdef SOFTPARTICLES_ON
                    float sceneZ = LinearEyeDepth(SampleSceneDepth( i.projPos.xy / i.projPos.w),_ZBufferParams);
                    float partZ = i.projPos.z;
                    float fade = saturate(_InvFade * (sceneZ-partZ));
                #endif

                #ifndef _NOISE_OFF
                #ifndef _NOISECHANNEL_UV_OFF
                    uv_shift(i.uv.xy, i.uv.zw);
                #endif
                #endif

                half4 col = 2.0f * i.color * _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                col.a = saturate(col.a);
                // alpha should not have double-brightness applied to it, but we can't fix that legacy behaior without breaking everyone's effects, so instead clamp the output to get sensible HDR behavior (case 967476)
                #ifndef _NOISE_OFF
                    frag_noise(col, i.uv.zw);
                #endif
                clip(col.a - _AlphaCut);

                #ifdef SOFTPARTICLES_ON
                    col.a *= fade;
                #endif
                col.a *= _AlphaScale;
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}