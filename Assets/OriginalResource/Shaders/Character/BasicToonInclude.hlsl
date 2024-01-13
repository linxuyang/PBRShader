#ifndef _BASIC_TOON_INCLUDE
#define _BASIC_TOON_INCLUDE

float2 GetRimDir()
{
    // 这里取的是世界空间下摄像机的正面朝向
    float3 worldViewDir = UNITY_MATRIX_V[2].xyz;
    // 先把视角方向调成水平(忽略Y轴)
    float3 rimDir = normalize(float3(worldViewDir.x, 0, worldViewDir.z));
    // 然后计算出与水平面上与视角方向垂直的边缘光方向(利用叉乘原理)
    rimDir = cross(half3(0, 1, 0), rimDir);
    return rimDir.xz;
}
    
half ToonStyleRim(half rim, half step, half feather)
{
    return saturate((rim - 1 + step + feather) / feather);
}

struct RimData
{
    half mask;
    half3 albedo;
    half ao;
    half metallic;
    half3 normal;
    half3 view;
    half2 rimDirXZ;
    half rimPermeation;
    half rimWidth;
    half rimPower;
    half3 rimColor;
    half rimDiffuseBlend;
    half toonRimStep;
    half toonRimFeather;
};

half3 RimColor(RimData data)
{
    half3 rimDir = normalize(half3(data.rimDirXZ.x, 0, data.rimDirXZ.y));
    // 边缘光的方向加上20°的水平倾角
    rimDir *= 0.940; // XZ轴的分量 × Cos(20°)
    rimDir.y = 0.342; // Y轴的分量 = Sin(20°)
    half nDotV = saturate(dot(data.normal, data.view));
    half nDotR = saturate((dot(data.normal, rimDir) + data.rimPermeation) / (1 + data.rimPermeation));
    float rim = nDotR * smoothstep(1 - data.rimWidth, 1, 1 - nDotV);
    rim = lerp(rim, 0.04, data.metallic) * data.ao;
#if _TOON_RIM
    rim = ToonStyleRim(rim, data.toonRimStep, data.toonRimFeather);
#endif
    half3 rimColor = data.mask * rim * data.rimPower * data.rimColor;
    rimColor = lerp(rimColor, rimColor * data.albedo, data.rimDiffuseBlend);
    return rimColor;
}

half4 CaclulateDyeSwitchAndIntensity(half3 dyeMask)
{
    half dyeSwitchR = 1 - step(dyeMask.r, 0.01);
    // 当染色R通道生效时, 覆盖G通道, 因此dyeMask.g - dyeSwitchR
    // 其它染色通道同理
    half dyeSwitchG = 1 - step(dyeMask.g - dyeSwitchR, 0.01);
    half dyeSwitchB = 1 - step(dyeMask.b - dyeSwitchR - dyeSwitchG, 0.01);
    half intensity = dyeMask.r * dyeSwitchR + dyeMask.g * dyeSwitchG + dyeMask.b * dyeSwitchB;
    return half4(dyeSwitchR, dyeSwitchG, dyeSwitchB, intensity);
}

void DyeColor(half toggle, sampler2D flowMaskTex, inout half3 color, half2 uv, half3 offset1, half3 offset2, half3 offset3)
{
    [branch]if(toggle == 1)
    {
        half3 dyeMask = tex2D(flowMaskTex, uv).rgb;
        half4 dyeSwitchAndIntensity = CaclulateDyeSwitchAndIntensity(dyeMask);
        half intensity = dyeSwitchAndIntensity.a;
        half3 offsetHSV = offset1 * dyeSwitchAndIntensity.r + offset2 * dyeSwitchAndIntensity.g + offset3 * dyeSwitchAndIntensity.b;
    
        half3 hsv = RgbToHsv(color);
        hsv.x = offsetHSV.x;
        hsv.y = saturate(hsv.y + offsetHSV.y);
        hsv.z = saturate(hsv.z + offsetHSV.z);
        color = lerp(color, HsvToRgb(hsv), intensity);
    }
}

struct DyeTransitionData
{
    half2 screenUV;
    half3 offset1;
    half3 offset2;
    half3 offset3;
    half3 offsetFrom1;
    half3 offsetFrom2;
    half3 offsetFrom3;
    half dyePercent;
    half dyeTrasitionWidth;
    half dyeFireWidth;
    half toIsOrigin;
    half fromIsOrigin;
    half3 dyeTransitionColor;
    half3 dyeTransitionColor2;
};

