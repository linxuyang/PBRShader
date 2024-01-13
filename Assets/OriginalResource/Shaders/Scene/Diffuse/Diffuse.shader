Shader "MC/Scene/Diffuse"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color("叠加色", Color) = (1, 1, 1, 1)
        _MainTex("固有色贴图 (RGBA)", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("剔除模式", Float) = 2
        [Space]
        [Header(Blinn Phong Specular)]
        [NoScaleOffset] _SpecularMaskTex("混合贴图 (R:光滑度 G：金属度 B：高光强度 A：AO)", 2D) = "grey" {}
        [HDR]_SpecularColor("高光叠加色", Color) = (1, 1, 1, 1)
        [Toggle]_SpecularDiffuseToggle(":: 高光颜色叠加固有色", Float) = 0
        [PowerSlider(2)]_Glossiness("光滑度", Range(0, 1)) = .5
        [PowerSlider(2)]_SpecularPower("高光强度", Range(0, 1)) = .2
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 开启自发光", Float) = 0
        [NoScaleOffset]_EmissionTex("自发光强度遮罩 (R通道)", 2D) = "white" {}
        [HDR]_EmissionColor("自发光叠加色", Color) = (1, 1, 1, 1)
        _EmissionPower("自发光强度", Range(0, 2)) = 1
        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)]_ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha("透明度", Range(0, 1)) = 1
        [Space]
        [Header(Wet)]
        [Toggle(_WET_ON)]_WetOn("开启潮湿", float) = 0
        _WetLevel("潮湿程度",Range(0, 1)) = 0
        _FloodLevel1("砖块缝隙水位", Range(0, 1)) = 0
        _FloodLevel2("水坑水位", Range(0, 1)) = 0
        _RainIntensity("降雨强度", Range(0, 1)) = 0
        [Header(Ripple)]
        _Density("密度", Range(0.01, 1)) = 1
        _SpreadSpd("波动速度", Range(1, 2)) = 1
        _WaveGap("波的宽度", Range(0.1, 0.6)) = 1
        _WaveHei("波动高度", Range(0.1, 10)) = 1
        _Tile("尺寸", Range(0.1, 2)) = 1
        [Header(WaterDistort)]
        _WaterNoiseMap("扰动噪声", 2D) = "white" {}
        _WaterDistortStrength("水面扰动强度", Range(0, 1)) = 0.25
        _WaterDistortScale("扰动尺寸", Range(0.01, 1)) = 0.25
        _WaterDistortTimeScale("扰动速度", Range(0, 5)) = 3
    }
    
    HLSLINCLUDE
    #include "DiffuseCommon.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    #include "../SceneCommonUtil.hlsl"
    

    sampler2D _MainTex;
    sampler2D _SpecularMaskTex;
    sampler2D _EmissionTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _Color;
    half4 _SpecularColor;
    half _Glossiness, _SpecularPower;
    half _SpecularDiffuseToggle;

    half4 _EmissionTex_ST;
    half3 _EmissionColor;
    half _EmissionPower;
    half _ScreenDoorAlpha; //点阵透明度
    CBUFFER_END

    struct DiffuseV2F
    {
        float4 positionCS : SV_POSITION;
        half2 uv : TEXCOORD0;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1); // 烘焙物体:光照贴图, 动态物体:光照探针
        float3 positionWS : TEXCOORD2; // 顶点坐标(世界)
        half3 normalWS : TEXCOORD3; // 法线(世界)
        half3 viewDirWS : TEXCOORD4; // 观察方向(世界)
        half4 fogFactorAndVertexLight : TEXCOORD5; // x: 雾效, yzw: 次要光源(逐顶点)
        float4 shadowCoord : TEXCOORD6; // 阴影纹理坐标
    #if _EMISSION_ON
        half2 emissionUV : TEXCOORD7;
    #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    DiffuseSurfaceData InitializeDiffuseSurfaceData(DiffuseV2F input)
    {
        DiffuseSurfaceData surfaceData = (DiffuseSurfaceData)0;
        surfaceData.albedo = tex2D(_MainTex, input.uv) * _Color;
        half3 baseColor = lerp(half3(1, 1, 1), surfaceData.albedo.rgb, _SpecularDiffuseToggle);
        surfaceData.specularColor = _SpecularColor.rgb * _SpecularColor.a * baseColor;
        half4 mask = tex2D(_SpecularMaskTex, input.uv);
        surfaceData.smoothness = _Glossiness * mask.r;
        surfaceData.metallic = mask.g;
        surfaceData.specular = _SpecularPower * mask.b;
        surfaceData.diffuseScale = 1;
        surfaceData.occlusion = mask.a;
    #if _EMISSION_ON
        half emissionMask = tex2D(_EmissionTex, input.emissionUV).r;
        surfaceData.emission = surfaceData.albedo.rgb * _EmissionColor * _EmissionPower * emissionMask;
    #endif
        return surfaceData;
    }

    DiffuseInputData InitializeDiffuseInputData(DiffuseV2F input)
    {
        DiffuseInputData inputData = (DiffuseInputData)0;
        inputData.positionWS = input.positionWS;
        inputData.normalWS = normalize(input.normalWS);
        inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);
        inputData.shadowCoord = input.shadowCoord;
        inputData.fogCoord = input.fogFactorAndVertexLight.x;
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
        inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    #if _SCREEN_DOOR_ON
        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    #endif
        inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
        return inputData;
    }

    DiffuseV2F DiffsePassVertex(DiffuseVertexInput input)
    {
        DiffuseV2F output = (DiffuseV2F)0;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);

        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        DiffuseNormalInputs normalInput = GetDiffuseNormalInputs(input.normalOS, input.tangentOS);
        half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
        // 对次要光源逐个计算光照(兰伯特模型), 结果相加
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

        output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
    #if _EMISSION_ON
        output.emissionUV = TRANSFORM_TEX(input.texcoord, _EmissionTex);
    #endif
        output.normalWS = normalInput.normalWS;
        output.viewDirWS = viewDirWS;

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV); // 处理LightmapUV(拉伸、偏移)
        DIFFUSE_OUTPUT_SH(output.normalWS, output.vertexSH);

        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        output.positionWS = vertexInput.positionWS;
        output.shadowCoord = GetShadowCoord(vertexInput);
        output.positionCS = vertexInput.positionCS;
        return output;
    }

    half4 DiffusePassFragment(DiffuseV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        DiffuseSurfaceData surfaceData = InitializeDiffuseSurfaceData(input);

        DiffuseInputData inputData = InitializeDiffuseInputData(input);

        ScreenDitherClip(inputData.normalizedScreenSpaceUV, _ScreenDoorAlpha);
        
        half4 color = DiffuseRender(inputData, surfaceData);
        color.a = 1;
        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }

    ENDHLSL

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue"="Geometry"
        }
        LOD 500

        Pass
        {
            Name "MainPass"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull [_Cull]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _WET_ON

            #pragma multi_compile_local _ _SCREEN_DOOR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON

            #pragma vertex DiffsePassVertex
            #pragma fragment DiffusePassFragment

            ENDHLSL
        }
        
        Pass
        {
            Name "META"
            Tags
            {
                "LightMode"="Meta"
            }
            
            Cull Off
            
            HLSLPROGRAM
            #pragma shader_feature_local _EMISSION_ON
        
            #pragma vertex DiffuseVertexMeta
            #pragma fragment DiffuseFragmentMeta

            DiffuseMetaV2F DiffuseVertexMeta(DiffuseMetaVertexInput input)
            {
                DiffuseMetaV2F output;
                output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
            #if _EMISSION_ON
                output.emissionUV = TRANSFORM_TEX(input.texcoord, _EmissionTex);
            #endif
                return output;
            }
            
            half4 DiffuseFragmentMeta(DiffuseMetaV2F input) : SV_Target
            {
                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = tex2D(_MainTex, input.uv).rgb * _Color.rgb;
            #if _EMISSION_ON
                half emissionMask = tex2D(_EmissionTex, input.emissionUV).r;
                metaInput.Emission = metaInput.Albedo * _EmissionColor * _EmissionPower * emissionMask;
            #endif
                return MetaFragment(metaInput);
            }
            
            ENDHLSL
        }
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"
        }
        LOD 100

        Pass
        {
            Name "MainPass"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull [_Cull]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _WET_ON

            #pragma multi_compile_local _ _SCREEN_DOOR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON

            #pragma vertex DiffsePassVertex
            #pragma fragment DiffusePassFragment

            ENDHLSL
        }
    }

    
    Fallback "MC/OpaqueShadowCaster"
}