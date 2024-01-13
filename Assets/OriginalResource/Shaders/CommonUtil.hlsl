#ifndef _MC_COMMON_UTIL_HLSL
#define _MC_COMMON_UTIL_HLSL
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


inline float InvLerp(float Min, float Max, float Val)
{
    return Min == Max ? Val >= Min : clamp((Val - Min) / (Max - Min), 0, 1);
}
inline float2 InvLerp(float2 Min, float2 Max, float2 Val)
{
    return clamp((Val - Min) / (Max - Min), 0, 1);
}
inline float3 InvLerp(float3 Min, float3 Max, float3 Val)
{
    return clamp((Val - Min) / (Max - Min), 0, 1);
}
inline float4 InvLerp(float4 Min, float4 Max, float4 Val)
{
    return clamp((Val - Min) / (Max - Min), 0, 1);
}

inline float Remap(float InMin, float InMax, float OutMin, float OutMax, float Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}
inline float2 Remap(float InMin, float InMax, float2 OutMin, float2 OutMax, float Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}
inline float3 Remap(float InMin, float InMax, float3 OutMin, float3 OutMax, float Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}
inline float4 Remap(float InMin, float InMax, float4 OutMin, float4 OutMax, float Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}

inline float1 Remap(float2 InMin, float2 InMax, float OutMin, float OutMax, float2 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float2(1,1));
    return lerp(OutMin, OutMax, i);
}
inline float2 Remap(float2 InMin, float2 InMax, float2 OutMin, float2 OutMax, float2 Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}
inline float3 Remap(float2 InMin, float2 InMax, float3 OutMin, float3 OutMax, float2 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float2(1,1));
    return lerp(OutMin, OutMax, i);
}
inline float4 Remap(float2 InMin, float2 InMax, float4 OutMin, float4 OutMax, float2 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float2(1,1));
    return lerp(OutMin, OutMax, i);
}

inline float Remap(float3 InMin, float3 InMax, float OutMin, float OutMax, float3 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float3(1,1,1));
    return lerp(OutMin, OutMax, i);
}
inline float2 Remap(float3 InMin, float3 InMax, float2 OutMin, float2 OutMax, float3 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float3(1,1,1));
    return lerp(OutMin, OutMax, i);
}
inline float3 Remap(float3 InMin, float3 InMax, float3 OutMin, float3 OutMax, float3 Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}
inline float4 Remap(float3 InMin, float3 InMax, float4 OutMin, float4 OutMax, float3 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float3(1,1,1));
    return lerp(OutMin, OutMax, i);
}

inline float Remap(float4 InMin, float4 InMax, float OutMin, float OutMax, float4 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float4(1,1,1,1));
    return lerp(OutMin, OutMax, i);
}
inline float2 Remap(float4 InMin, float4 InMax, float2 OutMin, float2 OutMax, float4 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float4(1,1,1,1));
    return lerp(OutMin, OutMax, i);
}
inline float3 Remap(float4 InMin, float4 InMax, float3 OutMin, float3 OutMax, float4 Val)
{
    float i = length(InvLerp(InMin, InMax, Val))/length(float4(1,1,1,1));
    return lerp(OutMin, OutMax, i);
}
inline float4 Remap(float4 InMin, float4 InMax, float4 OutMin, float4 OutMax, float4 Val)
{
    return lerp(OutMin, OutMax, InvLerp(InMin, InMax, Val));
}

#if _SCREEN_DOOR_TEX
    sampler2D _DitherPattern;
    float4 _DitherPattern_TexelSize;
#else
    // Bayer Dither Pattern 8x8
    // static const half4 ditherArray[16] = {
    //     half4(.01,.75,.20,.94),half4(.06,.80,.25,.98),
    //     half4(.51,.26,.69,.45),half4(.55,.31,.74,.49),
    //     half4(.13,.88,.08,.82),half4(.18,.92,.12,.86),
    //     half4(.63,.38,.57,.32),half4(.68,.43,.62,.37),
    //     half4(.05,.78,.23,.97),half4(.03,.77,.22,.95),
    //     half4(.54,.29,.72,.48),half4(.52,.28,.71,.46),
    //     half4(.17,.91,.11,.85),half4(.15,.89,.09,.83),
    //     half4(.66,.42,.60,.35),half4(.65,.40,.58,.34)
    // };
    static const float4x4 thresholdMatrix =
    {
    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
    };
#endif

half _ScreenDoorAlpha;
half _ScreenDoorAlphaBias;

