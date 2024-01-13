Shader "MC/Effect/FlipImageCutout"
{
    Properties
    {
        [NoScaleOffset]_TexA ("Texture A", 2D) = "white" {}
        [HDR]_ColorA ("Texture A - Color", Color) = (1, 1, 1, 1)
        _CutoutA ("Texture A - Alpha Cutout", Range(0, 1)) = 0
        [NoScaleOffset]_TexB ("Texture B", 2D) = "white" {}
        [HDR]_ColorB ("Texture B - Color", Color) = (1, 1, 1, 1)
        _CutoutB ("Texture B - Alpha Cutout", Range(0, 1)) = 0

        _Slices ("Slices", Range(1, 100)) = 10
        _Phase ("Phase", Range(-1, 1)) = 0 // 0:ImageA, 1:ImageB, 2:ImageC, 3:ImageA
        _PhaseWidth ("Phase Width", Range(0, 1)) = .2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" }
        Cull Off
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                half fogFactor : TEXCOORD1;
            };

            TEXTURE2D(_TexA);
            SAMPLER(sampler_TexA);
            half _CutoutA;
            half4 _ColorA;

            TEXTURE2D(_TexB);
            SAMPLER(sampler_TexB);
            half _CutoutB;
            half4 _ColorB;

            half _Slices; //[1,100]
            half _Phase; // [-1,1]
            half _PhaseWidth; // [0,1]

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.fogFactor = ComputeFogFactor(o.pos.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                bool flipAB = 1 - step(0, _Phase);
                _Phase = flipAB ? _Phase + 1 : _Phase;

                float pos = i.uv.x;
                float sliceWidth = 1.0/_Slices; // w
                float sliceID = trunc(pos/sliceWidth);
                float sliceMidpoint = sliceID * sliceWidth + .5 * sliceWidth;
                float startSliceID = _Phase * (1 + _PhaseWidth) - _PhaseWidth; // [-w,1]
                float endSliceID = _Phase * (1 + _PhaseWidth); // [0,1+w]
                float slicePhase = lerp(0, 1, saturate((sliceMidpoint - startSliceID) / _PhaseWidth));

                float offset = abs(pos - sliceMidpoint) * 2 / sliceWidth; // [0,1]
                float cutoutW = abs(cos(slicePhase * 3.1416)); // [0,1]
                clip(cutoutW - offset);
                i.uv.x = sliceMidpoint + (pos - sliceMidpoint) / cutoutW;

                half4 colA = SAMPLE_TEXTURE2D(_TexA,sampler_TexA,i.uv);
                half4 colB = SAMPLE_TEXTURE2D(_TexB,sampler_TexB,i.uv);
                bool isB = step(.5, slicePhase);

                isB = flipAB ? 1 - isB : isB;
                float alpha = isB ? colB.w * _ColorB.a : colA.w * _ColorA.a;
                float cutoutC = isB ? _CutoutB : _CutoutA;
                clip(alpha - cutoutC);

                half4 c = half4(0, 0, 0, 1);
                c.rgb = isB ? colB.rgb * _ColorB.rgb : colA.rgb * _ColorA.rgb;

                c.rgb = MixFog(c.rgb,i.fogFactor);
                return c;
            }
            ENDHLSL
        }
    }
}
