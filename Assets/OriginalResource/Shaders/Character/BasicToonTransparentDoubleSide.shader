Shader "MC/Character/Toon/BasicToonTransparentDoubleSide"
{
    Properties 
    {
        [Header(Basics)]
        [HDR]_Color("叠加色(RGB)", Color) = (1, 1, 1, 1)
        _MainTex("固有色(RGBA)", 2D) = "white" {}
        _ShadowTex("暗面叠加色(RGB)", 2D) = "grey" {}
        [Toggle(_SHADOWTEX_ON)]_ShadowSelfToggle("暗部使用贴图", float) = 0
        [HideInInspector]
        _AlphaScale("透明系数", Range(0, 1)) = 1
        [Space]
        [Header(Shading)]
        _ToonStep("明暗线位置", Range(0, 1)) = .5
        _ToonFeather("羽化", Range(0, 1)) = 0
        [HDR]_ShadowColor1("暗部颜色(RGBA)", Color) = (1, 1, 1, 1)
        _ToonStep2("明暗线位置2", Range(0, 1)) = .5
        _ToonFeather2("羽化2", Range(0, 1)) = 0
        [HDR]_ShadowColor2("暗部颜色2(RGBA)", Color) = (0.5, 0.5, 0.5, 1)
        [Toggle]_SkinToggle("皮肤光照", Float) = 0
        [Space]
        [Header(Specular)]
        [Toggle(_SPECULAR_ON)]_SpecularToggle(":: 启用高光", Float) = 0
        _SpecPower("强度", Range(0, 10)) = 1
        [Space]
        [Header(Normals)]
        [Toggle(_NORMAL_ON)]_BumpMapToggle(":: 启用法线贴图(RG为法线, BA为matcap遮罩)", Float) = 0
        _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("强度", Range(0, 2)) = 1
        [Space]
        [Header(ILM Mixed Map)]
        [NoScaleOffset]_ILMTex("ILM(RGBA) : 粗糙度, AO, 金属度, 自发光", 2D) = "black" {}
        _MetallicLevel("金属度系数", Range(0, 1)) = 1 
        _RoughnessLevel("粗糙度系数", Range(0, 2)) = 1 
        _AOLevel("AO系数", Range(0, 1)) = 1 
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色(RGB)", Color) = (1, 1, 1, 1)
        _EmissionPower("强度", Range(0, 2)) = 1
        [Space]
        [Header(Rim Light)]
        //边缘光
        [Toggle(_RIM_ON)]_RimToggle(":: 启用边缘光", Float) = 0
        _RimWidth("边缘光宽度", Range(0, 1)) = .5
        _RimPower("强度", Range(0, 3)) = 1
        _RimPermeation("边缘光向暗面延申", Range(0, 1)) = 0
        [Space]
        [HDR]_RimColor("边缘光颜色(RGB)", Color) = (1, 1, 1, 1)
        _RimDiffuseBlend("叠加多少固有色", Range(0, 1)) = 1
        [Space]
        //卡通风格的边缘光
        [Toggle(_TOON_RIM)]_ToonRimToggle(":: 使用卡通风格边缘光", Float) = 0
        _ToonRimStep("阈值", Range(0, 1)) = .2
        _ToonRimFeather("羽化", Range(0, 1)) = 0
        [Space]
        [Header(Outlines)]
        //外描边(法线外扩)
        [Toggle(_OL_ON)]_OutlineToggle(":: 启用描边", Float) = 0
        _OutlineColor("描边叠加色", Color) = (1, 1, 1, 1)
        _Outline("描边宽度", Range(0.001, 1)) = 0
        _OutlineZBias("描边Z偏移", Float) = 0
        _OutlineDispearDistance("描边消失距离", Range(1, 5)) = 1
        [Space]
        [Header(MatCap)]
        [Space(10)]
        [NoScaleOffset]_MatcapTex1("MatCap 纹理(RGB)", 2D) = "white" {}
        _Matcap1Scale("效果强度", Range(0, 1)) = 0
        [Toggle]_Matcap1ColorDiffuseToggle(":: 叠加固有色", Float) = 0
        [Toggle]_Matcap1RoughnessToggle(":: 粗糙的地方减弱", Float) = 0
        [HDR]_MatcapColor1("纹理叠加色(RGB)", Color) = (1, 1, 1, 1)
        _Matcap1Power("纹理强度", Range(0, 3)) = 1
        _Matcap1Index("MatCap纹理是第几张(0~15 从左至右 从上到下)", float) = 0
        [Space]
        [Toggle(_MATCAP2_ON)]_Matcap2Toggle(":: 启用Matcap 2区(Mask: G)", Float) = 0
        _Matcap2Scale("效果强度", Range(0, 1)) = 0
        [Toggle]_Matcap2ColorDiffuseToggle(":: 叠加固有色", Float) = 0
        [Toggle]_Matcap2RoughnessToggle(":: 粗糙的地方减弱", Float) = 0
        [HDR]_MatcapColor2("纹理叠加色(RGB)", Color) = (1, 1, 1, 1)
        _Matcap2Power("纹理强度", Range(0, 3)) = 1
        _Matcap2Index("MatCap纹理是第几张(0~15 从左至右 从上到下)", float) = 1
        [Space]
        [Header(DyeFlowMask)]
        _DyeFlowMask("染色/流光遮罩(rgb染色、a流光)", 2D) = "white" {}
        [Space]
        [Header(Dye)]
        [Enum(Off, 0, On, 1, Transition, 2)]_Dye("染色开关", Float) = 0
        [Space]
        [Toggle]_ToIsOrigin("切换目标是原色？", Float) = 0
        [DyeColor]_Offset1("染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset2("染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset3("染色B", Vector) = (0, 0, 0, 0)
        [Space]
        [Toggle]_FromIsOrigin("切换源是原色？", Float) = 0
        [DyeColor]_OffsetFrom1("源染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_OffsetFrom2("源染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_OffsetFrom3("源染色B", Vector) = (0, 0, 0, 0)
        _DyeOffset("染色渐变竖直偏移", Float)=0
        _DyeScale("1/染色渐变高度", Range(0, 1))=0.5
        _DyePercent("染色渐变百分比", Range(0, 1)) = 1
        _DyeTrasitionWidth("染色渐变间隔", Range(0.001, 0.2)) = 0.02
        _DyeFireWidth("染色渐变火焰水平缩放", Range(0.25, 2)) = 0.5
        [HDR]_DyeTransitionColor("染色渐变内层颜色", Color) = (0.6320754, 0.425409, 0.02087043, 0)
        [HDR]_DyeTransitionColor2("染色渐变外层颜色", Color) = (1, 0, 0.5450983, 0)
        _DyeNoiseTex("渐变噪声", 2D) = "white" {}
        [Space]
        [Header(Flow Color)]
        //流光开启与否。只有=1才会开启
        [Toggle(_FLOW_ON)]_FlowAbleToggle(":: 启用流光", Float) = 0
        //流光 改版
        _FlowLightTex("流光贴图(RGBA)", 2D) = "white" {}
        [HDR]_FlowColor1("流光颜色1(RGBA)", Color) = (.5, .5, .5, 1)
        [HDR]_FlowColor2("流光颜色2(RGBA)", Color) = (.5, .5, .5, 1)
        _FlowParam1("流光参数(u方向、v方向、tile、亮度)", Vector) = (1, 1, 1, 1)
        _FlowParam2("流光参数(u方向、v方向、tile、亮度)", Vector) = (1, 1, 1, 1)
        [HDR]_BlinkColor("闪光颜色", Color) = (1, 1, 1, 1)
        _BlinkTile("闪光尺寸", Range(0.1, 3)) = 1
        _BlinkSpeed("闪光速度", Range(0, 0.2)) = 1
        
        [HideInInspector][Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("模板操作", float) = 0
        [HideInInspector]_StencilVal("模板值", float) = 2
        [HideInInspector]_SrcAlphaBlend("__srcAlpha", Float) = 1.0
        [HideInInspector]_DstAlphaBlend("__dstAlpha", Float) = 0.0
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../CommonInclude.hlsl"
    #include "BasicToonInclude.hlsl"
    
    sampler2D _MainTex;
    sampler2D _NormalTex;
    sampler2D _FlowLightTex;
    sampler2D _DyeFlowMask; //染色遮罩
    sampler2D _DyeNoiseTex;
    sampler2D _ILMTex;
    sampler2D _MatcapTex1;
    sampler2D _ShadowTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _FlowLightTex_ST;
    
    half4 _Color;
    half _AlphaScale;
    half _NormalScale;
    
    half3 _ShadowColor1, _ShadowColor2;
    half _ToonStep, _ToonStep2;
    half _ToonFeather, _ToonFeather2;
    half _SkinToggle;
    
    half4 _MatcapTex1_TexelSize;
    half _Matcap1ColorDiffuseToggle, _Matcap1RoughnessToggle, _Matcap2ColorDiffuseToggle, _Matcap2RoughnessToggle;
    half3 _MatcapColor1;
    half _Matcap1Scale;
    half _Matcap1Power;
    half _Matcap1Index;
    half _Matcap2Index;
    half3 _MatcapColor2;
    half _Matcap2Scale;
    half _Matcap2Power;
    
    half _SpecPower;
    
    half3 _EmissionColor;
    half _EmissionPower;
    
    half _RimWidth, _RimPower, _RimPermeation;
    half _ToonRimStep, _ToonRimFeather;
    half3 _RimColor;
    half _RimDiffuseBlend;
    
    half3 _FlowColor1, _FlowColor2, _BlinkColor;
    half4 _FlowParam1, _FlowParam2;
    half _BlinkTile, _BlinkSpeed;
    
    half _Dye;
    half _ToIsOrigin, _FromIsOrigin;
    half3 _Offset1, _Offset2, _Offset3;
    half3 _OffsetFrom1, _OffsetFrom2, _OffsetFrom3;
    half _DyeOffset, _DyeScale, _DyePercent, _DyeTrasitionWidth;
    half _DyeFireWidth;
    half3 _DyeTransitionColor, _DyeTransitionColor2;
    
    half _MetallicLevel, _RoughnessLevel, _AOLevel;
    
    half _Outline;
    half3 _OutlineColor;
    half _OutlineZBias;
    CBUFFER_END

    OutlineVertexOutput OutlineVertex(OutlineVertexInput input)
    {
        OutlineVertexOutput output = (OutlineVertexOutput)0;
        UNITY_SETUP_INSTANCE_ID(input);
    
        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        output.positionCS = vertexInput.positionCS;
    #if _OL_ON
        half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
        half3 normalCS = TransformWorldToHClipDir(normalWS);
        output.positionCS.xy += normalCS.xy * _Outline * 0.04 * input.color.a;
        half bias = lerp(-0.001, 0.0005, UNITY_REVERSED_Z) * _OutlineZBias * output.positionCS.w;
        output.positionCS.z += bias;
        output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
        output.fogCoord = ComputeFogFactor(output.positionCS.z);
    #endif
        return output;
    }
    
    half4 OutlineFragment(OutlineVertexOutput i) : SV_Target
    {
    #if !_OL_ON
        clip(-1);
    #endif
        half3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
        half4 color = half4(_OutlineColor * albedo, _AlphaScale);
        color.rgb = MixFog(color.rgb, i.fogCoord);
        return color;
    }
    // 描边着色器 end

    struct VertexOutput
    {
        float4 positionCS : SV_POSITION;
        float4 uvAndScreenUV : TEXCOORD0; // xy: MainTex uv; zw: screenUV
        half4 fogFactorAndVertexSH : TEXCOORD1;
    #if _NORMAL_ON
        half4 normalWS : TEXCOORD2; // xyz:法线(世界); w:观察方向(世界).x
        half4 tangentWS : TEXCOORD3; // xyz:切线(世界); w:观察方向(世界).y
        half4 bitangentWS : TEXCOORD4; // xyz:副切线(世界); w:观察方向(世界).z
    #else
        half3 normalWS : TEXCOORD2;
        half3 viewDirWS : TEXCOORD3;
    #endif
    #if _RIM_ON
        half3 rimMaskAndRimDir : TEXCOORD6;
    #endif
    #if _FLOW_ON
        half4 flowUV : TEXCOORD7;
    #endif
        float3 positionWS : TEXCOORD8;
    };

    VertexOutput Vertex(BasicToonVertexInput input)
    {
        VertexOutput output = (VertexOutput)0;
        float3 positionWS = TransformObjectToWorld(input.positionOS);
        output.positionWS = positionWS;
        output.positionCS = TransformWorldToHClip(positionWS);
        output.uvAndScreenUV.xy = TRANSFORM_TEX(input.texcoord, _MainTex);

        half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
    #if _NORMAL_ON
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
    #else
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
        output.normalWS = normalInput.normalWS;
        output.viewDirWS = viewDirWS;
    #endif

        output.fogFactorAndVertexSH.x = ComputeFogFactor(output.positionCS.z);
        half3 vertexSH = SampleSH(normalInput.normalWS);
        //将gi转成亮度
        half luminance = LinearColorToLuminance(vertexSH);
        //将亮度值限定在一定范围内，0.3是一个魔法数字，凭感觉调出来的，不一定准确
        luminance = clamp(luminance, 0, 0.3);
        output.fogFactorAndVertexSH.yzw = luminance * vertexSH;
        
        // 流光特效
    #if _FLOW_ON
        half2 flowUV = TRANSFORM_TEX(input.texcoord, _FlowLightTex);
        half tx = fmod(_Time.x, 100.0);
        output.flowUV.xy = flowUV * _FlowParam1.z + tx * _FlowParam1.xy;
        output.flowUV.zw = flowUV * _FlowParam2.z + tx * _FlowParam2.xy;
    #endif

        float4 screenPos = ComputeScreenPos(output.positionCS);
        screenPos.xy /= screenPos.w;
        screenPos.y = positionWS.y * _DyeScale - _DyeOffset;
        output.uvAndScreenUV.zw = screenPos.xy;
    
    #if _RIM_ON
        output.rimMaskAndRimDir.x = input.color.g;
        output.rimMaskAndRimDir.yz = GetRimDir();
    #endif

        return output;
    }

    half4 Albedo(VertexOutput input)
    {
        half4 albedo = tex2D(_MainTex, input.uvAndScreenUV.xy) * _Color;
        DyeColor(_Dye, _DyeFlowMask, albedo.rgb, input.uvAndScreenUV.xy, _Offset1, _Offset2, _Offset3);
        DyeTransitionData dyeTransitionData;
        dyeTransitionData.screenUV = input.uvAndScreenUV.zw;
        dyeTransitionData.offset1 = _Offset1;
        dyeTransitionData.offset2 = _Offset2;
        dyeTransitionData.offset3 = _Offset3;
        dyeTransitionData.offsetFrom1 = _OffsetFrom1;
        dyeTransitionData.offsetFrom2 = _OffsetFrom2;
        dyeTransitionData.offsetFrom3 = _OffsetFrom3;
        dyeTransitionData.dyePercent = _DyePercent;
        dyeTransitionData.dyeTrasitionWidth = _DyeTrasitionWidth;
        dyeTransitionData.dyeFireWidth = _DyeFireWidth;
        dyeTransitionData.toIsOrigin = _ToIsOrigin;
        dyeTransitionData.fromIsOrigin = _FromIsOrigin;
        dyeTransitionData.dyeTransitionColor = _DyeTransitionColor;
        dyeTransitionData.dyeTransitionColor2 = _DyeTransitionColor2;
        DyeTransition(_Dye, _DyeFlowMask, _DyeNoiseTex, albedo.rgb, input.uvAndScreenUV.xy, dyeTransitionData);
        return albedo;
    }

    void GetIlmTexVal(half2 uv, out half roughness, out half ao, out half metallic, out half emissive)
    {
        half4 ilm = tex2D(_ILMTex, uv);
        roughness = saturate(ilm.r * _RoughnessLevel);
        ao = lerp(1, ilm.g, _AOLevel);
        metallic = saturate(ilm.b * _MetallicLevel);
        emissive = ilm.a;
    }

    void InitNormalAndViewDir(VertexOutput input, half4 normalTexVal, out half3 normalWS, out half3 viewDirWS)
    {
    #if _NORMAL_ON
        viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
        half3 normalTS = UnpackCustomNormal(normalTexVal, _NormalScale);
        normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, 
            input.bitangentWS.xyz, input.normalWS.xyz));
        normalWS = normalize(normalWS);
    #else
        viewDirWS = SafeNormalize(input.viewDirWS);
        normalWS = normalize(input.normalWS.xyz);
    #endif
    }

    half3 RenderWithDiffuseAndSHAndRim(Light mainLight, half3 normalWS, half3 viewDirWS, half3 albedo, VertexOutput input, half ao, half metallic)
    {
        half nDotL = saturate(dot(normalWS, mainLight.direction)) * 0.5 + 0.5;
        half nDotV = saturate(dot(normalWS, viewDirWS));
        half diff = lerp(nDotL, nDotV, _SkinToggle);

    #ifdef _SHADOWTEX_ON
        half3 shadowColor = albedo.rgb * tex2D(_ShadowTex, input.uvAndScreenUV.xy).rgb;
    #else
        half3 shadowColor = albedo.rgb * albedo.rgb;
    #endif
        half3 col = RendererDiffuse(albedo.rgb, diff, shadowColor, _ShadowColor1, _ShadowColor2, _ToonStep, _ToonStep2,
            _ToonFeather, _ToonFeather2) * mainLight.color;

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, input.positionWS);
            nDotL = saturate(dot(normalWS, light.direction)) * 0.5 + 0.5;
            diff = lerp(nDotL, nDotV, _SkinToggle);
            col += RendererDiffuse(albedo.rgb, diff, shadowColor, _ShadowColor1, _ShadowColor2, _ToonStep, _ToonStep2,
                _ToonFeather, _ToonFeather2) * light.color;
        }
        
        // 间接光
        col += albedo.rgb * input.fogFactorAndVertexSH.yzw * ao;
    #if _RIM_ON
        RimData rimData;
        rimData.mask = input.rimMaskAndRimDir.x;
        rimData.albedo = albedo.rgb;
        rimData.ao = ao;
        rimData.metallic = metallic;
        rimData.normal = normalWS;
        rimData.view = viewDirWS;
        rimData.rimDirXZ = input.rimMaskAndRimDir.yz;
        rimData.rimPermeation = _RimPermeation;
        rimData.rimWidth = _RimWidth;
        rimData.rimPower = _RimPower;
        rimData.rimColor = _RimColor;
        rimData.rimDiffuseBlend = _RimDiffuseBlend;
        rimData.toonRimStep = _ToonRimStep;
        rimData.toonRimFeather = _ToonRimFeather;
        half3 rimCol = RimColor(rimData);
        col += rimCol * mainLight.color;
    #endif
        return col;
    }

    void RenderWithSpecular(inout half3 col, half metallic, Light mainLight, half3 viewDirWS, half3 albedo, half roughness, half3 normalWS, float3 positionWS)
    {
    #if _SPECULAR_ON
        half specMask = max(0.01, metallic);
        half3 halfVector = SafeNormalize(float3(mainLight.direction) + float3(viewDirWS));
        half3 specColor = NormalSpeculr(albedo.rgb, metallic, specMask, roughness, normalWS, mainLight.direction, halfVector);
        specColor *= mainLight.color * _SpecPower;

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, positionWS);
            SafeNormalize(float3(light.direction) + float3(viewDirWS));
            specColor += NormalSpeculr(albedo.rgb, metallic, specMask, roughness, normalWS, light.direction, halfVector) * light.color * _SpecPower;
        }
        
        col = lerp(col + specColor, specColor, metallic);
    #endif
    }

    void RenderWithEmissionFlowFog(inout half3 col, half3 albedo, half emissive, VertexOutput input)
    {
    #if _EMISSION_ON
        col += albedo.rgb * emissive * _EmissionColor * _EmissionPower;
    #endif
        
    #if _FLOW_ON
        col += FlowLight(input.uvAndScreenUV.xy, input.flowUV, _DyeFlowMask, _FlowLightTex, _BlinkTile, _BlinkSpeed,
            _FlowParam1, _FlowParam2, _FlowColor1, _FlowColor2, _BlinkColor);
    #endif
 
        col = MixFog(col, input.fogFactorAndVertexSH.x);
    }

    half4 Fragment(VertexOutput input) : SV_Target
    {
        half4 albedo = Albedo(input);

        half roughness, ao, metallic, emissive;
        GetIlmTexVal(input.uvAndScreenUV.xy, roughness, ao, metallic, emissive);

        // 获取主光源
        Light mainLight = GetMainLight();
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;
        half4 normalTexVal = tex2D(_NormalTex, input.uvAndScreenUV.xy);
        
        half3 viewDirWS, normalWS;
        InitNormalAndViewDir(input, normalTexVal, normalWS, viewDirWS);

        half3 col = RenderWithDiffuseAndSHAndRim(mainLight, normalWS, viewDirWS, albedo.rgb, input, ao, metallic);

        MatcapData matcapData;
        matcapData.albedo = col;
        matcapData.matcapMask = normalTexVal.ba;
        matcapData.normalWS = normalWS;
        matcapData.roughness = roughness;
        matcapData.pixelWidth = _MatcapTex1_TexelSize.x;
        matcapData.matcapTex = _MatcapTex1;
        matcapData.matcapIndexs = half2(_Matcap1Index, _Matcap2Index);
        matcapData.matcap1ColorDiffuseToggle = _Matcap1ColorDiffuseToggle;
        matcapData.matcap1RoughnessToggle = _Matcap1RoughnessToggle;
        matcapData.matcapColor1 = _MatcapColor1;
        matcapData.matcap1Scale = _Matcap1Scale;
        matcapData.matcap1Power = _Matcap1Power;
        matcapData.matcap2ColorDiffuseToggle = _Matcap2ColorDiffuseToggle;
        matcapData.matcap2RoughnessToggle = _Matcap2RoughnessToggle;
        matcapData.matcapColor2 = _MatcapColor2;
        matcapData.matcap2Scale = _Matcap2Scale;
        matcapData.matcap2Power = _Matcap2Power;
        half3 matCapColor = MatcapColor(matcapData);
        RenderWithSpecular(col, metallic, mainLight, viewDirWS, albedo.rgb, roughness, normalWS, input.positionWS);
    
        col += matCapColor;

        RenderWithEmissionFlowFog(col, albedo.rgb, emissive, input);

        return half4(col.rgb, albedo.a * _AlphaScale);
    }

    half4 NotMatCapFragment(VertexOutput input) : SV_Target
    {
        half4 albedo = Albedo(input);

        half roughness, ao, metallic, emissive;
        GetIlmTexVal(input.uvAndScreenUV.xy, roughness, ao, metallic, emissive);

        // 获取主光源
        Light mainLight = GetMainLight();
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;

    #if _NORMAL_ON
        half4 normalTexVal = tex2D(_NormalTex, input.uvAndScreenUV.xy);
    #else
        half4 normalTexVal;
    #endif
        
        half3 viewDirWS, normalWS;
        InitNormalAndViewDir(input, normalTexVal, normalWS, viewDirWS);

        half3 col = RenderWithDiffuseAndSHAndRim(mainLight, normalWS, viewDirWS, albedo.rgb, input, ao, metallic);
    
        RenderWithSpecular(col, metallic, mainLight, viewDirWS, albedo.rgb, roughness, normalWS, input.positionWS);
    
        RenderWithEmissionFlowFog(col, albedo.rgb, emissive, input);

        return half4(col.rgb, albedo.a * _AlphaScale);
    }
    ENDHLSL

    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent"}
        LOD 500
        Blend SrcAlpha OneMinusSrcAlpha, [_SrcAlphaBlend] [_DstAlphaBlend]
        
        Stencil
        {
            Ref [_StencilVal]
            Comp Always
            Pass [_StencilOp]
        }

        Pass 
        {
            Tags {"LightMode" = "SRPDefaultUnlit"}
            NAME "FRONTBASE"
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest
            
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _SPECULAR_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _TOON_RIM
            #pragma shader_feature_local _MATCAP2_ON
            #pragma shader_feature_local _FLOW_ON
            #pragma shader_feature_local _SHADOWTEX_ON

            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            Name "OUTLINE"
            Cull Front
            
            HLSLPROGRAM
            #pragma shader_feature_local _OL_ON
            
            // #pragma multi_compile_fog
            
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            ENDHLSL
        }
    }
    
    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha, [_SrcAlphaBlend] [_DstAlphaBlend]
        
        Stencil
        {
            Ref [_StencilVal]
            Comp Always
            Pass [_StencilOp]
        }

        Pass 
        {
            NAME "FRONTBASE"
            ZWrite On
            Cull BACK

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _SPECULAR_ON
            #pragma shader_feature_local _MATCAP2_ON
            #pragma shader_feature_local _FLOW_ON

            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
    
    Fallback "MC/OpaqueShadowCaster"
}
