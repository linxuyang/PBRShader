Shader "MC/Character/Toon/BasicToonSkin"
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
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]_ReceiveShadows("接受阴影", Float) = 1.0
        [HDR]_Color("叠加色(RGBA)", Color) =(1, 1, 1, 1)
        _MainTex("固有色(RGBA)", 2D) = "white" {}
        _ShadowTex("暗面叠加色(RGB)", 2D) = "grey" {}
        _ShadowStrength("阴影浓度", Range(0, 2)) = 1
        [Toggle(_SHADOWTEX_ON)]_ShadowSelfToggle("暗部使用贴图", float) = 1
        [HideInInspector]
        _AlphaScale("透明度", Range(0, 1)) = 1
        [Space]
        [Header(Shading)]
        _ToonStep("明暗线位置", Range(0, 1)) = .5
        _ToonFeather("羽化", Range(0, 1)) = 0
        [HDR]_ShadowColor1("暗部颜色(RGBA)", Color) =(1, 1, 1, 1)
        [Toggle(_SHADOW2_ON)]_Shadow2Toggle("第二层暗部(暗部贴图x暗部颜色2)", Float) = 0
        _ToonStep2("明暗线位置2", Range(0, 1)) = .5
        _ToonFeather2("羽化2", Range(0, 1)) = 0
        [HDR]_ShadowColor2("暗部颜色2(RGBA)", Color) =(0.5, 0.5, 0.5, 1)
        [Space]
        [Header(Normals)]
        [Toggle(_NORMAL_ON)]_BumpMapToggle(":: 启用法线贴图(RG为法线, BA为matcap遮罩)", Float) = 0
        _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("强度", Range(0, 2)) = 1
        [Space]
        [Header(ILM Mixed Map)]
        [NoScaleOffset] _ILMTex("ILM(RGBA) : 粗糙度, AO, 金属度, 自发光", 2D) = "black" {}
        _MetallicLevel("金属度系数", Range(0, 1)) = 1 
        _RoughnessLevel("粗糙度系数", Range(0, 2)) = 1 
        _AOLevel("AO系数", Range(0, 1)) = 1 
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 启用自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色(RGB)", Color) =(1, 1, 1, 1)
        _EmissionPower("强度", Range(0, 2)) = 1
        [Space]
        [Header(Rim Light)]
        //边缘光
        [Toggle(_RIM_ON)]_RimToggle(":: 启用边缘光", Float) = 0
        _RimWidth("边缘光宽度", Range(0, 1)) = .5
        _RimPower("强度", Range(0, 3)) = 1
        _RimPermeation("边缘光向暗面延申", Range(0, 1)) = 0
        [Space]
        [HDR]_RimColor("边缘光颜色(RGB)", Color) =(1, 1, 1, 1)
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
        _OutlineColor("描边叠加色", Color) =(1, 1, 1, 1)
        _Outline("描边宽度", Range(0.001, 1)) = 0
        _OutlineZBias("描边Z偏移", Float) = 0
        _OutlineDispearDistance("描边消失距离", Range(1, 5)) = 1

        [Space]
        [Header(MatCap)]
        [Toggle(_MATCAP_ON)]_MatcapToggle(":: 启用MatCap", Float) = 0
        
        [Space(10)]
        [NoScaleOffset]_MatcapTex1("MatCap 纹理(RGB)", 2D) = "white" {}
        _Matcap1Scale("效果强度", Range(0, 1)) = 0
        [Toggle]_Matcap1ColorDiffuseToggle(":: 叠加固有色", Float) = 0
        [Toggle]_Matcap1RoughnessToggle(":: 粗糙的地方减弱", Float) = 0
        [HDR]_MatcapColor1("纹理叠加色(RGB)", Color) =(1, 1, 1, 1)
        _Matcap1Power("纹理强度", Range(0, 3)) = 1
        _Matcap1Index("MatCap纹理是第几张(0~15 从左至右 从上到下)", float) = 0
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../CommonInclude.hlsl"
    #include "BasicToonInclude.hlsl"
    
    sampler2D _MainTex;
    sampler2D _NormalTex;
    sampler2D _DyeNoiseTex;
    sampler2D _ILMTex;
    sampler2D _MatcapTex1;
    sampler2D _ShadowTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    
    half4 _Color;
    half _AlphaScale;
    half _NormalScale;
    
    half _ShadowStrength;
    
    half3 _ShadowColor1, _ShadowColor2;
    half _ToonStep, _ToonStep2;
    half _ToonFeather, _ToonFeather2;
    
    half4 _MatcapTex1_TexelSize;
    half _Matcap1ColorDiffuseToggle, _Matcap1RoughnessToggle;
    half3 _MatcapColor1;
    half _Matcap1Scale;
    half _Matcap1Power;
    half _Matcap1Index;
    
    half3 _EmissionColor;
    half _EmissionPower;
    
    half _RimWidth, _RimPower, _RimPermeation;
    half _ToonRimStep, _ToonRimFeather;
    half3 _RimColor;
    half _RimDiffuseBlend;
    
    half _MetallicLevel, _RoughnessLevel, _AOLevel;
    
    half _Outline;
    half3 _OutlineColor;
    half _OutlineZBias;
    CBUFFER_END

    half3 SkinMatcapColor(half3 albedo, half2 matcapMask, half3 normalWS, half roughness)
    {
        half onePixel = _MatcapTex1_TexelSize.x;
        half2 normalVS = TransformWorldToViewDir(normalWS).xy;
        normalVS = normalVS * 0.5 + 0.5;
        normalVS *= 0.25 - 2 * onePixel;
        half indexs =_Matcap1Index;
        half4 offset = 0;
        offset.yw = floor(indexs / 4);
        offset.xz = indexs - offset.yw * 4;
        offset.yw = 3 - offset.yw;
        offset = offset * 0.25 + onePixel;
    
        half3 matcap = tex2D(_MatcapTex1, normalVS + offset.xy).rgb;
        matcap *= _MatcapColor1 * _Matcap1Power;
        matcap *= lerp(half3(1, 1, 1), albedo, _Matcap1ColorDiffuseToggle);
        half3 matcap1 = matcap * matcapMask.x * _Matcap1Scale;
        matcap1 *= 1 - roughness * _Matcap1RoughnessToggle;
            
        return matcap1;
    }
    
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
        float4 shadowCoord : TEXCOORD5; // 阴影纹理坐标
    #if _RIM_ON
        half3 rimMaskAndRimDir : TEXCOORD6;
    #endif
        float3 positionWS : TEXCOORD7;
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

    #if _RIM_ON
        output.rimMaskAndRimDir.x = input.color.g;
        output.rimMaskAndRimDir.yz = GetRimDir();
    #endif

        output.shadowCoord = TransformWorldToShadowCoord(positionWS);
    
        return output;
    }

    half4 Fragment(VertexOutput input, half facing : VFACE) : SV_Target
    {
        half4 albedo = tex2D(_MainTex, input.uvAndScreenUV.xy) * _Color;

        half4 ilm = tex2D(_ILMTex, input.uvAndScreenUV.xy);
        half roughness = saturate(ilm.r * _RoughnessLevel);
        half ao = lerp(1, ilm.g, _AOLevel);
        half metallic = saturate(ilm.b * _MetallicLevel);
        half emissive = ilm.a;

        // 获取主光源
        Light mainLight = GetMainLight(input.shadowCoord);
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;
        mainLight.shadowAttenuation = saturate(lerp(1, mainLight.shadowAttenuation, _ShadowStrength));

    #if _NORMAL_ON || _MATCAP_ON
        half4 normalTexVal = tex2D(_NormalTex, input.uvAndScreenUV.xy);
    #endif
        
    #if _NORMAL_ON
        half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
        half3 normalTS = UnpackCustomNormal(normalTexVal, _NormalScale);
        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,
            input.bitangentWS.xyz, input.normalWS.xyz));
        normalWS = normalize(normalWS);
    #else
        half3 viewDirWS = SafeNormalize(input.viewDirWS);
        half3 normalWS = normalize(input.normalWS.xyz);
    #endif
        
        normalWS *= lerp(1, -1, step(facing, 0));
        
        half nDotV = saturate(dot(normalWS, viewDirWS));

    #ifdef _SHADOWTEX_ON
        half3 shadowColor = albedo.rgb * tex2D(_ShadowTex, input.uvAndScreenUV.xy).rgb;
    #else
        half3 shadowColor = albedo.rgb * albedo.rgb;
    #endif
        half3 col = RendererDiffuse(albedo.rgb, nDotV * mainLight.shadowAttenuation, shadowColor, _ShadowColor1,
            _ShadowColor2, _ToonStep, _ToonStep2, _ToonFeather, _ToonFeather2) * mainLight.color;

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, input.positionWS);
            col += RendererDiffuse(albedo.rgb, nDotV, shadowColor, _ShadowColor1, _ShadowColor2, _ToonStep, _ToonStep2,
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
    
    #if _MATCAP_ON
        half3 matCapColor = SkinMatcapColor(col, normalTexVal.ba, normalWS, roughness);
        col += matCapColor;
    #endif
    
    #if _EMISSION_ON
        col += albedo.rgb * emissive * _EmissionColor * _EmissionPower;
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

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _TOON_RIM
            #pragma shader_feature_local _MATCAP_ON
            #pragma shader_feature_local _SHADOWTEX_ON

            // #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

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

    // 中配删除勾边、暗部贴图、bentnormal、边缘光
    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry-50" "RenderType" = "Opaque"}
        LOD 100
        ZTest On

        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}
            NAME "MAINPASS"
            Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
            
            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _NORMAL_ON
            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _MATCAP_ON

            // #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            
            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }

   
    Fallback "MC/OpaqueShadowCaster"
}
