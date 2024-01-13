Shader "MC/Scene/LightBridge"
{
    Properties
    {
        _MainTex("主贴图", 2D) = "black" {}
        [HDR]_MainTexColor("主贴图颜色", Color) = (1,1,1,1)
        _MainTexFlow ("主贴图流动速度(u v 两个方向)", Vector) = (0,0.2,0,0)

        _Layer1Tex("Layer1", 2D) = "black" {}
        [HDR]_Layer1Color("Layer1颜色", Color) = (1,1,1,1)
        _Layer1Flow ("噪声流动速度(u v 两个方向)", Vector) = (0,0.2,0,0)
        _Layer2Tex ("Layer2", 2D) = "black" {}
        [HDR]_Layer2Color("Layer1颜色", Color) = (1,1,1,1)
        _Layer2Flow ("噪声流动速度(u v 两个方向)", Vector) = (0,0.2,0,0)
        _Layer3Tex ("Layer3", 2D) = "black" {}
        [HDR]_Layer3Color("Layer1颜色", Color) = (1,1,1,1)
        _Layer3Flow ("噪声流动速度(u v 两个方向)", Vector) = (0,0.2,0,0)
        // _Layer4Tex ("Layer4", 2D) = "black" {}
        [NoScaleOffset]_MaskTex ("遮罩", 2D) = "white" {}
        _NoiseTex ("噪声", 2D) = "black" {}
        _NoiseIntensity ("噪声强度", Range(0,0.1)) = 0.01
        _NoiseFlow ("噪声流动速度(u v 两个方向)", Vector) = (0,0.2,0,0)
        [Toggle(_MUL_NOISE_ON)] _NoiseMulToggle ("是否应用噪声遮罩", float) = 0
        // [HDR]_Color ("颜色", Color) = (1,1,1,1)
        _GradientPercent ("渐变进度", Range(-0.2,1)) = 1
        _GradientWidth ("渐变宽度", Range(0.001,0.2)) = 0.1
        [HDR]_GradientFadeColor("渐变头部颜色", Color) = (1,1,1,1)
        // _GradientIntensity ("渐变亮度", Range(0,2)) = 1
        // [PowerSlider(2)]_DiffusePower ("DiffusePower", Range(0.25,4)) = 1
        // _Lerp ("Lerp", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"
        }
        LOD 100
        // Blend OneMinusDstColor One
        ZWrite Off
        Cull back

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            // Blend One One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma shader_feature_local _MUL_NOISE_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // origin 
                float4 uv0 : TEXCOORD0;

                // UBPA_FOG_COORDS(3)
                // UNITY_FOG_COORDS(3)
                half fogFactor : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex;
            half4 _MainTex_ST;
            half2 _MainTexFlow;

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            half4 _MainTexColor;

            half _GradientPercent;
            half _GradientWidth;
            half _GradientIntensity;

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                float t = fmod(_Time.x, 100.0);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv0.xy = v.uv;
                o.uv0.zw = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv0.zw += t * float2(_MainTexFlow);

                // UBPA_TRANSFER_FOG(o, v.vertex);
                // UNITY_TRANSFER_FOG(o, o.vertex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                float q = tex2D(_NoiseTex, i.uv0.zw).r;;
                // float3 mainCol = tex2D(_MainTex,i.uv0.zw).rgb * _MainTexColor.rgb;
                float4 mainCol = tex2D(_MainTex, i.uv0.zw) * _MainTexColor;

                float fade = smoothstep(_GradientPercent + _GradientWidth, _GradientPercent, i.uv0.y);
                half4 col = mainCol * fade;

                #ifdef _MUL_NOISE_ON
                col.rgb *= q.x;
                #endif
                // UBPA_APPLY_FOG_COLOR(i.fogCoord, col, half4(0,0,0,0));
                // UNITY_APPLY_FOG_COLOR(i.fogCoord, col, half4(0, 0, 0, 0));
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }


        Pass
        {
            // Tags { "LightMode" = "ForwardBase" }
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma shader_feature_local _MUL_NOISE_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // origin & noise
                float4 uv0 : TEXCOORD0;
                // layer1 & 2
                float4 uv1 : TEXCOORD1;
                // layer1 & 2
                float4 uv2 : TEXCOORD2;
                // UBPA_FOG_COORDS(3)
                // UNITY_FOG_COORDS(3)
                half fogFactor : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex;
            half4 _MainTex_ST;
            half2 _MainTexFlow;

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            half _NoiseIntensity;
            half2 _NoiseFlow;
            sampler2D _Layer1Tex;
            float4 _Layer1Tex_ST;
            half2 _Layer1Flow;
            sampler2D _Layer2Tex;
            float4 _Layer2Tex_ST;
            half2 _Layer2Flow;
            sampler2D _Layer3Tex;
            float4 _Layer3Tex_ST;
            half2 _Layer3Flow;
            // sampler2D _Layer4Tex;
            // float4 _Layer4Tex_ST;
            sampler2D _MaskTex;
            // float4 _MaskTex_ST;

            half3 _MainTexColor;
            half3 _Layer1Color;
            half3 _Layer2Color;
            half3 _Layer3Color;

            half _GradientPercent;
            half _GradientWidth;
            half _GradientIntensity;
            half4 _GradientFadeColor;


            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                float t = fmod(_Time.x, 100.0);
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv0.xy = v.uv;
                o.uv0.zw = TRANSFORM_TEX(v.uv, _NoiseTex);

                o.uv1.xy = TRANSFORM_TEX(v.uv, _Layer1Tex);
                o.uv1.zw = TRANSFORM_TEX(v.uv, _Layer2Tex);
                o.uv1 += t * float4(_Layer1Flow, _Layer2Flow);

                o.uv2.xy = TRANSFORM_TEX(v.uv, _Layer3Tex) + t * _Layer3Flow;
                o.uv2.zw = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 += t * float4(_Layer3Flow, _MainTexFlow);
                // o.uv2.zw = TRANSFORM_TEX(v.uv, _Layer4Tex);
                // o.uv2 += float4(0,t,0,t);
                // UBPA_TRANSFER_FOG(o, v.vertex);
                // UNITY_TRANSFER_FOG(o, o.vertex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                return o;
            }

            inline bool Edge(in float2 edgeUV, in float percent)
            {
                return (edgeUV.x > (0.5 - percent * 0.5)) || (edgeUV.y > (0.5 - percent * 0.5));
            }

            half4 frag(v2f i) : SV_Target
            {
                float t = fmod(_Time.y, 100.0);
                float2 q = 0;
                q.x = tex2D(_NoiseTex, i.uv0.zw).r;
                q.y = tex2D(_NoiseTex, i.uv0.zw + float2(0.37, 0.59)).r;
                float p = tex2D(_NoiseTex, i.uv0.zw + q + float2(1.7, 9.2) + t * float2(_NoiseFlow.xy)).r;
                half3 mask = tex2D(_MaskTex, i.uv0.xy).rgb;
                // float3 mainCol = tex2D(_MainTex,i.uv2.zw).rgb * _MainTexColor.rgb;
                float3 layer1 = tex2D(_Layer1Tex, i.uv1.xy + _NoiseIntensity * p).rgb * _Layer1Color.rgb;
                float3 layer2 = tex2D(_Layer2Tex, i.uv1.zw + _NoiseIntensity * p).rgb * _Layer2Color.rgb;
                float3 layer3 = tex2D(_Layer3Tex, i.uv2.xy + _NoiseIntensity * p).rgb * _Layer3Color.rgb;
                // float layer4 = tex2D(_Layer4Tex,i.uv.xy + _NoiseIntensity*p*float2(-0.2,-0.8)).r;

                float fade = smoothstep(_GradientPercent + _GradientWidth, _GradientPercent, i.uv0.y);
                //获取中间虚化的部分
                float fade2 = smoothstep(_GradientPercent, _GradientPercent + _GradientWidth, i.uv0.y);
                float GradienFade = fade * fade2;
                //取到进度虚化的部分
                // float a = 2 / _GradientWidth;
                // float w = _GradientWidth / 2;
                // float fade = saturate(1 - a*a * (i.uv0.y-_GradientPercent-w)*(i.uv0.y-_GradientPercent-w));
                // fade1 += fade1;
                // float fade1= i.uv0.y < _GradientPercent;

                half4 col = half4((layer1 * mask.r + layer2 * mask.g + layer3 * mask.b) * fade, 1);
                col.rgb += col.rgb * _GradientFadeColor.rgb * GradienFade;

                #ifdef _MUL_NOISE_ON
                col.rgb *= q.x;
                #endif
                // UBPA_APPLY_FOG_COLOR(i.fogCoord, col, half4(0,0,0,0));
                // UNITY_APPLY_FOG_COLOR(i.fogCoord, col, half4(0,0,0,0));
                col.rgb = MixFog(col.rgb, i.fogFactor);
                return col;
            }
            ENDHLSL
        }
    }
}