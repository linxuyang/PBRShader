Shader "MC/SimpleFoam"
{
    Properties
    {
        _MainTex("水沫纹理", 2D) = "white" {}
        _Color("水沫颜色", Color) = (1, 1, 1, 1)
        _Width("宽度", Range(0, 1)) = 0.5
        _EdgeSmooth("边缘柔和", Range(0.01, 0.1)) = 0.05
        _Noise("噪声", 2D) = "gray" {}
        _OffsetNoiseStrength("偏移噪声强度", Range(0, 1)) = 0.5
        _WidthNoiseStrength("宽度噪声强度", Range(0, 1)) = 0.5
        _Speed("移动速度", Range(0, 5)) = 1
        _FadeTiming("消隐时机", Range(0, 6.28)) = 4
        _FadeSmooth("渐隐程度", Range(0.1, 1.5)) = 0.5
        _LandSideSmooth("近岸过渡", Range(0, 0.3)) = 0.1
        _LandSideSmoothRange("近岸过渡距离", Range(0, 0.3)) = 0.1
        _SeaSideSmooth("远岸过渡", Range(0, 0.3)) = 0.1
        _DistortTex("扭曲噪声", 2D) = "gray" {}
        _DistortStrength("扭曲强度", Range(0, 1)) = 0.5
        _TimeOffset("时间间隔", Range(0, 3.14)) = 1.5
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        Offset -1, -1
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            half4 _MainTex_ST;
            half4 _Color;
            half _Width, _EdgeSmooth;
            sampler2D _Noise;
            half4 _Noise_ST;
            half _WidthNoiseStrength, _OffsetNoiseStrength;
            half _Speed, _FadeTiming, _FadeSmooth;
            half _LandSideSmooth, _LandSideSmoothRange, _SeaSideSmooth;
            sampler2D _DistortTex;
            half4 _DistortTex_ST;
            half _DistortStrength;
            half _TimeOffset;

            half SimpleFoam(half2 uv, half2 noiseUV, half2 distortUV, half time)
            {
                half3 distort = tex2D(_DistortTex, distortUV).rgb;
                distort = (distort - 0.5) * distort.z * _DistortStrength;
                uv += distort.xy;

                noiseUV += distort;
                half noise = tex2D(_Noise, noiseUV).r;
                half width = _Width * (1 - (0.5 - noise) * _WidthNoiseStrength);
                noise = tex2D(_Noise, noiseUV + half2(0, 0.2)).r;
                half offset = (noise - 0.5) * _OffsetNoiseStrength;

                half move = 0.5 * (sin(time) + 1); // 0 ~ 1
                move = lerp(-1, 1 - width, move); // -1 ~ 1 - width

                half fade = (time + HALF_PI) % TWO_PI;
                fade = smoothstep(_FadeTiming + _FadeSmooth, _FadeTiming, fade);
                
                half2 mainTexUV = uv;
                mainTexUV.y += offset - move;
                half foam = mainTexUV.y < width;
                mainTexUV.y = mainTexUV.y / width;
                foam *= smoothstep(0, _EdgeSmooth, mainTexUV.y) * smoothstep(1, 1 - _EdgeSmooth, mainTexUV.y);
                mainTexUV = mainTexUV * _MainTex_ST.xy + _MainTex_ST.zw;
                foam *= tex2D(_MainTex, mainTexUV).r;
                foam *= fade;
                return foam;
            }

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertexOuput
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                half4 noiseAndDistortUV : TEXCOORD1;
            };

            VertexOuput Vertex(VertexInput input)
            {
                VertexOuput o;
                o.positionCS = TransformObjectToHClip(input.positionOS);
                o.uv = input.uv;
                o.noiseAndDistortUV.xy = TRANSFORM_TEX(input.uv, _Noise);
                o.noiseAndDistortUV.zw = TRANSFORM_TEX(input.uv, _DistortTex);
                return o;
            }

            half4 Fragment(VertexOuput input) : SV_Target
            {
                half2 uv = input.uv;
                half2 noiseUV = half2(input.noiseAndDistortUV.x, 0.5);
                half2 distortUV = input.noiseAndDistortUV.zw;
                half time = _Time.y * _Speed;
                half foam = SimpleFoam(uv, noiseUV, distortUV, time);

                uv = input.uv + half2(0.5, 0);
                noiseUV += 0.5;
                distortUV += 0.5;
                time += _TimeOffset * _Speed;
                foam += SimpleFoam(uv, noiseUV, distortUV, time);
                
                foam *= smoothstep(0, _SeaSideSmooth, input.uv.y) * smoothstep(1 - _LandSideSmooth, 1 - _LandSideSmooth - _LandSideSmoothRange, input.uv.y);
                half4 color = half4(_Color.rgb, saturate(foam * _Color.a));
                return color;
            }
            ENDHLSL
        }
    }
}