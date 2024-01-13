// 潮湿地面效果
#ifndef WetLib_HLSL
#define WetLib_HLSL

// 常量定义
#define PI2 6.28318530718
#define HASHSCALE1 .1031
#define HASHSCALE3 half3(.1031, .1030, .0973)

sampler2D _WaterMask;   //水坑深度图
sampler2D _WaterNoiseMap;       // 水面扰动噪声图

half4 _WaterMask_ST;
half _FloodLevel1;      // 地板缝隙水位
half _FloodLevel2;      // 水坑水位
half _WetLevel;        // 潮湿程度
half _RainIntensity;    // 降雨强度
// 
// 涟漪相关参数
half _Density ;     //强度
half _SpreadSpd;    //涟漪扩散速度
half _WaveGap;      //涟漪宽度
half _WaveHei;      //涟漪高度
half _Tile;         //涟漪尺寸
half _WaterDistortStrength;    // 扰动强度
half _WaterDistortTimeScale;   // 扰动速度
half _WaterDistortScale;       // 扰动尺寸

//  1 out, 3 in...
float Hash13(float3 p3)
{
    p3  = frac(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

//  2 out, 1 in...
float2 Hash21(float p)
{
    float3 p3 = frac(p * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx+p3.yz)*p3.zy);
}

///  2 out, 3 in...
float2 Hash23(float3 p3)
{
    p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return frac((p3.xx+p3.yz)*p3.zy);
}

// 计算涟漪
// 核心公式 y = sin(31.*t) * smoothstep(-0.6, -0.3, t) * smoothstep(0., -0.3,t)
half _Ripple(half period,half spreadSpd,half waveGap,float2 uv,half rnd)
{
    const half CROSS_NUM = 1.0;
    half radius = (half(CROSS_NUM));
    half2 p0 = floor(uv);
    half sum = 0.;

    //多个格子中的波动全部累计起来,避免涟漪被分割
    for (half j = -CROSS_NUM; j <= CROSS_NUM; ++j){
        for (half i = -CROSS_NUM; i <= CROSS_NUM; ++i){
            half2 pi = p0 + half2(i, j);
            half2 h22 = Hash23(half3(pi,rnd));
            half h12 = Hash13(half3(pi,rnd));
            // 波峰个数设为2~3个
            half WAVE_NUM = 2. + round(h12);
            half ww = -WAVE_NUM * .5 * waveGap;
            half hww = ww * 0.5;
            half freq = WAVE_NUM * PI2 / waveGap/(CROSS_NUM + 1.);
            half pd = period*( h12 * 1.+ 1.);//让周期随机
            float time = _Time.y;//+pd*h12;//让时间偏移点  不会全部同时出现
            float t = fmod(time,pd);
            half spd = spreadSpd*((1.0-h12) * 0.2 + 0.8);//让传播速度随机
            half size = (h12)*0.4+0.6;
            half maxt = min(pd*0.6,radius *size /spd);
            half amp = saturate(1.- t/maxt);
            float2 p = pi +  Hash21(h12 + floor(time/pd)) * 0.4;
            half d = (length(p - uv) - spd*t)/radius * 0.5;
            sum -= amp*sin(freq*d) *  smoothstep(ww*size, hww*size, d) *  smoothstep(0., hww*size, d);//让波动传播开来
        }
    }
    sum /= (CROSS_NUM*2+1)*(CROSS_NUM*2+1);
    return sum;
}

// 分层计算涟漪
half Ripples(float2 uv ,half layerNum,half tileNum,half period,half spreadSpd,half waveGap)
{
    half sum = 0.;
    for(int i =0;i<layerNum;i++){
        sum += _Ripple(period,spreadSpd,waveGap,uv*(1.+i/layerNum ) * tileNum,half(i));
    }
    return sum ;
}

// 计算涟漪
half WaterMap(float3 pos)
{
    half h = Ripples(pos.xz,1.,1/_Tile,1/_Density,_SpreadSpd,_WaveGap)* _WaveHei * _Tile;
    return h;
}

half2 WaterDistort(float3 pos)
{
    float FrameTime = _WaterDistortTimeScale * _Time.y;
    float2 ofs_0 = float2(pos.x + pos.y, pos.z) * 0.048/_WaterDistortScale + float2(-0.022, 0.0273) * FrameTime;
    float2 ofs_1 = float2(pos.x, pos.y + pos.z) * 0.038/_WaterDistortScale - float2(-0.033, 0.0184) * FrameTime;
    half2 sample_res_0 = tex2D(_WaterNoiseMap, ofs_0).rg * 2.0 - 1.0;
    half2 sample_res_1 = tex2D(_WaterNoiseMap, ofs_1).rg * 2.0 - 1.0;
    half2 nor_ofs = sample_res_0 * sample_res_1 * 0.9 * _WaterDistortStrength;
    return nor_ofs;
}

// 地板水面法线计算，融合了涟漪
half3 WaterNormal(float3 pos)
{
    half EPSILON = 0.001;
    half3 dx = half3(EPSILON, 0, 0);
    half3 dz = half3(0, 0, EPSILON);
    
    half3 normal = half3(0, 1, 0);
    half bumpfactor = 0.2;//根据距离所见Bump幅度
    half2 nor_ofs = WaterDistort(pos);
    // 计算扰动噪声
    // 扰动和涟漪结合
    normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON) + nor_ofs.x;
    normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON) + nor_ofs.y;
    return normalize(normal);	
}

void DoWetSetup(inout half diffuseScale, inout half gloss, float3 worldPos, inout half3 worldNormal, half3 lightColor, inout half3 emission)
{
    // 取当前像素点最接近水的系数
    half AccumulatedWater = max(_FloodLevel1, _FloodLevel2);
    
    // 设置潮湿地面的潮湿度。越潮湿，漫反射越弱，高光的光泽度越强
    diffuseScale *= lerp(1.0, 0.3, _WetLevel);
    gloss = min(gloss * lerp(1.0, 2.5, _WetLevel), 1.0);
    // 涟漪法线
    half3 RippleNormal = WaterNormal(worldPos);
    // 给涟漪添加自发光
    emission += lightColor * saturate(WaterMap(worldPos)) * _RainIntensity * 0.5 / pow(_Tile, 1.5);
    // 水面和涟漪混合
    half3 waterNormal = lerp(half3(0, 1, 0), RippleNormal, saturate(_RainIntensity));
    // 计算世界坐标系下的normal、lightDir、viewDir、H
    half3 N = lerp(worldNormal, waterNormal, AccumulatedWater); 
    // 修改后续光照的法线
    worldNormal = N;
}
#endif