Shader "MC/PostEffect/Weather/Rain"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("噪声", 2D) = "white" {}
        _Color ("雨水颜色", COLOR) = ( .34, .85, .92, 1)
        _RainFar("雨面距离", Range(1,10)) = 5
        _RainLength ("雨丝长度", Range(0.01,2)) = 1
        _RainWidth ("雨丝宽度", Range(0.1,2)) = 1
        _RainSpeed ("雨速", Range(0,1.5)) = 1
        _RainDensity ("雨丝密度", Range(0,1.5)) = 1
        _Rotate("旋转角度", Range(-45,45)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // // #pragma multi_compile _ UBPA_FOG_ENABLE
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 ruv : TEXCOORD2;
            };

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            float4 _NoiseTex_ST;
            half4 _Color;
            half _RainLength;
            half _RainSpeed;
            half _RainDensity;
            half _RainFar;
            half _RainWidth;
            float _Rotate;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.ruv = o.uv;
                o.uv = (o.uv * 2.0 - 1.0) *  float2(_ScreenParams.x/_ScreenParams.y,1.0);
                float theta = _Rotate * PI / 180;
                o.uv = float2(cos(theta)*o.uv.x-sin(theta)*o.uv.y,sin(theta)*o.uv.x+cos(theta)*o.uv.y) ;
                o.uv = o.uv * _RainFar * float2(2 / _RainWidth, .03 / _RainLength)+float2(0, _Time.y*.2)*_RainSpeed;
                // UBPA_TRANSFER_FOG(o, v.vertex)
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // return half4(i.uv.x,i.uv.y,0,1);
                float2 st =  i.uv;
                //拉伸实现
				float f = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,st).y * SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,st).x * 1.55 * (_RainDensity *0.25+0.6);
                // return tex2D(_NoiseTex, st);
                f = clamp( 0.0, pow(abs(f), 23.0) * 13.0,(i.ruv.y-.1)*.14);
                clip(f-0.001);
                // UBPA_APPLY_FOG(i.fogCoord, col);
                return half4(_Color.rgb,_Color.a* saturate(f*4));
            }
            ENDHLSL
        }
    }
}
