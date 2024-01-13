Shader "MC/Scene/Diffuse_Flow_Emission"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色", Color) = (1,1,1,1)
        _MainTex ("固有色贴图 (RGBA)", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("剔除模式", Float) = 2

        [Space]
        [Header(Emission)]
        [NoScaleOffset] _EmissionTex ("自发光遮罩 (R强度 G流向)", 2D) = "white" {}
        [HDR]_EmissionColor ("自发光叠加色", Color) = (1,1,1,1)
        _EmissionPower ("自发光强度", Range(0, 2)) = 1
        [Toggle(_FLOW_EMISSION_ON)] _FlowEmissionToggle("开启流动自发光",float) = 0
        _FlowSpeed("流动方向", vector) = (1,0,0,0)
        _FlowScale("噪声尺寸", Range(0.01,1)) = 1

        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)] _ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha ("透明度", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "MainPass"
            Tags { "LightMode"="UniversalForward" }
            Cull [_Cull]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _FLOW_EMISSION_ON

            #pragma multi_compile_local _ _SCREEN_DOOR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../SceneCommonUtil.hlsl"
            #include "../../CommonInclude.hlsl"
            
            sampler2D _MainTex;
            sampler2D _EmissionTex;
            half3 _LightningColor;// 打雷

            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half4 _Color;
            half3 _EmissionColor;
            half _EmissionPower;
            half2 _FlowSpeed;
            half _FlowScale;
            half _ScreenDoorAlpha; //点阵透明度
            CBUFFER_END

            //自发光，底色纹理叠加自发光纹理，再叠加一些控制参数
            inline half3 Emission(half3 albedo, half2 uv)
            {
                half mask = tex2D(_EmissionTex, uv).r;
                half3 emission = _EmissionColor * _EmissionPower * mask;
            #ifdef _FLOW_EMISSION_ON
                half noise = tex2D(_EmissionTex, (_Time.y * _FlowSpeed.xy + uv * _FlowScale)).g;
                noise = Pow5(noise) * 5;
                // 不乘固有色，方便做出各种颜色的自发光
                emission *= noise;
            #else
                emission *= albedo;
            #endif
                return emission;
            }

            struct appdata_main
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                half4 color : COLOR;
                half2 uv : TEXCOORD0;
            };

            struct v2f_main
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                half4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half fogCoord : TEXCOORD1;
                half2 uv_emission:TEXCOORD2;
            };

            v2f_main vert (appdata_main v)
            {
                v2f_main o = (v2f_main)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv_emission = v.uv;
                o.fogCoord = ComputeFogFactor(o.pos.z);
                return o;
            }
            
            half4 frag (v2f_main i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
            #if _SCREEN_DOOR_ON
                half2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.pos);
                ScreenDitherClip(normalizedScreenSpaceUV, _ScreenDoorAlpha);
            #endif

                // 取出固有色
                half4 baseColor = tex2D(_MainTex, i.uv.xy) * _Color;
                half4 col = baseColor;
               
                col.rgb += Emission(baseColor.rgb, i.uv_emission);
                col.rgb = MixFog(col.rgb, i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}
