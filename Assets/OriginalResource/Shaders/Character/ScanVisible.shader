Shader "MC/Character/Other/ScanVisible"
{
    Properties
    {
        [Header(Scan Visible)]
        _ScanOrigin("扫描起点(模型空间)", Vector) = (0, 0, 0, 0)
        _ScanDir("扫描方向(模型空间)", Vector) = (0, 1, 0, 0)
        _ScanDistance("扫描距离(模型空间)", Float) = 1
        _ScanSchedule("扫描进度", Range(0, 1)) = 0
        _ScanRandomNoise("扫描噪声", 2D) = "gray" {}
        _ScanRandomStrength("扫描噪声强度", Range(0, 0.1)) = 0.02
        _ScanSmoothRange("过渡范围", Range(0.01, 0.2)) = 0.05
        [HDR]_ScanSmoothColor1("边缘颜色", Color) = (1, 1, 1, 1)
        _ScanColor1Range("边缘颜色宽度", Range(1, 10)) = 5
        [HDR]_ScanSmoothColor2("过渡颜色", Color) = (1, 1, 1, 1)
        _ScanSmoothNoise("过渡噪声", 2D) = "white" {}
        _NoiseStrength("噪声强度", Range(0, 1)) = 0.5
        _NoiseDistortScale("噪声扭曲程度", Range(0, 0.1)) = 0.06
        _NoiseUVSpeedX("噪声UV速度-X", Float) = 0
        _NoiseUVSpeedY("噪声UV速度-Y", Float) = 0

        [Space]
        [Header(Special Render)]
        [HDR]_Color("叠加色 (RGBA)", Color) = (1, 1, 1, 1)
        _MainTex("固有色 (RGBA)", 2D) = "white" {}
        _MinRim("边缘柔和区间1", Range(0, 1)) = 0
        _MaxRim("边缘柔和区间2", Range(0, 1)) = 1
        [HDR]_RimColor("边缘颜色(RGB)", Color) = (0.5, 0.5, 0.5, 0.5)
        [HDR]_InnerColor("内部颜色(RGB)", Color) = (0.5, 0.5, 0.5, 0.5)
        _RimPower("边缘光衰减", Range(0.0,5.0)) = 2.5
        _MinRimAlpha("最小透明度", Range(0, 1)) = 0
        _AlphaPower("透明度衰减", Range(0, 8)) = 4

        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色 (RGB)", Color) = (.5, .5, .5, 1)
        [NoScaleOffset]_EmissionTex ("自发光遮罩R", 2D) = "white" {}
        _EmissionPower("强度", Range(0, 2)) = 0

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    sampler2D _ScanRandomNoise;
            sampler2D _ScanSmoothNoise;
            sampler2D _MainTex;
            sampler2D _EmissionTex;

            CBUFFER_START(UnityPerMaterial)
            half3 _ScanOrigin, _ScanDir;
            half _ScanDistance, _ScanSchedule, _ScanSmoothRange, _ScanColor1Range;
            
            half4 _ScanRandomNoise_ST;
            half _ScanRandomStrength;
            half3 _ScanSmoothColor1, _ScanSmoothColor2;
            
            half4 _ScanSmoothNoise_ST;
            half _NoiseStrength, _NoiseDistortScale, _NoiseUVSpeedX, _NoiseUVSpeedY;
            
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

    ENDHLSL
    
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"
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
                half2 texcoord : TEXCOORD0;
            };
            
            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                half scan : TEXCOORD1;
            };
            
            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output;
            
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);

                //扫描起点到顶点的向量
                half3 vertexToOrigin = input.positionOS.xyz - _ScanOrigin;
                //向量与扫描方向点乘计算出顶点在扫描方向的投影点与扫描起点的距离, 再除去整体扫描距离得到该顶点位于扫描轴线上的位置(比例)
                half scan = dot(vertexToOrigin, normalize(_ScanDir)) / _ScanDistance;
                output.scan = scan;
                return output;
            }
            
            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                half scan = input.scan;
                // 采样扫描噪声并将结果从0~1映射到-0.5~0.5, 再乘上噪声强度
                half scanOffset = tex2D(_ScanRandomNoise, input.uv * _ScanRandomNoise_ST.xy + _ScanRandomNoise_ST.zw).b;
                scanOffset = (scanOffset - 0.5) * _ScanRandomStrength;
                // scan叠加上扫描噪声的结果, 把平直的扫描线变成不规则的曲线
                scan += scanOffset;
                //最后再根据当前扫描进度和过渡区域大小计算出一个值，该值表示了顶点相对扫描线的位置，具体含义如下
                // value < 0 : 不显示    0 < value < 1 : 处于扫描线内部的过渡区域     value > 1 正常显示
                scan = 1 - (scan - _ScanSchedule) / _ScanSmoothRange;
                
                //scan小于0的直接裁剪掉不显示
                clip(scan);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite Off

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            #pragma shader_feature_local _EMISSION_ON

            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment

            

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
                float3 scan : TEXCOORD4;
            };

            VertexOutput Vertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;

                float3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWSAndFogFactor.xyz = GetWorldSpaceViewDir(positionWS);

                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);

                //扫描起点到顶点的向量
                half3 vertexToOrigin = input.positionOS.xyz - _ScanOrigin;
                //向量与扫描方向点乘计算出顶点在扫描方向的投影点与扫描起点的距离, 再除去整体扫描距离得到该顶点位于扫描轴线上的位置(比例)
                half scan = dot(vertexToOrigin, normalize(_ScanDir)) / _ScanDistance;
                output.scan.x = scan;
                //计算屏幕UV 后续采样噪声需要用
                float4 screenPos = ComputeScreenPos(output.positionCS);
                output.scan.yz = screenPos.xy / screenPos.w;
                output.viewDirWSAndFogFactor.w = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Fragment(VertexOutput input) : SV_Target
            {
                half scan = input.scan.x;
                // 采样扫描噪声并将结果从0~1映射到-0.5~0.5, 再乘上噪声强度
                half scanOffset = tex2D(_ScanRandomNoise, input.uv * _ScanRandomNoise_ST.xy + _ScanRandomNoise_ST.zw).b;
                scanOffset = (scanOffset - 0.5) * _ScanRandomStrength;
                // scan叠加上扫描噪声的结果, 把平直的扫描线变成不规则的曲线
                scan += scanOffset;
                //最后再根据当前扫描进度和过渡区域大小计算出一个值，该值表示了顶点相对扫描线的位置，具体含义如下
                // value < 0 : 不显示    0 < value < 1 : 处于扫描线内部的过渡区域     value > 1 正常显示
                scan = 1 - (scan - _ScanSchedule) / _ScanSmoothRange;
                
                //scan小于0的直接裁剪掉不显示
                clip(scan);

                half4 col = tex2D(_MainTex, input.uv);
                col *= _Color;

                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = SafeNormalize(input.viewDirWSAndFogFactor.xyz);
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
                
                // 屏幕UV 应用噪声纹理的拉伸参数
                float2 screenUV = input.scan.yz;
                screenUV *= _ScanSmoothNoise_ST.xy;
                // 采样一次噪声图用于扭曲效果
                half2 distort = tex2D(_ScanSmoothNoise, screenUV).gb * _NoiseDistortScale;
                // 根据时间做UV动画
                half2 uvOffset = fmod(_Time.x, 100.0) * half2(_NoiseUVSpeedX, _NoiseUVSpeedY);
                // 再次采样噪声(应用了UV动画和扭曲效果)
                half noise = tex2D(_ScanSmoothNoise, screenUV + uvOffset + distort).r;
                // 把噪声结果从 0~1 改成 -0.5~0.5
                noise = noise - 0.5;

                // 反转一下scan(0~1):值越小越靠近正常显示区域，越大越靠近裁剪区域
                half scanSmooth = max(0, 1 - scan);
                // 噪声乘上根据扫描线计算出来的加权值(越靠近扫描线中央加权值越接近1, 扫描线上下边界加权值为0)
                noise *= 1 - abs(scanSmooth - 0.5) * 2;
                // scanSmooth根据噪声做上下随机偏移
                scanSmooth += noise * _NoiseStrength;
                // 计算边缘颜色的加权值
                half coreSmooth = pow(scanSmooth, 5) * _ScanColor1Range;
                // 扫描线的颜色 = 过渡颜色 + 边缘颜色 * 加权值
                half3 scanSmoothColor = _ScanSmoothColor1 * coreSmooth + _ScanSmoothColor2;
                // 最后使用插值的方式形成正常显示的模型与扫描线的过渡
                col.rgb = lerp(col.rgb, scanSmoothColor, scanSmooth);

                col.rgb = MixFog(col.rgb, input.viewDirWSAndFogFactor.w);

                return col;
            }
            ENDHLSL
        }

    }
}