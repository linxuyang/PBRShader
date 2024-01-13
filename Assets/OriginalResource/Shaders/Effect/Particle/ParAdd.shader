Shader "MC/Effect/ParticleAdditive"
{
    Properties
    {
        [HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("Particle Texture", 2D) = "white" {}

        [Space]
        [Toggle(SOFTPARTICLES_ON)]_SoftParticlesEnabled ("软粒子开关", Float) = 0.0
        _InvFade ("软粒子深度系数", Range(0.01,3.0)) = 1.0

        [Space]
        [Toggle(UNITY_UI_CLIP_RECT)]_UnityUIClipRect ("开启UI遮罩", Float) = 0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }

    Category
    {
        Tags
        {
            "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        //透明底
        Blend SrcAlpha One,One OneMinusSrcAlpha //透明底
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

                #pragma shader_feature _ UNITY_UI_CLIP_RECT

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                half4 _TintColor;
                half _AlphaScale;
                float4 _ClipRect;
                float _UIMaskSoftnessX;
                float _UIMaskSoftnessY;

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
                    #ifdef UNITY_UI_CLIP_RECT
                half2 rectMask : TEXCOORD3;
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
				        o.projPos = ComputeScreenPos(o.vertex);
                        o.projPos.z = -TransformWorldToView(positionWS).z;
                    #endif
                    o.color = v.color;
                    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                    o.fogFactor = ComputeFogFactor(o.vertex.z);

                    #ifdef UNITY_UI_CLIP_RECT
				float4 screenPos = ComputeScreenPos(o.vertex);
                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                // 在屏幕空间计算当前顶点相对RectMask中心点的偏移Vector2(这里计算出来的结果是实际偏移的两倍, 后续的相关计算也同样都是两倍)
                o.rectMask = screenPos.xy / screenPos.w * _ScreenParams.xy * 2 - clampedRect.xy - clampedRect.zw;
                    #endif
                    return o;
                }

                float _InvFade;

                half4 frag(v2f i) : SV_Target
                {
                    half mask = 1;
                    #ifdef UNITY_UI_CLIP_RECT
                // 对接UI的RectMask2D遮罩，以下计算都是基于屏幕空间坐标系
                // 计算当前位置在XY轴上与裁剪边界的距离(在边界内为正数, 在边界外为负数, 计算得到的结果是实际数值的两倍)
                half2 rectMask = _ClipRect.zw - _ClipRect.xy - abs(i.rectMask);
                // 根据柔性遮罩的数值做过渡处理, 在边界内，距离边界越远则越不透明, 距离大于_UIMaskSoftness则不受影响
                rectMask /= half2(_UIMaskSoftnessX, _UIMaskSoftnessY);
                rectMask = saturate(rectMask);
                mask *= rectMask.x * rectMask.y;
                clip(mask - 0.001);
                    #endif

                    #ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth(SampleSceneDepth( i.projPos.xy / i.projPos.w),_ZBufferParams);
				float partZ = i.projPos.z;
				float fade = saturate (_InvFade * (sceneZ-partZ));
				i.color.a *= fade;
                    #endif

                    half4 col = 2.0f * i.color * _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                    col.a *= _AlphaScale * mask;
                    col.rgb = MixFog(col.rgb, i.fogFactor);
                    return col;
                }
                ENDHLSL
            }
        }
    }
}