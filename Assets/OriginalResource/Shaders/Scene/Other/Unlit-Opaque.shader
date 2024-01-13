// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "MC/Scene/Unlit-Opaque" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        [HDR]_TintColor ("Color", Color) = (0.5,0.5,0.5,0.5)

        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)] _EmissionToggle(":: 开启自发光", Float) = 0
        [NoScaleOffset] _EmissionTex ("自发光强度遮罩 (R通道)", 2D) = "white" {}
        [HDR]_EmissionColor ("自发光叠加色", Color) = (1,1,1,1)
        _EmissionPower ("自发光强度", Range(0, 2)) = 1

        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)] _ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha ("透明度", Range(0, 1)) = 1
        
        [HideInInspector]_SrcAlphaBlend ("__srcAlpha", Float) = 1.0
        [HideInInspector]_DstAlphaBlend ("__dstAlpha", Float) = 0.0
    }

    SubShader {
        Tags {"Queue"="Geometry" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector"="True" "RenderType"="Opaque"}
        LOD 100

        Cull back
        ZTest LEqual
        ZWrite On
        Blend One Zero,[_SrcAlphaBlend] [_DstAlphaBlend]

        Pass {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            
            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma multi_compile_local _ _SCREEN_DOOR_ON
            #pragma shader_feature_local _EMISSION_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                // UBPA_FOG_COORDS(1)
                half fogFactor : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
                #if _SCREEN_DOOR_ON
                    float4 screenPos : TEXCOORD2;
                #endif
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _TintColor;


            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                // UBPA_TRANSFER_FOG(o, v.vertex)
                // UNITY_TRANSFER_FOG(o,o.vertex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                #if _SCREEN_DOOR_ON
                    o.screenPos = ComputeScreenPos(o.vertex);
                #endif
                return o;
            }


            #if _EMISSION_ON
                sampler2D _EmissionTex;
                half _EmissionPower;
                half4 _EmissionColor;
         
                //自发光，底色纹理叠加自发光纹理，再叠加一些控制参数
                inline half3 Emission(half3 albedo, half2 uv)
                {
                    return tex2D(_EmissionTex, uv).r * albedo * _EmissionColor * _EmissionPower;
                }
            #endif

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.texcoord);
                col.rgb *= _TintColor.rgb * 2;

                 // 自发光
                #if _EMISSION_ON
                    col.rgb += Emission(col.rgb, i.texcoord);
                #endif

                // 透明模板
                #if _SCREEN_DOOR_ON
                    #if _SCREENDOORDEBUG_GRID
                        return applyScreenDoor(i.screenPos, col.a);
                    #else
                        applyScreenDoor(i.screenPos, col.a);
                    #endif
                #endif

                // UBPA_APPLY_FOG(i.fogCoord, col);
                // UNITY_APPLY_FOG(i.fogCoord, col);
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
//    Fallback "VertexLit"
}
