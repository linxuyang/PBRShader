#ifndef _MC_WATER_NEW_INCLUDE_HLSL
#define _MC_WATER_NEW_INCLUDE_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "../../CommonInclude.hlsl"

#define CAUSTIC_MATRIX half3x3(2, 1, -2, 3, -2, 1, 1, 2, 2)

sampler2D _NormalTex;
sampler2D _FadeShape;
sampler2D _WaterFoamTex;
sampler2D _SSPR_RT;
TEXTURECUBE(_IBLTex);
SAMPLER(sampler_IBLTex);
half _IblLuminance;
half4 _IBLTex_HDR;
// 打雷
half3 _LightningColor;

// CBUFFER_START(UnityPerMaterial)
half _WaveScale;
half _WaveSpeed;
half _WaveFrequency;
// 折射相关
float4 _NormalTex_ST;
half _NormalScale;
half3 _WindDir;
half _RefractionDisort;

half4 _ShallowColor;
half4 _DeepColor;
half _DepthScale;
half _DepthPower;

half _CausticFade;
half _CausticScale;
half _CausticPower;
half3 _CausticColor;
half _CausticSpeed;
half _DiffuseIntensity;

half3 _SpecularColor;
half _SpecularPower, _Gloss;

half3 _FoamColor;
half _FoamSpeed;
half _FoamDistort;
half _FoamScale;

// 伪光源
half3 _FakeLightRotation;
half3 _FakeLightColor;
half _FakeLightColorStrength;

// 远处渐隐
half _FadeIntensity;

// 边缘光
half3 _EdgeColor;
half _DistanceSmoothStart;
half _DistanceStartTrim;
half _DistanceSmoothEnd;
#define _DistanceFinalStart _DistanceSmoothStart + _DistanceStartTrim / 100
// CBUFFER_END

void WaterWave(inout float3 vertex, in float time)
{
    float2 uv = vertex.xz * _WaveFrequency + time * _WaveSpeed;
    vertex.y += (sin(uv.x) + cos(uv.y)) * _WaveScale;
}

half3 GetNormalTangentSpace(float2 wind, float time, float2 normalUV)
{
    // 两道uv交叉移动的法线叠加
    float4 offset = 0.701 * float4(wind.x - wind.y, wind.x + wind.y, wind.x + wind.y, wind.y - wind.x);
    float4 uvWind = normalUV.xyxy - time * offset;
    half3 normalTS_1 = UnpackCustomNormal(tex2D(_NormalTex, uvWind.xy), _NormalScale);
    half3 normalTS_2 = UnpackCustomNormal(tex2D(_NormalTex, uvWind.zw * 0.4), _NormalScale);
    return lerp(normalTS_1, normalTS_2, 0.5);
}

// 正交投影通用距离计算
half3 RotateFakeLight(half3 lightDir, float3 rotation)
{
    half sx, sy, sz, cx, cy, cz;
    sincos(rotation.x, sx, cx);
    sincos(rotation.y, sy, cy);
    sincos(rotation.z, sz, cz);
    float3x3 M = float3x3(cy * cz + sz * sy * sz, -cy * sz + sx * sy * cz, cx * sy,
                          cx * sz, cx * cz, -sx,
                          -sy * cz + sx * cy * sz, sy * sz + sx * cy * cz, cx * cy
    );
    return mul(M, lightDir);
}

void GetWaterDepthParams(float4 screenPos, half3 normalTS, out float depthDelta, out float disortDepthDelta,
                         out float finalDepthDelta)
{
    float rawDepth = SampleSceneDepth(screenPos.xy / screenPos.w);
    // 屏幕空间水底深度
    float linearDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
    // // 屏幕空间水面深度
    float depthWater = screenPos.z;
    depthDelta = linearDepth - depthWater;
    float2 OffsetUV = normalTS.xy * saturate(depthDelta * _DepthScale) * _RefractionDisort;
    // 采样经过折射偏移后的相机深度图
    rawDepth = SampleSceneDepth((screenPos.xy + OffsetUV) / screenPos.w);
    linearDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
    disortDepthDelta = linearDepth - depthWater;
    finalDepthDelta = lerp(depthDelta, disortDepthDelta, step(0, disortDepthDelta));
}

// 假的海浪
inline half3 FoamColor(float2 uv, half2 wind, float time)
{
    float2 uvFoam = 0.701 * float2(uv.x + uv.y, uv.y - uv.x);
    half windPower = length(wind.xy);
    float cosT = wind.x / windPower;
    float sinT = wind.y / windPower;
    uvFoam = float2(uvFoam.x * cosT + sinT * uvFoam.y, -sinT * uvFoam.x + cosT * uvFoam.y);
    uvFoam -= time * float2(0.701, -0.701) * windPower * _FoamSpeed;
    half3 foamColor = tex2D(_WaterFoamTex, uvFoam * _FoamScale).rgb;
    foamColor *= foamColor;
    return foamColor * _FoamColor;
}

