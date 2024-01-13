#ifndef _MC_COMMON_INCLUDE_HLSL
#define _MC_COMMON_INCLUDE_HLSL

#ifdef LIGHTMAP_ON
    #define DIFFUSE_OUTPUT_SH(normalWS, OUT)
#else
    #define DIFFUSE_OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSH(normalWS)
#endif

// 解码法线贴图信息，这里针对的是ba通道存取其它内容的法线贴图
inline half3 UnpackCustomNormal(half4 packedNormal, half scale)
{
    half3 normal;
    normal.xy = (packedNormal.xy * 2 - 1) * scale;
    normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
    return normal;
}

half MC_GLOBAL_SPECULAR_ON;
half4 MC_SpecularWorldDir; // 高光自定方向

half3 GetSpecularLightDir(half3 oriLightDir, float3 positionWS)
{
    half3 globalSpecLightDir = MC_SpecularWorldDir.xyz - positionWS * MC_SpecularWorldDir.w;
    half3 dir = lerp(oriLightDir, globalSpecLightDir, MC_GLOBAL_SPECULAR_ON);
    return dir;
}

half3 GetWorldSpaceLightDir(float3 positionWS)
{
    return _MainLightPosition.xyz - positionWS * _MainLightPosition.w;
}

// 场景内的主光源对角色来说太亮, 但调整场景灯光的工作量太大, 因此采用该折衷方案:
// 角色shader在计算主光源渲染前先将主光源的强度乘 * 0.25(基本保证不会过曝)
// 再由另外的角色补光灯给角色补光(方便角色组的美术控制角色最终渲染结果)
#define CHARACTER_LIGHT_INTENSITY 0.25

inline half Pow3(half x)
{
    return x * x * x;
}

inline half Pow5(half x)
{
    return x * x * x * x * x;
}

inline half2 Rotate2D(half2 vec, half rad)
{
    half s, c;
    sincos(rad, s, c);
    half2x2 rotate = half2x2(half2(c, -s), half2(s, c));
    return mul(rotate, vec);
}

inline half FresnelTerm(half F0, half cosA)
{
    half t = Pow5(1 - cosA);   // ala Schlick interpoliation
    return F0 + (1 - F0) * t;
}

inline half3 FresnelLerp(half3 F0, half3 F90, half cosA)
{
    half t = Pow5(1 - cosA); // ala Schlick interpoliation
    return lerp(F0, F90, t);
}

#define LUMINANCE_CONST half3(0.2126729,  0.7151522, 0.0721750)

half LinearColorToLuminance(half3 linearColor)
{
    return dot(linearColor, LUMINANCE_CONST);
}

half InvLerp(half min, half max, half val)
{
    half result = saturate((val - min) / (max - min));
    return lerp(result, val >= min, min == max);
}

half3 Remap(half inMin, half inMax, half3 outMin, half3 outMax, half val)
{
    return lerp(outMin, outMax, InvLerp(inMin, inMax, val));
}

half3 CalcToonColor(half3 albedo, half3 shadow, half lambert, half step, half feather)
{
    feather /= 2;
    return Remap(saturate(step - feather), saturate(step + feather), shadow, albedo, lambert);
}

#endif