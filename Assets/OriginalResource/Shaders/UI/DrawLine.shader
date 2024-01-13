Shader "MC/UI/DrawLine"
{
    Properties
    {
        _Color("Center Color", Color) = (1, 1, 1, 1)
        _OutLineColor("Edge Color", Color) = (0, 0, 0, 1)
        _OutLineWidth("Edge Width", Range(0, 1)) = 0
        _FeatherPow("Feather Pow", Range(0, 20)) = 1

        [hideinInspector]_StencilComp ("Stencil Comparison", Float) = 8
        [hideinInspector]_Stencil ("Stencil ID", Float) = 0
        [hideinInspector]_StencilOp ("Stencil Operation", Float) = 0
        [hideinInspector]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [hideinInspector]_StencilReadMask ("Stencil Read Mask", Float) = 255
        [hideinInspector]_ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="true"
            "RenderType"="Transparent"
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
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                half2 texcoord : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            half4 _Color, _OutLineColor;
            half _OutLineWidth, _FeatherPow;

            v2f vert(appdata i)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(i.vertex.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            float4 frag(v2f i) : COLOR
            {
                half centerStep = 1 - abs(0.5 - i.texcoord.y) * 2;
                half fade = saturate(centerStep / _OutLineWidth);
                fade = pow(fade, _FeatherPow);
                centerStep = step(_OutLineWidth, centerStep);
                half4 color = lerp(_OutLineColor, _Color, centerStep);
                color.a *= fade;
                return color;
            }
            ENDHLSL
        }
    }
    Fallback "Sprites/Default"
}