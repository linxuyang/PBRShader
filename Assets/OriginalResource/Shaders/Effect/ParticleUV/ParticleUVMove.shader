Shader "MC/Effect/ParticleUVMove"
{
    Properties
    {
        _Offset_Z("Z Offset-深度偏移", Float) = 0
        [HDR]_MainColor("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" {}
        _MainSpeed_U("U Speed", Float) = 0
        _MainSpeed_V("V Speed", Float) = 0
        [Space]
        [Header(Blend Mode)]
        [Enum(Off, 0, Front, 1, Back, 2)]_Cull("Cull Mode-裁剪模式", Float) = 2
        [Enum(One, 1, SrcAlpha, 5)] _ColorSrc("Src Blend-目标混合系数", Float) = 5
        [Enum(One, 1, OneMinusSrcAlpha, 10)] _ColorDst("Dst Blend-背景混合系数", Float) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent"
        }

        Cull [_Cull]
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Blend[_ColorSrc][_ColorDst]
            
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half4 color : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half _Offset_Z;
            half _MainSpeed_U;
            half _MainSpeed_V;
            half4 _MainColor;

            v2f vert(appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                // 在(顶点->摄像机)方向做偏移
                float3 offsetVector = normalize(GetCameraPositionWS() - worldPos);
                worldPos += offsetVector * _Offset_Z;
                // 顶点坐标从世界空间转换到裁剪空间
                o.vertex = TransformWorldToHClip(worldPos.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                half2 mainTexUV = i.uv + _Time.y * half2(_MainSpeed_U, _MainSpeed_V);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,mainTexUV);
                col *= _MainColor * i.color;
                return col;
            }
            ENDHLSL
        }
    }
}
