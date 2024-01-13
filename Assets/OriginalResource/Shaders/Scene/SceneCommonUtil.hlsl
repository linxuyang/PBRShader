#ifndef _MC_SCENE_COMMON_HLSL
#define _MC_SCENE_COMMON_HLSL

// 点阵半透明矩阵
static const float4x4 thresholdMatrix =
{
    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
};

// 应用点阵半透明
void ScreenDitherClip(half2 screenUV, half alpha)
{
    #if _SCREEN_DOOR_ON
    half2 ditherUV = screenUV * _ScreenParams.xy;
    ditherUV = ditherUV % 4;
    clip(alpha - thresholdMatrix[ditherUV.x][ditherUV.y]);
    #endif
}

#endif
