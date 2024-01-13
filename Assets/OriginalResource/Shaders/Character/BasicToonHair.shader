Shader "MC/Character/Toon/BasicToonHair"
{
    Properties 
    {
        [Header(Basics)]
        [BlendMode]_Mode("渲染类型", Float) = 0.0
        [HideInInspector]_SrcBlend("__src", Float) = 1.0
        [HideInInspector]_DstBlend("__dst", Float) = 0.0
        [HideInInspector]_SrcAlphaBlend("__srcAlpha", Float) = 1.0
        [HideInInspector]_DstAlphaBlend("__dstAlpha", Float) = 0.0
        [HideInInspector]_ZWrite("__zw", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("背面消隐", Float) = 2
        [HDR]_Color("叠加色 (RGBA)", Color) = (1, 1, 1, 1)
        _MainTex("固有色 (RGBA)", 2D) = "white" {}
        [HideInInspector]_AlphaScale("透明度", Range(0, 1)) = 1
        [Space]
        [Header(Shading)]
        _ToonStep("明暗线位置", Range(0, 1)) = .5
        _ToonFeather("羽化", Range(0, 1)) = 0
        [HDR]_ShadowColor1("暗部颜色 (RGBA)", Color) = (1, 1, 1, 1)
        _ToonStep2("明暗线位置2", Range(0, 1)) = .5
        _ToonFeather2("羽化2", Range(0, 1)) = 0
        [HDR]_ShadowColor2("暗部颜色2 (RGBA)", Color) = (0.5, 0.5, 0.5, 1)
        [Space]
        [Header(Specular)]
        _SpecPower("总体强度", Range(0, 10)) = 1
        [HDR]_AnisoSpecColor("主高光颜色", Color) = (1, 1, 1, 1)
        _AnisoSpecPower("主高光强度", Range(0, 5)) = 1
        _AnisoGlossiness("光滑度", Range(0, 1)) = .2
        [HDR]_AnisoBaseSpecColor("副高光颜色", Color) = (1, 1, 1, 1)
        _AnisoSpecBasePower("副高光强度", Range(0, 1)) = 1
        _AnisoBaseGlossiness("副高光光滑度", Range(0, 1)) = 1
        _AnisoSpecularPosition("高光位置", Range(-1, 1)) = 0
        [Space]
        _AnisoSpecNoiseTex("噪波图", 2D) = "black" {}
        _AnisoNoiseScale("幅度", Range(0, 2)) = 0
        [Space]
        [Header(Normals)]
        [Toggle(_NORMAL_ON)]_BumpMapToggle(":: 启用法线贴图(RG为法线,BA为matcap遮罩)", Float) = 0
        _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("强度", Range(0, 2)) = 1
        [Space]
        [Header(ILM Mixed Map)]
        [NoScaleOffset]_ILMTex("ILM(RGBA) : 粗糙度,AO,高光强度,自发光", 2D) = "grey" {}
        _MetallicLevel("金属度系数", Range(0, 1)) = 1 
        _AOLevel("AO系数", Range(0, 1)) = 1 
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色 (RGB)", Color) = (1, 1, 1, 1)
        _EmissionPower("强度", Range(0, 2)) = 1
        [Space]
        [Header(Rim Light)]
        //边缘光
        [Toggle(_RIM_ON)]_RimToggle(":: 启用边缘光", Float) = 0
        _RimWidth("边缘光宽度", Range(0, 1)) = .5
        _RimPower("强度", Range(0, 3)) = 1
        _RimPermeation("边缘光向暗面延申", Range(0, 1)) = 0
        [Space]
        [HDR]_RimColor("边缘光颜色 (RGB)", Color) = (1, 1, 1, 1)
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
        [Space]
        [Header(DyeFlowMask)]
        _DyeFlowMask("染色/流光遮罩(rgb染色、a流光)", 2D) = "white" {}
        [Space]
        [Header(Dye)]
        [Enum(Off, 0, On, 1, Transition, 2)]_Dye("染色开关", Float) = 0
        [Space]
        [Toggle]_ToIsOrigin("切换目标是原色?", Float) = 0
        [DyeColor]_Offset1("染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset2("染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset3("染色B", Vector) = (0, 0, 0, 0)
        [Space]
        [Toggle]_FromIsOrigin("切换源是原色？", Float) = 0
        [DyeColor]_OffsetFrom1("源染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_OffsetFrom2("源染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_OffsetFrom3("源染色B", Vector) = (0, 0, 0, 0)
        _DyeOffset("染色渐变竖直偏移", Float) = 0
        _DyeScale("1/染色渐变高度", Range(0, 1)) = 0.5
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
        _FlowLightTex("流光贴图 (RGBA)", 2D) = "white" {}
        [HDR]_FlowColor1("流光颜色1 (RGBA)", Color) = (.5, .5, .5, 1)
        [HDR]_FlowColor2("流光颜色2 (RGBA)", Color) = (.5, .5, .5, 1)
        _FlowParam1("流光参数(u方向、v方向、tile、亮度)", Vector) = (1, 1, 1, 1)
        _FlowParam2("流光参数(u方向、v方向、tile、亮度)", Vector) = (1, 1, 1, 1)
        [HDR]_BlinkColor("闪光颜色", Color) = (1, 1, 1, 1)
        _BlinkTile("闪光尺寸", Range(0.1, 3)) = 1
        _BlinkSpeed("闪光速度",Range(0, 0.2)) = 1
        
        [HideInInspector][Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("模板操作", float) = 0
        [HideInInspector]_StencilVal("模板值", float) = 2
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../CommonInclude.hlsl"
    #include "BasicToonInclude.hlsl"
    
    sampler2D _MainTex;
    sampler2D _NormalTex;
    sampler2D _AnisoSpecNoiseTex;
    sampler2D _FlowLightTex;
    sampler2D _DyeFlowMask; //染色遮罩
    sampler2D _DyeNoiseTex;
    sampler2D _ILMTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _AnisoSpecNoiseTex_ST;
    half4 _FlowLightTex_ST;
    
    half4 _Color;
    half _AlphaScale;
    half _NormalScale;
    half _AnisoNoiseScale;
    
    half3 _ShadowColor1, _ShadowColor2;
    half _ToonStep, _ToonStep2;
    half _ToonFeather, _ToonFeather2;
    
    half _SpecPower;
    half3 _AnisoSpecColor, _AnisoBaseSpecColor;
    half _AnisoSpecPower, _AnisoGlossiness, _AnisoSpecBasePower, _AnisoBaseGlossiness, _AnisoSpecularPosition;
    
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
    
    half _MetallicLevel, _AOLevel;
    
    half _Outline;
    half3 _OutlineColor;
    half _OutlineZBias;
    CBUFFER_END
    
    // 描边着色器 begin
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

    half3 KKSpecular(half3 tangent, half3 viewDir, half3 lightDir, half nDotL)
    {
        half3 halfVector = SafeNormalize(float3(viewDir) + float3(lightDir));
        half tDotH = dot(normalize(tangent + halfVector * _AnisoSpecularPosition), halfVector);
        half sinTH2 = abs(1.0 - tDotH * tDotH);
        half3 specular1 = pow(sinTH2, (_AnisoGlossiness + 0.05) * 250) * _AnisoSpecColor;
        half3 specular2 = pow(sinTH2, (_AnisoGlossiness * _AnisoBaseGlossiness + 0.05) * 100) * _AnisoBaseSpecColor;
        half3 specular = specular1 * _AnisoSpecPower + specular2 * _AnisoSpecBasePower;
        return specular * nDotL;
    }

    struct VertexOutput
    {
        float4 positionCS : SV_POSITION;
        half4 uv : TEXCOORD0; // xy: MainTex uv; zw: AnisoSpecNoiseTex uv
        half4 fogFactorAndVertexSH : TEXCOORD1;
        half4 normalWS : TEXCOORD2; // xyz:法线(世界); w:观察方向(世界).x
        half4 tangentWS : TEXCOORD3; // xyz:切线(世界); w:观察方向(世界).y
        half4 bitangentWS : TEXCOORD4; // xyz:副切线(世界); w:观察方向(世界).z
        float2 screenUV : TEXCOORD5;
        float3 positionWS : TEXCOORD6;
    #if _RIM_ON
        half3 rimMaskAndRimDir : TEXCOORD7;
    #endif
    #if _FLOW_ON
        half4 flowUV : TEXCOORD8;
    #endif
    };

    VertexOutput Vertex(BasicToonVertexInput input)
    {
        VertexOutput output = (VertexOutput)0;
        float3 positionWS = TransformObjectToWorld(input.positionOS);
        output.positionWS = positionWS;
        output.positionCS = TransformWorldToHClip(positionWS);
        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _AnisoSpecNoiseTex);

        half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

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
        output.screenUV = screenPos.xy;
    
    #if _RIM_ON
        output.rimMaskAndRimDir.x = input.color.g;
        output.rimMaskAndRimDir.yz = GetRimDir();
    #endif
    
        return output;
    }

    half4 Fragment(VertexOutput input, half facing : VFACE) : SV_Target
    {
        half4 albedo = tex2D(_MainTex, input.uv.xy) * _Color;

        DyeColor(_Dye, _DyeFlowMask, albedo.rgb, input.uv.xy, _Offset1, _Offset2, _Offset3);
        DyeTransitionData dyeTransitionData;
        dyeTransitionData.screenUV = input.screenUV;
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
        DyeTransition(_Dye, _DyeFlowMask, _DyeNoiseTex, albedo.rgb, input.uv.xy, dyeTransitionData);
    
        half4 ilm = tex2D(_ILMTex, input.uv.xy);
        half ao = lerp(1, ilm.g, _AOLevel);
        half specularMask = ilm.b * _MetallicLevel;
        half emissive = ilm.a;

        // 获取主光源
        Light mainLight = GetMainLight();
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;
        half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
        viewDirWS = SafeNormalize(viewDirWS);
        half3 tangentWS = normalize(input.tangentWS.xyz);
        
    #if _NORMAL_ON
        half4 normalTexVal = tex2D(_NormalTex, input.uv.xy);
        half3 normalTS = UnpackCustomNormal(normalTexVal, _NormalScale);
        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,
            input.bitangentWS.xyz, input.normalWS.xyz));
        normalWS = normalize(normalWS);
    #else
        half3 normalWS = input.normalWS.xyz;
    #endif

        normalWS *= lerp(1, -1, step(facing, 0));
        
        half nDotL = saturate(dot(normalWS, mainLight.direction)) * 0.5 + 0.5;

        half3 shadowColor = albedo.rgb * albedo.rgb;
        half3 col = RendererDiffuse(albedo.rgb, nDotL, shadowColor, _ShadowColor1, _ShadowColor2, _ToonStep, _ToonStep2,
            _ToonFeather, _ToonFeather2) * mainLight.color;

        half shift = tex2D(_AnisoSpecNoiseTex, input.uv.wz).r * 2 - 1;
        half3 specTangentWS = normalize(tangentWS + normalWS * shift * _AnisoNoiseScale);
        half3 specColor = KKSpecular(specTangentWS, viewDirWS, mainLight.direction, nDotL);
        specColor *= _SpecPower * specularMask * mainLight.color;

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, input.positionWS);
            nDotL = saturate(dot(normalWS, light.direction)) * 0.5 + 0.5;
            col += RendererDiffuse(albedo.rgb, nDotL, shadowColor, _ShadowColor1, _ShadowColor2, _ToonStep, _ToonStep2,
                _ToonFeather, _ToonFeather2) * light.color;
            specColor += KKSpecular(specTangentWS, viewDirWS, light.direction, nDotL) * _SpecPower
                * specularMask * light.color;
        }
        
        // 间接光
        col += albedo.rgb * input.fogFactorAndVertexSH.yzw * ao;
    #if _RIM_ON
        RimData rimData;
        rimData.mask = input.rimMaskAndRimDir.x;
        rimData.albedo = albedo.rgb;
        rimData.ao = ao;
        rimData.metallic = 0;
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
        
        col += specColor;
    
    #if _EMISSION_ON
        col += albedo.rgb * emissive * _EmissionColor * _EmissionPower;
    #endif
        
    #if _FLOW_ON
        col += FlowLight(input.uv.xy, input.flowUV, _DyeFlowMask, _FlowLightTex, _BlinkTile, _BlinkSpeed, _FlowParam1,
            _FlowParam2, _FlowColor1, _FlowColor2, _BlinkColor);
    #endif
 
        col = MixFog(col, input.fogFactorAndVertexSH.x);
        return half4(col.rgb, albedo.a * _AlphaScale);
    }
    ENDHLSL

    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry-50" "RenderType" = "Opaque"}
        LOD 500
        ZTest On
        
        Pass 
        {
            Tags {"LightMode" = "SRPDefaultUnlit"}
            NAME "MAINPASS"

            Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            Stencil
            {
                Ref [_StencilVal]
                Comp Always
                Pass [_StencilOp]
            }

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _TOON_RIM
            #pragma shader_feature_local _FLOW_ON

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
            Blend [_SrcBlend] [_DstBlend],[_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]
            Cull Front
            
            HLSLPROGRAM

            #pragma shader_feature_local _OL_ON
            
            // #pragma multi_compile_fog
            
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            ENDHLSL
        }
        
    }
    
    // 中配删除暗部贴图、边缘光、描边
    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue"="Geometry-50" "RenderType"="Opaque"}
        LOD 100
        ZTest On
        
        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}
            NAME "MAINPASS"

            Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            Stencil
            {
                Ref [_StencilVal]
                Comp Always
                Pass [_StencilOp]
            }

            HLSLPROGRAM

            #pragma fragmentoption ARB_precision_hint_nicest
            
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
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