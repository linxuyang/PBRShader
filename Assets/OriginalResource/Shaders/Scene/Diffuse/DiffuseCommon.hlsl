#ifndef _MC_DIFFUSE_COMMON_HLSL
#define _MC_DIFFUSE_COMMON_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "../WetLib.hlsl"
#include "../../CommonInclude.hlsl"

struct DiffuseVertexInput
{
    float4 positionOS : POSITION;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    half2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct DiffuseBumpV2F
{
    float4 positionCS : SV_POSITION;
    half4 uv : TEXCOORD0; // xy:主纹理UV; zw:法线贴图UV
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1); // 烘焙物体:光照贴图, 动态物体:光照探针
    float3 positionWS : TEXCOORD2; // 顶点坐标(世界)
    half4 normalWS : TEXCOORD3; // xyz:法线(世界); w:观察方向(世界).x
    half4 tangentWS : TEXCOORD4; // xyz:切线(世界); w:观察方向(世界).y
    half4 bitangentWS : TEXCOORD5; // xyz:副切线(世界); w:观察方向(世界).z
    half4 fogFactorAndVertexLight : TEXCOORD6; // x: 雾效, yzw: 次要光源(逐顶点)
    float4 shadowCoord : TEXCOORD7; // 阴影纹理坐标
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct DiffuseNormalInputs
{
    half3 tangentWS;
    half3 bitangentWS;
    half3 normalWS;
};

DiffuseNormalInputs GetDiffuseNormalInputs(half3 normalOS, half4 tangentOS)
{
    DiffuseNormalInputs tbn;
    // mikkts space compliant. only normalize when extracting normal at frag.
    half sign = tangentOS.w * GetOddNegativeScale();
    tbn.normalWS = TransformObjectToWorldNormal(normalOS);
    tbn.tangentWS = TransformObjectToWorldDir(tangentOS.xyz);
    tbn.bitangentWS = cross(tbn.normalWS, tbn.tangentWS) * sign;
    return tbn;
}

struct DiffuseInputData
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

struct DiffuseSurfaceData
{
    half4 albedo;
    half3 specularColor;
    half metallic;
    half smoothness;
    half3 emission;
    half occlusion;
    half specular;
    half diffuseScale;
    half3 normalTS;
    half envRefScale; // 环境反射强度
    half2 ssprNoise; // 实时反射UV扰动
};

DiffuseInputData InitializeDiffuseBumpInputData(DiffuseBumpV2F input, DiffuseSurfaceData surfaceData)
{
    DiffuseInputData inputData = (DiffuseInputData)0;
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
    #if _SCREEN_DOOR_ON || MC_GLOBAL_SSPR_ON
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    #endif
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
    return inputData;
}

// 计算高光反射
half3 CustomizedSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, DiffuseSurfaceData surfaceData)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = max(dot(normal, halfVec), 0.0001);
    half smoothness = surfaceData.smoothness * 128;
    smoothness = max(0.005, smoothness);

    // 归一化系数，为了维持能量守恒，反射光不能大于入射光。 原理:http://www.thetenthplanet.de/archives/255
    half specular = surfaceData.specular * (smoothness + 2.0) / TWO_PI;
    specular *= max(0, pow(NdotH, smoothness));

    // 设置高光反射颜色(依据金属度设置)
    half3 dielectricSpec = lerp(kDielectricSpec.rgb, surfaceData.albedo.rgb, surfaceData.metallic);
    return lightColor * surfaceData.specularColor * dielectricSpec * specular;
}

half3 _LightningColor;

half4 DiffuseRender(DiffuseInputData inputData, DiffuseSurfaceData surfaceData)
{
    // 获取主光源
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
    // 实时与烘焙光照混合
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    // 主光源叠加上闪电
    mainLight.color += _LightningColor;
    // 主光源叠加阴影衰减以及距离衰减
    half3 attenuatedLightColor = mainLight.color * mainLight.shadowAttenuation * mainLight.distanceAttenuation;
#if _MIXED_LIGHTING_SUBTRACTIVE
    half3 attenuatedSpecLightColor = mainLight.color * mainLight.shadowAttenuation;
#else
    half3 attenuatedSpecLightColor = attenuatedLightColor;
#endif

#if _WET_ON
    half3 lightColorAndAmbient = attenuatedLightColor + inputData.bakedGI;
    DoWetSetup(surfaceData.diffuseScale, surfaceData.smoothness, inputData.positionWS, inputData.normalWS, lightColorAndAmbient, surfaceData.emission);
#endif
    
    // 漫反射 + 环境光(光照贴图或光照探针)
    half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction,
                                                             inputData.normalWS);
    // 高光反射
    half3 specularLightDir = GetSpecularLightDir(mainLight.direction, inputData.positionWS);
    half3 specularColor = CustomizedSpecular(attenuatedSpecLightColor, specularLightDir, inputData.normalWS,
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
    half3 finalColor = diffuseColor * surfaceData.albedo.rgb * surfaceData.diffuseScale * surfaceData.occlusion + specularColor + surfaceData.emission;
    return half4(finalColor, surfaceData.albedo.a);
}

// 环境反射
half3 EnvironmentReflections(DiffuseInputData inputData, DiffuseSurfaceData surfaceData, half reflSmooth, half reflPower)
{
    half3 envRef = 0;
    #if _ENVREFLECT_ON
    half nDotV = abs(dot(inputData.normalWS, inputData.viewDirectionWS));
    half3 reflectDir = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half perceptualRoughness = 1 - saturate(surfaceData.smoothness * reflSmooth);
    half surfaceReduction = 1.0 - 0.6 * Pow3(perceptualRoughness) + 0.08 * Pow4(perceptualRoughness);
        
    half oneMinusReflectivity = kDielectricSpec.a * (1 - surfaceData.envRefScale * surfaceData.metallic);
    half grazingTerm = saturate(2 - perceptualRoughness - oneMinusReflectivity);
        
    half3 dielectricSpec = lerp(kDielectricSpec.rgb, surfaceData.albedo.rgb, surfaceData.metallic);

    half3 env = surfaceReduction * FresnelLerp(dielectricSpec, grazingTerm, nDotV);
    
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;;
    half4 envReflData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
    half3 envReflCol = DecodeHDREnvironment(envReflData, unity_SpecCube0_HDR);
        
    env = surfaceData.envRefScale * surfaceData.occlusion * reflPower * envReflCol * env;
    envRef += env;
    #endif
    return envRef;
}

// META 相关 begin

struct DiffuseMetaVertexInput
{
    float4 positionOS : POSITION;
    half2 texcoord : TEXCOORD0;
};

struct DiffuseMetaV2F
{
    float4 positionCS : SV_POSITION;
    half2 uv : TEXCOORD0;
    #if _EMISSION_ON
    half2 emissionUV : TEXCOORD1;
    #endif
};

// META 相关 end

#endif