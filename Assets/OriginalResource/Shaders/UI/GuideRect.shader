Shader "MC/UI/GuideRect" {
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
        
        //设置圆心点和园半径
        _Center("Center",vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        Stencil 
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Default"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                half4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            half4 _Color;
            half4 _TextureSampleAdd;
            float4 _Center;

            v2f vert(appdata_t v)
            {

                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                // OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.vertex = TransformObjectToHClip(OUT.worldPosition.xyz);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            half4 frag(v2f IN) : SV_Target
            {
                half4 color = (SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.texcoord) + _TextureSampleAdd) * IN.color;
                //大于圆的半径则颜色显示正常，园园内透明
                // color.a *= (distance(IN.worldPosition.xy, _Center.xy) > _Slider);
                //计算矩形区域
                color.a *= (distance(IN.worldPosition.x, _Center.x) > _Center.z/2 || distance(IN.worldPosition.y, _Center.y) > _Center.w/2);
                color.rgb *= color.a;
                return color;
            }
        ENDHLSL
        }
    }
}