half applyScreenDoor(float4 screenPos, float colorAlpha)
{
    colorAlpha *= _ScreenDoorAlpha;
    // #if ! _SCREENDOORDEBUG_GRID
    //     if (colorAlpha == 1) return 1;
    // #endif
    screenPos.xy = screenPos.xy / screenPos.w; //[0,1]
    // #if _SCREEN_DOOR_TEX
    //     // external texture
    //     float2 ditherUV = screenPos.xy * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
    //     ditherUV = ditherUV;
    //     #if _SCREENDOORDEBUG_GRID
    //         ditherUV /= 5; //enlarge texture for debug
    //     #endif
    //     float dither = tex2D(_DitherPattern, ditherUV).r;
    // #else
        // 
        float2 ditherUV = screenPos.xy * _ScreenParams.xy; //[0,resolution]
        
        clip(colorAlpha - thresholdMatrix[ditherUV.x % 4][ditherUV.y % 4]);
        // #if _SCREENDOORDEBUG_GRID
            // ditherUV /= 5; //enlarge texture for debug
        // #endif
    //     ditherUV = fmod(trunc(ditherUV), 8);//[0,7]
    //     ditherUV.y = 7 - ditherUV.y; //flip y
    //     uint didx = ditherUV.y * 8 + ditherUV.x;
    //     half4 dither4 = ditherArray[trunc(didx/4)];
    //     didx = didx % 4;
    //     half dither = didx >= 3 ? dither4.w : didx >= 2 ? dither4.z : didx >= 1? dither4.y : dither4.x;
    // #endif
    // #if _SCREENDOORDEBUG_GRID
    //     return dither;
    // #else
        // clip(colorAlpha - max(dither, .0001));
        return 1;
    // #endif
}



#define APPLY_SCREENDOOR(o, colorAlpha) applyScreenDoor(o.screenPos, colorAlpha);
#define TRANSFER_SCREENDOOR(o, pos) o.screenPos = ComputeScreenPos(pos);
#define SCREENDOOR_COORDS(idx) float4 screenPos : TEXCOORD##idx;


float3 HSV2RGB(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}
float3 RGB2HSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

inline half3 LinearToGammaSpace (half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);

    // Exact version, useful for debugging.
    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));
}

inline half3 GammaToLinearSpace (half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}

float3 ColorContrast(float3 color, float contrast)
{
    color = LinearToGammaSpace(color);
    // color = pow(abs(color * 2.0 - 1.0), 1.0 / max(contrast, 0.0001)) * sign(color - 0.5) + 0.5;
    color = saturate(lerp(half3(0.5, 0.5, 0.5), color, contrast));
    color = GammaToLinearSpace(color);
    return color;
}

inline half Lumin(half3 col)
{
    return dot(col, half3(0.2126729f,  0.7151522f, 0.0721750f));
}

inline half AntiAliasingStep(half y, half x)
{
    half v = x - y;
    return saturate(v / fwidth(v));
}

inline float2 Rotate2D(float2 vec, float rad)
{
    float s, c;
    sincos(rad, s, c);
    float2x2 rotate = float2x2(float2(c, -s), float2(s, c));
    return mul(rotate, vec);
}

// 读取法线贴图，这里针对的是ba通道存取其它内容的法线贴图
inline half3 UnpackNormalCustom(half4 packednormal, float scale)
{
    half3 normal;
    normal.xy = (packednormal.xy * 2 - 1) * scale;
    normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
    return normal;
}
inline float Random1(float x)
{
    return frac(sin(x * 419.2)*43758.5453);
}
inline float2 Random2(float x)
{
    float2 q = float2(127.1, 269.5);
    return frac(sin(x * q) * 43758.5453);
}
inline float2 Random2(float2 xy)
{
    float2 q = float2(dot(xy, float2(127.1, 311.7)), 
                      dot(xy, float2(269.5, 183.3))); 
    return frac(sin(q) * 43758.5453);
}
inline float3 Random3(float x)
{
    float3 q = float3(127.1, 269.5, 419.2);
    return frac(sin(x * q) * 43758.5453);
}
inline float3 Random3(float2 xy)
{
    float3 q = float3(dot(xy, float2(127.1,311.7)), 
                      dot(xy, float2(269.5,183.3)),
                      dot(xy, float2(419.2,371.9)));
    return frac(sin(q)*43758.5453);
}

// 全屏三角形UV变换
float2 TransformTriangleVertexToUV(float2 vertex)
{
    float2 uv = (vertex + 1.0) * 0.5;
    return uv;
}

#endif
