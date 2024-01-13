Shader "MC/Character/Scene/BasicRole"
{
    Properties
    {
        [Header(Basics)]        
        [BlendMode]_Mode ("渲染类型", Float) = 0.0
        [HideInInspector]_SrcBlend ("__src", Float) = 1.0
        [HideInInspector]_DstBlend ("__dst", Float) = 0.0
        [HideInInspector]_SrcAlphaBlend("__srcAlpha", Float) = 1.0
        [HideInInspector]_DstAlphaBlend("__dstAlpha", Float) = 0.0
        [HideInInspector]_ZWrite("__zw", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("背面消隐", Float) = 2
        [HDR]_Color("叠加色 (RGBA)", Color) = (1, 1, 1, 1)
        _MainTex("固有色 (RGBA)", 2D) = "white" {}
        [HideInInspector]
        _AlphaScale("透明度", Range(0, 1)) = 1

        [Space]
        [Header(Normals)]
        [Toggle(_NORMAL_ON)]_NormalToggle(":: 启用法线贴图", Float) = 0
        _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("强度", Range(0, 2)) = 1

        [Space]
        [Header(Lighting)]
        [PowerSlider(5.0)]_Shininess("光泽度", Range(0.03, 1)) = 0.078125
        _SpecColor("高光颜色(a通道控制强弱)", Color) = (0.5, 0.5, 0.5, 1)
        _LightFilter("平行光扩散", Range(0, 1)) = 0

        [Space]
        [Header(Rim Light)]
        //边缘光
        [Toggle(_RIM_ON)]_RimToggle(":: 启用边缘光", Float) = 0
        _RimWidth("边缘光宽度", Range(0, 1)) = .5
        _RimPower("强度", Range(0, 3)) = 1
        [Space]
        [HDR]_RimColor("边缘光颜色 (RGB)", Color) = (1, 1, 1, 1)
        _RimDiffuseBlend("叠加多少固有色", Range(0, 1)) = 1
        [Space]

        //边缘光
        [HideInInspector][Toggle(_HIT_RIM)]_HitRimToggle(":: 启用受击边缘光", Float) = 0
        [HideInInspector]_HitRimWidth("边缘光宽度", Range(0, 1)) = .5
        [HideInInspector]_HitRimPower("强度", Range(0, 3)) = 1
        [HideInInspector][HDR]_HitRimColor("边缘光颜色 (RGB)", Color) = (1, 1, 1, 1)

        [Space]
        [Header(DyeFlowMask)]
        _DyeFlowMask("染色(rgba染色)", 2D) = "white" {}
        [Space]
        [Header(Dye)]
        [Toggle]_Dye("染色开关", Float) = 0
        [Space]
        [DyeColor]_Offset1("染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset2("染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset3("染色B", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset4("染色A", Vector) = (0, 0, 0, 0)

        [Space]
        [Header(EmissionFlow)]
        [NoScaleOffset]_EmissionFlowTex("自发光遮罩R/流光遮罩G", 2D) = "white" {}

        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色 (RGB)", Color) = (.5, .5, .5, 1)
        _EmissionPower("强度", Range(0, 2)) = 0


        [Space]
        [Header(Flow Color)]
        //流光开启与否。只有=1才会开启
        [Toggle(_FLOW_ON)]_FlowAbleToggle(":: 启用流光", Float) = 0
        //流光 改版
        _FlowLightTex("流光贴图 (R)", 2D) = "white" {}
        [HDR]_FlowColor1("流光颜色 (RGBA)", Color) = (.5, .5, .5, 1)
        _FlowParam1("流光参数(u方向、v方向、tile、亮度)", Vector) = (1, 1, 1, 1)
  
        //溶解相关
		[Header(Dissolve)]
		[Toggle(_DISSOLVE_ON)]_Dissolve("死亡溶解开关", float) = 0
		_DissolveTex("溶解贴图", 2D) = "white" {}
		_DissolveProgress("溶解阈值", Range(0, 1)) = 1
		_DissolveEdge("溶解边缘扩散程度", Range(0.01, 0.5)) = 0.01
		_DissolveEdgeAround("溶解边缘颜色范围", Range(0, 0.5)) = 0.25
		_DissolveEdgeAroundPower("溶解边缘颜色外层强度", Range(1, 5)) = 5
		_DissolveEdgeAroundHDR("溶解边缘颜色HDR强度", Range(1, 3)) = 3
		_DissolveEdgeColor1("溶解边缘颜色内层", Color) = (0, 0, 0, 0)
		_DissolveEdgeColor2("溶解边缘颜色外层", Color) = (0, 0, 0, 0)
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "../CommonInclude.hlsl"

    sampler2D _MainTex;
    sampler2D _NormalTex;
    sampler2D _FlowLightTex;
    sampler2D _EmissionFlowTex;  //自发光遮罩R、流光遮罩G、流光贴图B
    sampler2D _DyeFlowMask; //染色遮罩
    sampler2D	_DissolveTex;

    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _Color;
    half _AlphaScale;

    // 粗糙度
    half _Shininess;
    // 平行光扩散范围
    half _LightFilter;
    half4 _SpecColor;

    half3 _EmissionColor;
    half _EmissionPower;

    half _Dye;
    half3 _Offset1, _Offset2, _Offset3, _Offset4;
    
    half4 _NormalTex_ST;
    half _NormalScale;
    
    half4 _FlowLightTex_ST;
    half4 _FlowParam1;
    half3 _FlowColor1;

    half _RimWidth;
    half _RimPower;
    half3 _RimColor;
    half _RimDiffuseBlend;

    half3 _HitRimColor;
    half _HitRimWidth;
    half _HitRimPower;

    half4 _DissolveTex_ST;
    half _DissolveEdge;
    half _DissolveProgress;
    half _DissolveEdgeAround;
    half _DissolveEdgeAroundPower;
    half _DissolveEdgeAroundHDR;
    half3 _DissolveEdgeColor1;
    half3 _DissolveEdgeColor2;
    CBUFFER_END

    struct VertexInput
    {
        float3 positionOS : POSITION;
        half2 texcoord : TEXCOORD0;  
        half3 normalOS : NORMAL;
        half4 color : COLOR;
    #if _NORMAL_ON
        half4 tangentOS : TANGENT;
    #endif
    };

    struct VertexOutput
    {
        float4 positionCS : SV_POSITION;
        half4 uv : TEXCOORD0;
        half4 fogFactorAndVertexSH : TEXCOORD1; // x: 雾效, yzw: 球谐光照
        half3 flowUVAndRimFactor : TEXCOORD2; // xy: 流光UV, z: 边缘光强度
        float3 positionWS : TEXCOORD3;
    #if _NORMAL_ON
        half4 normalWS : TEXCOORD4; // xyz:法线(世界); w:观察方向(世界).x
        half4 tangentWS : TEXCOORD5; // xyz:切线(世界); w:观察方向(世界).y
        half4 bitangentWS : TEXCOORD6; // xyz:副切线(世界); w:观察方向(世界).z
    #else
        half3 normalWS : TEXCOORD4; // 法线(世界)
        half3 viewDirWS : TEXCOORD5; // 观察方向(世界)
    #endif
    };

    half GetRimFactor(half mask, half3 normal, half3 view, half3 light)
    {
        half nDotV = abs(dot(normal, view));
        half nDotL = saturate(abs(dot(normal, light)));
        half rim = nDotL * saturate((_RimWidth - nDotV) / _RimWidth) * mask;
        return rim;
    }

    void DyeColor(inout half3 color, half2 uv)
    {
        [branch]if(_Dye)
        {
            half4 dyeMask = tex2D(_DyeFlowMask, uv);
        
            half dyeSwitchR = 1 - step(dyeMask.r, 0.01);
            // 当染色R通道生效时, 覆盖G通道, 因此dyeMask.g - dyeSwitchR
            // 其它染色通道同理
            half dyeSwitchG = 1 - step(dyeMask.g - dyeSwitchR, 0.01);
            half dyeSwitchB = 1 - step(dyeMask.b - dyeSwitchR - dyeSwitchG, 0.01);
            half dyeSwitchA = 1 - step(dyeMask.a - dyeSwitchR - dyeSwitchG - dyeSwitchB, 0.01);
            half3 offsetHSV = _Offset1 * dyeSwitchR + _Offset2 * dyeSwitchG + _Offset3 * dyeSwitchB + _Offset4 * dyeSwitchA;
            half intensity = dyeMask.r * dyeSwitchR + dyeMask.g * dyeSwitchG + dyeMask.b * dyeSwitchB + dyeMask.a * dyeSwitchA;
            
            float3 hsv = RgbToHsv(color);
            hsv.x = offsetHSV.x;
            hsv.y = saturate(hsv.y + offsetHSV.y);
            hsv.z = saturate(hsv.z + offsetHSV.z);
            color = lerp(color, HsvToRgb(hsv), intensity);
        }
    }

    half3 Diffuse(half3 albedo, Light light, half3 normalWS)
    {
        half diff = max(0, dot(normalWS, light.direction));
        return albedo * light.color * saturate(diff + _LightFilter);
    }

    half3 Specular(Light light, half3 normalWS, half3 viewDirWS)
    {
        half3 halfVector = SafeNormalize(float3(light.direction) + float3(viewDirWS));
        half nDotH = max(0, dot(normalWS, halfVector));
        half spec = pow(nDotH, _Shininess * 128) * _SpecColor.a;
        return light.color * _SpecColor.rgb * spec;
    }

    VertexOutput Vertex(VertexInput input)
    {
        VertexOutput output = (VertexOutput)0;
        output.positionCS = TransformObjectToHClip(input.positionOS);
        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
    
        float3 positionWS = TransformObjectToWorld(input.positionOS);
        output.positionWS = positionWS;
        half3 viewDirWS = GetWorldSpaceViewDir(positionWS);

    #if _NORMAL_ON
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalTex);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
    #else
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
        output.normalWS = normalInput.normalWS;
        output.viewDirWS = viewDirWS;
    #endif
        
    #if _RIM_ON
        half3 lightDirWS = normalize(GetWorldSpaceLightDir(positionWS));
        output.flowUVAndRimFactor.z = GetRimFactor(input.color.g, normalInput.normalWS, normalize(viewDirWS), lightDirWS);
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
        flowUV = flowUV * _FlowParam1.z + fmod(_Time.x, 100.0) * _FlowParam1.xy;
        output.flowUVAndRimFactor.xy = flowUV;
    #endif
    
        return output;
    }

    half4 Fragment(VertexOutput input) : SV_Target
    {
        half4 albedo = tex2D(_MainTex, input.uv.xy) * _Color;
        
        //染色处理
        DyeColor(albedo.rgb, input.uv.xy);
        
    #if _NORMAL_ON
        half3 normalTS = UnpackCustomNormal(tex2D(_NormalTex, input.uv.zw), _NormalScale);
        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,
            input.bitangentWS.xyz, input.normalWS.xyz));
        half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
    #else
        half3 normalWS = input.normalWS;
        half3 viewDirWS = SafeNormalize(input.viewDirWS);
    #endif
        normalWS = normalize(normalWS);

        Light mainLight = GetMainLight();
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;
        
        // 基本光照 = 自发光 + (直接漫反射 + 直接镜面反射)(BlinnPhong) + 间接漫反射(SH/ambient) + 间接镜面反射(不计算)
        // 直接光照部分
        // 漫反射
        half3 color = Diffuse(albedo.rgb, mainLight, normalWS);
        // 高光反射
        color += Specular(mainLight, normalWS, viewDirWS);
        // 环境光(球谐)
        color += albedo.rgb * input.fogFactorAndVertexSH.yzw;

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, input.positionWS);
            color += Diffuse(albedo.rgb, light, normalWS);
            color += Specular(light, normalWS, viewDirWS);
        }

    #if _EMISSION_ON || _FLOW_ON
        //自发光、流光遮罩。提前采样，因为下面有两个地方会共用到
        half4 emissionFlowMask = tex2D(_EmissionFlowTex, input.uv.xy);
    #endif
        
    #if _EMISSION_ON
        // 自发光
        color += emissionFlowMask.r * albedo.rgb * _EmissionColor * _EmissionPower;
    #endif
        
    #if _RIM_ON
        // 边缘光
        half3 rimColor = input.flowUVAndRimFactor.z * _RimPower * _RimColor;
        rimColor = lerp(rimColor, rimColor * albedo.rgb, _RimDiffuseBlend);
        color += rimColor * mainLight.color;
    #endif

    #if _HIT_RIM
        // 边缘光
        half nDotV = abs(dot(normalWS, viewDirWS));
        half hitRim = smoothstep(1 - _HitRimWidth, 1, 1 - nDotV);
        half3 hitRimColor = hitRim * _HitRimPower * _HitRimColor;
        color += hitRimColor;
    #endif
        
    #if _DISSOLVE_ON
        half dissolve = tex2D(_DissolveTex, input.uv.xy).r;
        //Edge
        half edge = lerp(dissolve + _DissolveEdge, dissolve - _DissolveEdge, _DissolveProgress);
        half dissolveAlpha = smoothstep(_DissolveProgress + _DissolveEdge, _DissolveProgress - _DissolveEdge, edge);

        //Edge Around Factor
        half edgearound = lerp(dissolve + _DissolveEdgeAround, dissolve - _DissolveEdgeAround, _DissolveProgress);
        edgearound = smoothstep(_DissolveProgress + _DissolveEdgeAround, _DissolveProgress - _DissolveEdgeAround, edgearound);
        edgearound = pow(edgearound, _DissolveEdgeAroundPower);

        //Edge Around Color
        half3 ca = lerp(_DissolveEdgeColor2, _DissolveEdgeColor1, edgearound);
        ca = (color + ca) * ca * _DissolveEdgeAroundHDR;
        color = lerp(ca, color, edgearound);        
        albedo.a *= dissolveAlpha;
    #endif

    #if _FLOW_ON
        half flowVal = tex2D(_FlowLightTex, input.flowUVAndRimFactor.xy).a;
        half3 tempCol = flowVal * _FlowParam1.w * _FlowColor1 * emissionFlowMask.g;
        color += tempCol;
    #endif

        // color = MixFog(color, input.fogFactorAndVertexSH.x);
        return half4(color, albedo.a * _AlphaScale);
    }
    ENDHLSL

    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry-50" "IgnoreProjector" = "True" "RenderType" = "Opaque"}
        LOD 300
        ZTest LEqual
        Cull [_Cull]

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _FLOW_ON
            #pragma shader_feature_local _RIM_ON

            #pragma multi_compile_local _ _HIT_RIM
            #pragma multi_compile_local _ _DISSOLVE_ON

            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }

    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry-50" "IgnoreProjector" = "True" "RenderType"="Opaque"}
        LOD 100
        ZTest LEqual
        Cull [_Cull]

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            Blend [_SrcBlend] [_DstBlend],[_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            
            #pragma shader_feature_local _EMISSION_ON

            //边缘光开关
            #pragma multi_compile_local _ _HIT_RIM
            #pragma multi_compile_local _ _DISSOLVE_ON

            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}