Shader "MC/Scene/Transparent"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色", Color) = (1,1,1,1)
        _MainTex ("固有色贴图 (RGBA)", 2D) = "white" {}
        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)] _ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha ("透明度", Range(0, 1)) = 1
        // [KeywordEnum(None, Grid)] _ScreenDoorDebug("调试透明度模板", Float) = 0
    }
    SubShader
    {

        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            // Tags {"LightMode"="ForwardBase"}
            Name "Transparent"
            Cull back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ _SCREEN_DOOR_ON


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                // UBPA_FOG_COORDS(1)
                // UNITY_FOG_COORDS(1)
                half fogFactor : TEXCOORD1;
                SCREENDOOR_COORDS(2)
            };

            sampler2D _MainTex;
            half4 _MainTex_ST;
            half4 _Color;

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                // UBPA_TRANSFER_FOG(o, v.vertex)
                // UNITY_TRANSFER_FOG(o, o.pos);
                o.fogFactor = ComputeFogFactor(o.pos.z);
                #if _SCREEN_DOOR_ON
                TRANSFER_SCREENDOOR(o,o.pos);
                #endif
                return o;
            }

            half4 frag(v2f i): SV_Target
            {
                half4 color = tex2D(_MainTex, i.uv);
                color *= _Color;

                // UBPA_APPLY_FOG(i.fogCoord, color);
                // UNITY_APPLY_FOG(i.fogCoord, color);
                color.rgb = MixFog(color.rgb, i.fogFactor);
                #if _SCREEN_DOOR_ON
                APPLY_SCREENDOOR(i,color.a)
                #endif
                return color;
            }
            ENDHLSL
        }

    }
}