void DyeTransition(half toggle, sampler2D flowMaskTex, sampler2D dyeNoiseTex, inout half3 color, half2 uv, DyeTransitionData data)
{
    [branch]if(toggle == 2)
    {
        half3 dyeMask = tex2D(flowMaskTex, uv).rgb;
        half4 dyeSwitchAndIntensity = CaclulateDyeSwitchAndIntensity(dyeMask);
        half intensity = dyeSwitchAndIntensity.a;
        half3 offsetHSV = data.offset1 * dyeSwitchAndIntensity.r + data.offset2 * dyeSwitchAndIntensity.g + data.offset3 * dyeSwitchAndIntensity.b;
        half3 offsetFromHSV = data.offsetFrom1 * dyeSwitchAndIntensity.r + data.offsetFrom2 * dyeSwitchAndIntensity.g + data.offsetFrom3 * dyeSwitchAndIntensity.b;

        half3 hsv = RgbToHsv(color);
        half3 hsvFrom = hsv;
        hsv.x = offsetHSV.x;
        hsv.y = saturate(hsv.y + offsetHSV.y);
        hsv.z = saturate(hsv.z + offsetHSV.z);
        hsvFrom.x = offsetFromHSV.x;
        hsvFrom.y = saturate(hsvFrom.y + offsetFromHSV.y);
        hsvFrom.z = saturate(hsvFrom.z + offsetFromHSV.z);

        half percent = smoothstep(data.dyePercent, data.dyePercent + data.dyeTrasitionWidth, 1 - data.screenUV.y);
        half fire = (data.screenUV.y + data.dyePercent - 1) / data.dyeTrasitionWidth;
        // 使用屏幕空间水平uv和世界坐标高度
        uv = data.screenUV;
        uv.x *= data.dyeFireWidth;
        half4 distort = tex2D(dyeNoiseTex, uv) * 0.063;
        //使用扭曲纹理来取样噪音纹理
        half tx = fmod(_Time.x, 100.0);
        half noise = tex2D(dyeNoiseTex, half2(uv.x * 2 + tx + distort.g, 2 * (uv.y - tx) + distort.r)).r;
        noise *= 0.6;
        half w = step(0, 1 - data.screenUV.y - data.dyePercent);
        fire *= lerp(0.4, 1, w);
        fire = saturate(1 - abs(fire + noise) - noise);
        half pow5 = saturate(Pow5(fire)) * 16;
        half3 targetCol = lerp(HsvToRgb(hsv), color, data.toIsOrigin);
        half3 fromCol = lerp(HsvToRgb(hsvFrom), color, data.fromIsOrigin);
        half3 transition = lerp(targetCol, fromCol, percent);
        color = lerp(color, transition, intensity) + pow5 * data.dyeTransitionColor + fire * data.dyeTransitionColor2;
    }
}

half3 FlowLight(half2 maskUV, half4 flowUV, sampler2D dyeFlowMaskTex, sampler2D flowLightTex, half blinkTile,
    half blinkSpeed, half4 flowParam1, half4 flowParam2, half3 flowColor1, half3 flowColor2, half3 blinkColor)
{
    half tx = fmod(_Time.x, 100);
    half maskA = tex2D(dyeFlowMaskTex, maskUV).a; 
    half flowCol1 = tex2D(flowLightTex, flowUV.xy).r;
    half flowCol2 = tex2D(flowLightTex, flowUV.zw).g;
    half blinCol = tex2D(flowLightTex, maskUV * blinkTile * 0.97 + tx * blinkSpeed).b;
    blinCol = clamp(blinCol * tex2D(flowLightTex, maskUV * blinkTile - tx * blinkSpeed).b * 200, 0, 2);
    half3 tempCol = flowCol1 * flowParam1.w * flowColor1;
    tempCol += flowCol2 * flowParam2.w * flowColor2;
    tempCol += blinCol * blinkColor;
    return tempCol * maskA;
}

