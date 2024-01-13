// 色散后处理
Shader "MC/PostEffect/Dispersion"
{
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../CommonUtil.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 原始图像
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            // 色散强度
            half _Intensity;
            // 色散模式
            half _DispersionMode;
            // 色散焦点
            half2 _Center;
            // 色散方向
            half2 _Duration;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
                o.uv = TransformTriangleVertexToUV(v.vertex.xy);
                #if UNITY_UV_STARTS_AT_TOP
                o.uv.y = o.uv.y * -1 + 1;
                #endif
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                // 计算从色散焦点到该点的向量
                half2 centerToUV = uv - _Center;
                // 根据色散模式得出最终的色散方向(即UV偏移方向)
                half2 uvOffset = lerp(_Duration, centerToUV, _DispersionMode);
                uvOffset = normalize(uvOffset);
                // 根据色散模式得出最终的色散强度
                half intensity = lerp(1, length(centerToUV) * 2, _DispersionMode);
                intensity *= _Intensity;
                // G、B通道的UV分别以0.5倍和1倍的强度偏移，R通道不偏移(因为红绿蓝光的折射率依次增大)
                half R = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).r;
                half G = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv-uvOffset*0.5*intensity).g;
                half B = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv-uvOffset*intensity).b;
                // 将分离的颜色通道再合并输出
                half4 color = half4(R, G, B, 1);
                return color;
            }
            ENDHLSL
        }
    }
}