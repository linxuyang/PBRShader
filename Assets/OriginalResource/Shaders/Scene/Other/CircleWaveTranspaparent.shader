Shader "MC/Scene/CircleWaveTransparent"
{
    Properties
    {
        _Tex1("贴图1", 2D) = "white" {}
        [HDR]_TintColor1("叠加颜色1", Color) = (0.17066,0.5566,0.54808,0.4117647)
        _Tex2("贴图2", 2D) = "white" {}
        [HDR]_TintColor2("叠加颜色2", Color) = (0.385,1,0.49473,1)
        _UVSpeed("UV速度", Vector) = (0.2,0.1,0.05,0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }
            Blend SrcAlpha One
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                // UBPA_FOG_COORDS(1)
                // UNITY_FOG_COORDS(1)
                half fogFactor : TEXCOORD1; 
                float4 vertex : SV_POSITION;
            };

            sampler2D _Tex1;
            half4 _Tex1_ST;
            sampler2D _Tex2;
            half4 _Tex2_ST;
            half4 _TintColor1;
            half4 _TintColor2;
            half4 _UVSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _Tex1) + _Time.x * _UVSpeed.xy;
                o.uv.zw = TRANSFORM_TEX(v.uv, _Tex2) + _Time.x * _UVSpeed.zw;
                
                // UBPA_TRANSFER_FOG(o, v.vertex)
                // UNITY_TRANSFER_FOG(o,o.vertex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col1 = tex2D(_Tex1, i.uv.xy) * _TintColor1;
                half4 col2 = tex2D(_Tex2, i.uv.zw) * _TintColor2;
                
                half4 col = col1 * col2 * 2;
                // apply fog
                // UBPA_APPLY_FOG(i.fogCoord, col);
                // UNITY_APPLY_FOG(i.fogCoord, col);
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}
