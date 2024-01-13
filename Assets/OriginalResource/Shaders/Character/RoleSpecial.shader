Shader "MC/Character/Other/RoleSpecial"
{
    Properties
    {
        [HDR]_Color("叠加色 (RGBA)", Color) = (1, 1, 1, 1)
        _MainTex("固有色 (RGBA)", 2D) = "white" {}
        _MinRim("边缘柔和区间1", Range(0, 1)) = 0
        _MaxRim("边缘柔和区间2", Range(0, 1)) = 1
        [HDR]_RimColor("边缘颜色(RGB)", Color) = (0.5, 0.5, 0.5, 0.5)
        [HDR]_InnerColor("内部颜色(RGB)", Color) = (0.5, 0.5, 0.5, 0.5)
        _RimPower("边缘光衰减", Range(0.0, 5.0)) = 2.5
        _MinRimAlpha("最小透明度", Range(0, 1)) = 0
        _AlphaPower("透明度衰减", Range(0, 8)) = 4

        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色 (RGB)", Color) = (.5, .5, .5, 1)
        [NoScaleOffset]_EmissionTex("自发光遮罩R", 2D) = "white" {}
        _EmissionPower("强度", Range(0, 2)) = 0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }
    
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue"="Transparent"
        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back

        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            struct VertexInput
            {
                float3 positionOS : POSITION;
            };
            
            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
            };
            
            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
            
                output.positionCS = TransformObjectToHClip(input.positionOS);
                return output;
            }
            
            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
            ZWrite Off

            HLSLPROGRAM
            #pragma shader_feature_local _EMISSION_ON

            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            sampler2D _EmissionTex;

            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half4 _Color;
            half _MinRim, _MaxRim, _MinRimAlpha;

            half3 _RimColor;
            half _RimPower;
            half _AlphaPower;
            half3 _InnerColor;
            half _AlphaScale;

            half3 _EmissionColor;
            half _EmissionPower;
            CBUFFER_END

            half4 Emission(half2 uv)
            {
                // 采样自发光遮罩贴图的R通道来限制自发光的区域
                // 有自发光的区域，除了RGB通道外还要根据自发光强度叠加alpha，不然自发光会变透明
                half emissionMask = tex2D(_EmissionTex, uv).r;
                return half4(emissionMask * _EmissionColor * _EmissionPower, emissionMask * _EmissionPower);
            }

            struct VertexInput
            {
                float3 positionOS : POSITION;
                half3 normalOS: NORMAL;
                half2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS: TEXCOORD1;
                half4 viewDirWSAndFogFactor : TEXCOORD2;
                half2 uv : TEXCOORD3;
                
            };

            VertexOutput Vertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
                output.viewDirWSAndFogFactor.xyz = viewDirWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);

                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);

                output.viewDirWSAndFogFactor.w = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Fragment(VertexOutput input) : SV_Target
            {
                half4 col = tex2D(_MainTex, input.uv);
                col *= _Color;

                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWSAndFogFactor.xyz);
                // 根据法线与视线夹角计算边缘，并利用smoothstep将rim的变化区间限制在指定范围内
                half rim = smoothstep(_MinRim, _MaxRim, 1 - dot(normalWS, viewDirWS));
                // 使用rim的值调整物体透明度，_AlphaPower调整透明度衰减速度
                col.a *= lerp(_MinRimAlpha, 1, pow(rim, _AlphaPower));
                // 使用rim的值来混合边缘光颜色和内部光颜色，_RimPower调整边缘光衰减速度
                col.rgb += lerp(_InnerColor, _RimColor, pow(rim, _RimPower));

            #if _EMISSION_ON
                col += Emission(input.uv);
            #endif

                // 前面的计算有可能导致alpha值超过1，限制一下
                col.a = saturate(col.a);
                col.a *= _AlphaScale;

                col.rgb = MixFog(col.rgb, input.viewDirWSAndFogFactor.w);

                return col;
            }
            ENDHLSL
        }
    }
}