// 反射
inline half3 ReflectColor(float4 screenPos, half3 worldNormal, half3 worldView, half depthRatio)
{
    half3 reflColor = 0;
#if _REFLECTION_REALTIME// 平面反射
    screenPos.xy += worldNormal.xz * depthRatio;
    screenPos.xy /= screenPos.w;
    reflColor = tex2D(_SSPR_RT, screenPos.xy).rgb;
#elif _REFLECTION_CUBE// 静态cube反射
    half perceptualRoughness = 1 - _Gloss;
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
    half3 reflectionDir = reflect(-worldView, worldNormal);
    reflectionDir.y = max(0, reflectionDir.y);
    half4 envReflData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectionDir, mip);
    reflColor = DecodeHDREnvironment(envReflData, unity_SpecCube0_HDR);
#elif _REFLECTION_IBL// 静态cube反射，自定义cubemap
    half perceptualRoughness = 1 - _Gloss;
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
    half3 reflectionDir = reflect(-worldView, worldNormal);
    reflectionDir.y = max(0, reflectionDir.y);
    half4 envReflData = SAMPLE_TEXTURECUBE_LOD(_IBLTex, sampler_IBLTex, reflectionDir, mip);
    reflColor = DecodeHDREnvironment(envReflData, _IBLTex_HDR);
    reflColor *= _IblLuminance;
#endif
    // 雷光
    reflColor.rgb += _LightningColor;
    return reflColor.rgb;
}

// 折射
inline half3 RefractColor(float4 screenPos, half3 normalTS, half depth)
{
    half2 screenUV = screenPos.xy;
    screenUV += normalTS.xy * saturate(depth * _DepthScale) * _RefractionDisort;
    screenUV /= screenPos.w;
    return SampleSceneColor(screenUV);
}

// 基于连续空间旋转min叠加，实现焦散[https://blog.csdn.net/tjw02241035621611/article/details/80135626]
float CausticRotateMin(float2 uv, float time)
{
    float3 vec1 = mul(CAUSTIC_MATRIX * 0.5, float3(uv, time)); //3.对颜色空间进行操作
    float3 vec2 = mul(CAUSTIC_MATRIX * 0.4, vec1); //4.重复2，3操作
    float3 vec3 = mul(CAUSTIC_MATRIX * 0.3, vec2);
    float val = min(length(frac(vec1) - 0.5), length(frac(vec2) - 0.5)); //5.集合操作 min
    val = min(val, length(frac(vec3) - 0.5));
    val = pow(val, 7.0) * 25.; //6.亮度调整
    return val;
}

// 焦散
inline half3 CausticColor(float2 uv, float time, half depth, half viewDirY, half2 disortOffset)
{
    half power = smoothstep(1 - _CausticFade, 1, viewDirY);
    power *= saturate(depth) * _CausticPower;
    return CausticRotateMin(uv * _CausticScale + disortOffset, time * _CausticSpeed) * _CausticColor * power;
}

struct appdata
{
    float3 positionOS : POSITION;
    half2 texcoord : TEXCOORD0;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    half4 fogFactorAndVertexSH : TEXCOORD1;
    half4 normalWS : TEXCOORD2; // xyz:法线(世界); w:观察方向(世界).x
    half4 tangentWS : TEXCOORD3; // xyz:切线(世界); w:观察方向(世界).y
    half4 bitangentWS : TEXCOORD4; // xyz:副切线(世界); w:观察方向(世界).z
    float4 screenPos : TEXCOORD5;
    float3 fakeLightDir : TEXCOORD7;
    float2 wind : TEXCOORD8;
};

float3 _LightDirection;

struct WaterShadowCasterVertexInput
{
    float4 positionOS : POSITION;
    half2 texcoord : TEXCOORD0;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct WaterShadowCasterVertexOutput
{
    float4 positionCS : SV_POSITION;
};

float4 GetShadowPositionHClip(WaterShadowCasterVertexInput input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return positionCS;
}

WaterShadowCasterVertexOutput WaterShadowVertex(WaterShadowCasterVertexInput input)
{
    WaterShadowCasterVertexOutput output;
    UNITY_SETUP_INSTANCE_ID(input);
    #ifdef _VERTEX_WAVE_ON
    WaterWave(input.positionOS.xyz, fmod(_Time.y, 10000.0));
    #endif
    output.positionCS = GetShadowPositionHClip(input);
    return output;
}

half4 WaterShadowFragment(WaterShadowCasterVertexOutput input) : SV_TARGET
{
    return 0;
}

#endif
