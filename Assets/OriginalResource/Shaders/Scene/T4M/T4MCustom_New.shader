Shader "MC/Scene/T4MNew"
{
    Properties
    {
        [KeywordEnum(TWO, THREE, FOUR)] _TEXTURE ("纹理使用数目", Float) = 0
        [Space]
        [HDR]_SpecColor ("高光 颜色", Color) = (1, 1, 1, 1)
        _SpecSmooth ("高光过渡阈值", Range(0, 1)) = 0.5
        [Space]
        _ShininessL0 ("Layer1高光强度", Range(0.001, 1)) = 0.078125
        _Gloss0 ("Layer1光滑度", Range(0, 1)) = 0
        _Metallic0 ("Layer1金属度", Range(0, 1)) = 0.5
        _Splat0 ("Layer 1 (R)", 2D) = "white" {}
        _ShininessL1 ("Layer2高光强度", Range(0.001, 1)) = 0.078125
        _Gloss1 ("Layer2光滑度", Range(0, 1)) = 0
        _Metallic1 ("Layer2金属度", Range(0, 1)) = 0.5
        _Splat1 ("Layer 2 (G)", 2D) = "white" {}
        _ShininessL2 ("Layer3高光强度", Range(0.001, 1)) = 0.078125
        _Gloss2 ("Layer3光滑度", Range(0, 1)) = 0
        _Metallic2 ("Layer3金属度", Range(0, 1)) = 0.5
        _Splat2 ("Layer 3 (B)", 2D) = "white" {}
        _ShininessL3 ("Layer4高光强度", Range(0.001, 1)) = 0.078125
        _Gloss3 ("Layer4光滑度", Range(0, 1)) = 0
        _Metallic3 ("Layer4金属度", Range(0, 1)) = 0.5
        _Splat3 ("Layer 4 (A)", 2D) = "white" {}
        _BumpSplat0 ("Layer1Normalmap", 2D) = "bump" {}
        _NormalFactor0("Normal Factor1", Range(0, 2)) = 0
        _BumpSplat1 ("Layer2Normalmap", 2D) = "bump" {}
        _NormalFactor1("Normal Factor2", Range(0, 2)) = 0
        _BumpSplat2 ("Layer3Normalmap", 2D) = "bump" {}
        _NormalFactor2("Normal Factor3", Range(0, 2)) = 0
        _BumpSplat3 ("Layer4Normalmap", 2D) = "bump" {}
        _NormalFactor3("Normal Factor4", Range(0, 2)) = 0
        _Control ("Control (RGBA)", 2D) = "white" {}
        
        [Header(Emission)]
        _EmissionPower ("自发光强弱", Range(0, 2)) = 0
        [Space]
        [Header(Wet)]
        [Toggle(_WET_ON)] _WetOn ("开启潮湿", float) = 0
        _WetLevel ("潮湿程度", Range(0, 1)) = 0.5
        _FloodLevel1 ("砖块缝隙水位", Range(0, 1)) = 0
        _FloodLevel2 ("水坑水位", Range(0, 1)) = 0.5
        _RainIntensity ("降雨强度", Range(0, 1)) = 1
        [Header(Ripple)]
        _Density ("密度", Range(0.01, 1)) = 1
        _SpreadSpd ("波动速度", Range(1, 2)) = 1.25
        _WaveGap ("波的宽度", Range(0.1, 0.6)) = 0.256
        _WaveHei ("波动高度", Range(0.1, 10)) = 1.17
        _Tile ("尺寸", Range(0.1, 2)) = 0.23
        [Header(WaterDistort)]
        _WaterNoiseMap ("扰动噪声", 2D) = "white" {}
        _WaterDistortStrength ("水面扰动强度",Range(0, 1)) = 0.25
        _WaterDistortScale ("扰动尺寸",Range(0.01, 1)) = 0.25
        _WaterDistortTimeScale ("扰动速度",Range(0, 5)) = 3
    }
    
    HLSLINCLUDE
    
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    #include "../../CommonInclude.hlsl"
    #include "../WetLib.hlsl"

    sampler2D _Control;
    sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
    sampler2D _BumpSplat0, _BumpSplat1, _BumpSplat2, _BumpSplat3;
    half3 _LightningColor;

    CBUFFER_START(UnityPerMaterial)
    half4 _Control_ST;
    half4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
    half _NormalFactor0, _NormalFactor1, _NormalFactor2, _NormalFactor3;
    half _ShininessL0, _ShininessL1, _ShininessL2, _ShininessL3;
    half _Gloss0, _Gloss1, _Gloss2, _Gloss3;
    half _Metallic0, _Metallic1, _Metallic2, _Metallic3;

    half3 _SpecColor;
    half _SpecSmooth;

    half _EmissionPower;

    CBUFFER_END

    struct T4MVertexInput
    {
        float4 positionOS : POSITION;
        half3 normalOS : NORMAL;
        half4 tangentOS : TANGENT;
        half2 texcoord : TEXCOORD0;
        float2 lightmapUV : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct T4MV2F
    {
        float4 positionCS : SV_POSITION;
        half2 uv : TEXCOORD0;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1); // 烘焙物体:光照贴图, 动态物体:光照探针
        float3 positionWS : TEXCOORD2; // 顶点坐标(世界)
        half4 normalWS : TEXCOORD3; // xyz:法线(世界); w:观察方向(世界).x
        half4 tangentWS : TEXCOORD4; // xyz:切线(世界); w:观察方向(世界).y
        half4 bitangentWS : TEXCOORD5; // xyz:副切线(世界); w:观察方向(世界).z
        half4 fogFactorAndVertexLight : TEXCOORD6; // x: 雾效, yzw: 次要光源(逐顶点)
        float4 shadowCoord : TEXCOORD7; // 阴影纹理坐标
        half4 splatUV01 : TEXCOORD8;
    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        half4 splatUV23 : TEXCOORD9;
    #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct T4mInputData
    {
        float3 positionWS;
        half3 normalWS;
        half3 viewDirectionWS;
        float4 shadowCoord;
        half fogCoord;
        half3 vertexLighting; // 实时多光源的Lambert光照结果的叠加
        half3 bakedGI; // 全局照明(静态物体是lightmap, 动态物体是lightProbe)
        half2 normalizedScreenSpaceUV;
        half4 shadowMask;
    };

    struct T4MSurfaceData
    {
        half3 albedo;
        half smoothness;
        half3 emission;
        half specular;
        half metallic;
        half3 normalTS;
        half diffuseScale;
    };

    T4MSurfaceData InitializeT4MSurfaceData(T4MV2F input)
    {
        T4MSurfaceData surfaceData = (T4MSurfaceData)0;
        half4 splatControl = tex2D(_Control, input.uv);

        half4 splatVal0 = tex2D(_Splat0, input.splatUV01.xy);
        surfaceData.albedo = splatControl.r * splatVal0.rgb;
        surfaceData.smoothness = splatControl.r * _Gloss0;
        surfaceData.specular = smoothstep(_SpecSmooth, 1, splatControl.r) * _ShininessL0 * splatVal0.a;
        surfaceData.metallic += splatControl.r * _Metallic0;
        half4 bumpVal = splatControl.r * tex2D(_BumpSplat0, input.splatUV01.xy);
        half normalScale = splatControl.r * _NormalFactor0;

        half4 splatVal1 = tex2D(_Splat1, input.splatUV01.zw);
        surfaceData.albedo += splatControl.g * splatVal1.rgb;
        surfaceData.smoothness += splatControl.g * _Gloss1;
        surfaceData.specular += smoothstep(_SpecSmooth, 1, splatControl.g) * _ShininessL1 * splatVal1.a;
        surfaceData.metallic += splatControl.g * _Metallic1;
        bumpVal += splatControl.g * tex2D(_BumpSplat1, input.splatUV01.zw);
        normalScale += splatControl.g * _NormalFactor1;

    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        half4 splatVal2 = tex2D(_Splat2, input.splatUV23.xy);
        surfaceData.albedo += splatControl.b * splatVal2.rgb;
        surfaceData.smoothness += splatControl.b * _Gloss2;
        surfaceData.specular += smoothstep(_SpecSmooth, 1, splatControl.b) * _ShininessL2 * splatVal2.a;
        surfaceData.metallic += splatControl.b * _Metallic2;
        bumpVal += splatControl.b * tex2D(_BumpSplat2, input.splatUV23.xy);
        normalScale += splatControl.b * _NormalFactor2;
        
    #ifdef _TEXTURE_FOUR
        half4 splatVal3 = tex2D(_Splat3, input.splatUV23.zw);
        surfaceData.albedo += splatControl.a * splatVal3.rgb;
        surfaceData.smoothness += splatControl.a * _Gloss3;
        surfaceData.specular += smoothstep(_SpecSmooth, 1, splatControl.a) * _ShininessL3 * splatVal3.a;
        surfaceData.metallic += splatControl.a * _Metallic3;
        bumpVal += splatControl.a * tex2D(_BumpSplat3, input.splatUV23.zw);
        normalScale += splatControl.a * _NormalFactor3;
    #endif
        
    #endif
        
        surfaceData.normalTS = UnpackNormalScale(bumpVal, normalScale);

        surfaceData.specular = max(0.001, surfaceData.specular);
        
        surfaceData.emission = surfaceData.albedo * _EmissionPower;
        surfaceData.diffuseScale = 1;
        
        return surfaceData;
    }
    
    struct T4MInputData
    {
        float3 positionWS;
        half3 normalWS;
        half3 viewDirectionWS;
        float4 shadowCoord;
        half fogCoord;
        half3 vertexLighting; // 实时多光源的Lambert光照结果的叠加
        half3 bakedGI; // 全局照明(静态物体是lightmap, 动态物体是lightProbe)
        half4 shadowMask;
    };

    T4MInputData InitializeT4MInputData(T4MV2F input, T4MSurfaceData surfaceData)
    {
        T4MInputData inputData = (T4MInputData)0;
        inputData.positionWS = input.positionWS;
        inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(input.tangentWS.xyz,
            input.bitangentWS.xyz, input.normalWS.xyz));
        inputData.normalWS = normalize(inputData.normalWS);
        half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
        inputData.viewDirectionWS = SafeNormalize(viewDirWS);
        inputData.shadowCoord = input.shadowCoord;
        inputData.fogCoord = input.fogFactorAndVertexLight.x;
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
        inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
        inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
        return inputData;
    }

    // 计算高光反射
    half3 CustomizedSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, T4MSurfaceData surfaceData)
    {
        float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
        half NdotH = max(0.0001, dot(normal, halfVec));
        half smoothness = surfaceData.smoothness * 128;
        smoothness = max(0.005, smoothness);

        // 归一化系数，为了维持能量守恒，反射光不能大于入射光。 原理:http://www.thetenthplanet.de/archives/255
        half specular = surfaceData.specular * (smoothness + 2.0) / TWO_PI;
        specular *= max(0, pow(NdotH, smoothness));

        // 设置高光反射颜色(依据金属度设置)
        half3 dielectricSpec = lerp(kDielectricSpec.rgb, surfaceData.albedo, surfaceData.metallic);
        return lightColor * _SpecColor * dielectricSpec * specular;
    }

    half4 T4MRender(T4MInputData inputData, T4MSurfaceData surfaceData)
    {
        // 获取主光源
        Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
        // 实时与烘焙光照混合
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
        // 主光源叠加上闪电
        mainLight.color += _LightningColor;
        // 主光源叠加阴影衰减以及距离衰减
        half3 attenuatedLightColor = mainLight.color * mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    
    #if _WET_ON
        half3 lightColorAndAmbient = attenuatedLightColor + inputData.bakedGI;
        DoWetSetup(surfaceData.diffuseScale, surfaceData.smoothness, inputData.positionWS, inputData.normalWS, lightColorAndAmbient, surfaceData.emission);
    #endif
        
        // 漫反射 + 环境光(光照贴图或光照探针)
        half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction,
                                                                 inputData.normalWS);
        // 高光反射
        half3 specularLightDir = GetSpecularLightDir(mainLight.direction, inputData.positionWS);
        half3 specularColor = CustomizedSpecular(mainLight.color, specularLightDir, inputData.normalWS,
                                                 inputData.viewDirectionWS, surfaceData);

        // 逐像素多光源
    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
            half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
            diffuseColor += LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);
            specularColor += CustomizedSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, surfaceData);
        }
    #endif
        // 逐顶点多光源
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        diffuseColor += inputData.vertexLighting;
    #endif
        // 漫反射 + 高光反射 + 自发光
        half3 finalColor = diffuseColor * surfaceData.albedo * surfaceData.diffuseScale + specularColor + surfaceData.emission;
        return half4(finalColor, 1);
    }

    T4MV2F T4MVertex(T4MVertexInput input)
    {
        T4MV2F output = (T4MV2F)0;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        
        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

        half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
        // 对次要光源逐个计算光照(兰伯特模型), 结果相加
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

        output.uv = TRANSFORM_TEX(input.texcoord, _Control);
        output.splatUV01.xy = TRANSFORM_TEX(input.texcoord, _Splat0);
        output.splatUV01.zw = TRANSFORM_TEX(input.texcoord, _Splat1);
    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        output.splatUV23.xy = TRANSFORM_TEX(input.texcoord, _Splat2);
    #ifdef _TEXTURE_FOUR
        output.splatUV23.zw = TRANSFORM_TEX(input.texcoord, _Splat3);
    #endif
    #endif

        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV); // 处理LightmapUV(拉伸、偏移)
        DIFFUSE_OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        output.positionWS = vertexInput.positionWS;
        output.shadowCoord = GetShadowCoord(vertexInput);
        output.positionCS = vertexInput.positionCS;
        return output;
    }

    half4 T4MFragment(T4MV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        T4MSurfaceData surfaceData = InitializeT4MSurfaceData(input);
        T4MInputData inputData = InitializeT4MInputData(input, surfaceData);
        half4 color = T4MRender(inputData, surfaceData);

        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }

    struct T4MMetaVertexInput
    {
        float4 positionOS : POSITION;
        half2 texcoord : TEXCOORD0;
    };

    struct T4MMetaV2F
    {
        float4 positionCS : SV_POSITION;
        half2 uv : TEXCOORD0;
        half4 splatUV01 : TEXCOORD1;
    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        half4 splatUV23 : TEXCOORD9;
    #endif
    };

    T4MMetaV2F T4MVertexMeta(T4MMetaVertexInput input)
    {
        T4MMetaV2F output;
        output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
        output.uv = TRANSFORM_TEX(input.texcoord, _Control);
        output.splatUV01.xy = TRANSFORM_TEX(input.texcoord, _Splat0);
        output.splatUV01.zw = TRANSFORM_TEX(input.texcoord, _Splat1);
    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        output.splatUV23.xy = TRANSFORM_TEX(input.texcoord, _Splat2);
    #ifdef _TEXTURE_FOUR
        output.splatUV23.zw = TRANSFORM_TEX(input.texcoord, _Splat3);
    #endif
    #endif
        return output;
    }

    half4 T4MFragmentMeta(T4MMetaV2F input) : SV_Target
    {
        MetaInput metaInput = (MetaInput)0;
        half4 splatControl = tex2D(_Control, input.uv);
        half3 albedo = 0;
        half3 splatVal0 = tex2D(_Splat0, input.splatUV01.xy).rgb;
        albedo = splatControl.r * splatVal0;

        half3 splatVal1 = tex2D(_Splat1, input.splatUV01.zw).rgb;
        albedo += splatControl.g * splatVal1;

    #if defined(_TEXTURE_THREE) || defined(_TEXTURE_FOUR)
        half3 splatVal2 = tex2D(_Splat2, input.splatUV23.xy).rgb;
        albedo += splatControl.b * splatVal2;
        
    #ifdef _TEXTURE_FOUR
        half3 splatVal3 = tex2D(_Splat3, input.splatUV23.zw).rgb;
        albedo += splatControl.a * splatVal3;
    #endif
        
    #endif
        metaInput.Albedo = albedo;
        metaInput.Emission = albedo * _EmissionPower;
        return MetaFragment(metaInput);
    }

    ENDHLSL

    SubShader
    {
        Tags
        {
            "SplatCount" = "4"
            "Queue" = "Geometry+100"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            
            #pragma shader_feature_local _ _TEXTURE_THREE _TEXTURE_FOUR
            #pragma shader_feature_local _WET_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON
            
            #pragma vertex T4MVertex
            #pragma fragment T4MFragment
            
            ENDHLSL
        }
        
        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }
            Cull Off

            HLSLPROGRAM

            #pragma shader_feature_local _ _TEXTURE_THREE _TEXTURE_FOUR
            
            #pragma vertex T4MVertexMeta
            #pragma fragment T4MFragmentMeta
            
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}