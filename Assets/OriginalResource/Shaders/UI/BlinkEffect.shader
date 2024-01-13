Shader "MC/UI/BlinkEffect"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        _OffsetX("OffsetX", Float) = 0
        _OffsetY("OffsetY", Float) = 0
        _AlphaMultiplier("AlphaMultiplier", Float) = 1
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
        _ParamX("ParamX",Float) = 0.6
        _ParamY("ParamY",Float) = 0.3

    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //#pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP


            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            half4 _Color;
            float _OffsetX;
            float _OffsetY;
            float4 _MainTex_ST;
            half _AlphaMultiplier;
            half _ParamX;
            half _ParamY;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.worldPosition = v.vertex;
                // OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.vertex = TransformObjectToHClip(OUT.worldPosition.xyz);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex) - float2(_OffsetX, _OffsetY);
                OUT.color = v.color * _Color;
                return OUT;
            }

            half4 frag(v2f IN) : SV_Target
            {
                half4 color = IN.color;
                half x = IN.texcoord.x - 0.5;
                half y = IN.texcoord.y - 0.5;
                half oval = x * x / (_ParamX * _ParamX) + y * y / (_ParamY * _ParamY);
                oval = clamp(oval * _AlphaMultiplier, 0, 1);
                color.a = oval * color.a;
                #ifdef UNITY_UI_ALPHACLIP
		    clip (color.a - 0.001);
                #endif
                return color;
            }
            ENDHLSL
        }
    }
}