// 漫反射
half3 RendererDiffuse(half3 albedo, half nDotL, half3 shadowColor, half3 shadowColor1, half3 shadowColor2, half toonStep,
    half toonStep2, half toonFeather, half toonFeather2)
{
    half3 shadow1 = shadowColor * shadowColor1;
    half3 shadow2 = shadowColor * shadowColor2;
    shadow2 = CalcToonColor(shadow1, shadow2, nDotL, toonStep2, toonFeather2);
    return CalcToonColor(albedo, shadow2, nDotL, toonStep , toonFeather);
}

struct MatcapData
{
    half3 albedo;
    half2 matcapMask;
    half3 normalWS;
    half roughness;
    half pixelWidth;
    sampler2D matcapTex;
    half2 matcapIndexs;
    half matcap1ColorDiffuseToggle;
    half matcap1RoughnessToggle;
    half3 matcapColor1;
    half matcap1Scale;
    half matcap1Power;
    half matcap2ColorDiffuseToggle;
    half matcap2RoughnessToggle;
    half3 matcapColor2;
    half matcap2Scale;
    half matcap2Power;
};

half3 MatcapColor(MatcapData matcapData)
{
    half2 normalVS = TransformWorldToViewDir(matcapData.normalWS).xy;
    normalVS = normalVS * 0.5 + 0.5;
    normalVS *= 0.25 - 2 * matcapData.pixelWidth;
    half4 offset = 0;
    offset.yw = floor(matcapData.matcapIndexs / 4);
    offset.xz = matcapData.matcapIndexs - offset.yw * 4;
    offset.yw = 3 - offset.yw;
    offset = offset * 0.25 + matcapData.pixelWidth;
    
    half3 matcap = tex2D(matcapData.matcapTex, normalVS + offset.xy).rgb;
    matcap *= matcapData.matcapColor1 * matcapData.matcap1Power;
    matcap *= lerp(half3(1, 1, 1), matcapData.albedo, matcapData.matcap1ColorDiffuseToggle);
    half3 matcap1 = matcap * matcapData.matcapMask.x * matcapData.matcap1Scale;
    matcap1 *= 1 - matcapData.roughness * matcapData.matcap1RoughnessToggle;
    
#if _MATCAP2_ON
    matcap = tex2D(matcapData.matcapTex, normalVS + offset.zw).rgb;
    matcap *= matcapData.matcapColor2 * matcapData.matcap2Power;
    matcap *= lerp(half3(1, 1, 1), matcapData.albedo, matcapData.matcap2ColorDiffuseToggle);
                
    half3 matcap2 = matcap * matcapData.matcapMask.y * matcapData.matcap2Scale;
    matcap2 *= 1 - matcapData.roughness * matcapData.matcap2RoughnessToggle;
    matcap1 += matcap2;
#endif
            
    return matcap1;
}

half3 NormalSpeculr(half3 albedo, half metallicRaw, half mask, half roughness, half3 normal, half3 lightDir, half3 halfVector)
{
    half3 specColor = lerp(float3(1, 1, 1), albedo, metallicRaw);
    half nDotL = saturate(dot(normal, lightDir));
    float nDotH = saturate(dot(normal, halfVector));
    float lDotN = saturate(dot(lightDir, halfVector));
    
    half roughnessSquare = roughness * roughness;
    half roughnessPow4 = roughnessSquare * roughnessSquare;
    half d = nDotH * nDotH * (roughnessPow4 - 1) + 1.00001;
    half specularTerm = roughnessPow4 / (max(0.1, lDotN * lDotN) * (roughnessSquare + 0.5) * (d * d) * 4);
    specularTerm -= 0.0001;
    specularTerm = clamp(specularTerm, 0.0, 100.0);
    return specularTerm * specColor * nDotL * mask;
}

struct BasicToonVertexInput
{
    float3 positionOS : POSITION;
    half2 texcoord : TEXCOORD0;
    half4 color : COLOR;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
};

// 描边着色器 begin
struct OutlineVertexInput
{
    float4 positionOS : POSITION;
    half3 normalOS : NORMAL;
    half4 color : COLOR;
    half2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
    
struct OutlineVertexOutput
{
    float4 positionCS : SV_POSITION;
    half2 uv : TEXCOORD0;
    half fogCoord : TEXCOORD1;
    UNITY_VERTEX_OUTPUT_STEREO
};
// 描边着色器 end

#endif
