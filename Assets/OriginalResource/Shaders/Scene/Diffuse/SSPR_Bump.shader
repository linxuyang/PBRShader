Shader "MC/Scene/SSPR_Bump"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色", Color) = (1,1,1,1)
        _MainTex ("固有色贴图 (RGBA)", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("剔除模式", Float) = 2
        [Space]
        [Header(Normals)]
        _NormalTex ("法线贴图(RG:法线,A:环境反射遮罩)", 2D) = "bump" {}
        _NormalScale ("法线贴图强度", Range(0, 2)) = 1
        [Space]
        [Header(Blinn Phong Specular)]
        [NoScaleOffset] _SpecularMaskTex ("混合贴图 (R:光滑度 G：金属度 B：高光强度 A：AO)", 2D) = "grey" {}
        [HDR] _SpecularColor ("高光叠加色", Color) = (1,1,1,1)
        [HideInInspector]_SpecularDiffuseToggle(":: 高光颜色叠加固有色", Float) = 1
        [PowerSlider(2)]_Glossiness ("光滑度", Range(0, 1)) = .5
        [PowerSlider(2)]_SpecularPower ("高光强度", Range(0, 1)) = .2
        [Space]
        [Header(Enviroment Reflection)]
        _ReflPower("环境反射强度",Range(0,4)) = 1
        _ReflSmooth("环境反射光泽度增强",Range(1,2)) = 1
        _ReflRotate("环境反射旋转角度",Range(0,360)) = 0
        _SSPR_UVNoiseTex("SSPR扭曲噪声",2D) = "grey" {}
        _SSPR_NoiseIntensity("SSPR噪声强度",Range(-.2,.2)) = 0
        _SSPR_Intensity("SSPR强度",Range(0,2)) = 1
        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)] _ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha ("透明度", Range(0, 1)) = 1
        [Space]
        [Header(Wet)]
        [Toggle(_WET_ON)] _WetOn("开启潮湿",float) = 0
        _WetLevel ("潮湿程度",Range(0,1)) = 0
        _FloodLevel1 ("砖块缝隙水位", Range(0,1)) = 0
        _FloodLevel2 ("水坑水位", Range(0,1)) = 0
        _RainIntensity("降雨强度", Range(0,1)) = 0
        [Header(Ripple)]
        _Density ("密度", Range(0.01,1)) = 1
        _SpreadSpd ("波动速度", Range(1,2)) = 1.25
        _WaveGap ("波的宽度", Range(0.1,0.6)) = 0.256
        _WaveHei ("波动高度", Range(0.1,10)) = 1.17
        _Tile ("尺寸", Range(0.1,2)) = 0.23
        [Header(WaterDistort)]
        _WaterNoiseMap("扰动噪声", 2D) = "white" {}
        _WaterDistortStrength("水面扰动强度",Range(0,1)) = 0.25
        _WaterDistortScale("扰动尺寸",Range(0.01,1)) = 0.25
        _WaterDistortTimeScale("扰动速度",Range(0,5)) = 3
    }
    
    HLSLINCLUDE
    #include "DiffuseCommon.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    #include "../SceneCommonUtil.hlsl"

    sampler2D _MainTex;
    sampler2D _SpecularMaskTex;
    sampler2D _NormalTex;
    // 实时反射图像
    sampler2D _SSPR_RT;
    sampler2D _SSPR_UVNoiseTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _Color;
    half4 _SpecularColor;
    half _Glossiness, _SpecularPower;
    half _SpecularDiffuseToggle;

    half4 _NormalTex_ST;
    half _NormalScale;

    half _ReflPower; // 环境光增强
    half _ReflSmooth; // 环境光光泽度增强
    half _ReflRotate; // 环境反射旋转
    half _SSPR_NoiseIntensity;
    half _SSPR_Intensity;
    half _ScreenDoorAlpha; //点阵透明度
    CBUFFER_END

    DiffuseSurfaceData InitializeDiffuseBumpSurfaceData(DiffuseBumpV2F input)
    {
        DiffuseSurfaceData surfaceData = (DiffuseSurfaceData)0;
        surfaceData.albedo = tex2D(_MainTex, input.uv.xy) * _Color;
        half3 baseColor = lerp(half3(1, 1, 1), surfaceData.albedo.rgb, _SpecularDiffuseToggle);
        surfaceData.specularColor = _SpecularColor.rgb * _SpecularColor.a * baseColor;
        half4 mask = tex2D(_SpecularMaskTex, input.uv.xy);
        surfaceData.smoothness = _Glossiness * mask.r;
        surfaceData.metallic = mask.g;
        surfaceData.specular = _SpecularPower * mask.b;
        surfaceData.diffuseScale = 1;
        surfaceData.occlusion = mask.a;
        half4 normalTexVal = tex2D(_NormalTex, input.uv.zw);
        surfaceData.normalTS = UnpackCustomNormal(normalTexVal, _NormalScale);
        
        surfaceData.envRefScale = normalTexVal.a;
        surfaceData.diffuseScale *= kDielectricSpec.a * (1 - surfaceData.envRefScale * surfaceData.metallic);
        surfaceData.diffuseScale = clamp(surfaceData.diffuseScale, 0.02, 1);

    #if MC_GLOBAL_SSPR_ON
        surfaceData.ssprNoise = tex2D(_SSPR_UVNoiseTex, input.uv.xy) * 2 - 1;
        surfaceData.ssprNoise *= _SSPR_NoiseIntensity;
    #endif
        
        return surfaceData;
    }

    // 环境反射
    half3 SSPREnvironmentReflections(DiffuseInputData inputData, DiffuseSurfaceData surfaceData)
    {
        half3 envRef = 0;
        half nDotV = abs(dot(inputData.normalWS, inputData.viewDirectionWS));
        half3 reflectDir = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    #if MC_GLOBAL_SSPR_ON
        half rotateRad = radians(_ReflRotate);
        reflectDir.xz = Rotate2D(reflectDir.xz, rotateRad);

        half2 ssprUVOffset = surfaceData.ssprNoise + inputData.normalWS.xz * 0.1;
        half3 ssprColor = tex2D(_SSPR_RT, inputData.normalizedScreenSpaceUV + ssprUVOffset).rgb;
        half3 sspr = ssprColor * _SSPR_Intensity * surfaceData.smoothness;
        envRef += sspr;
    #endif
        half perceptualRoughness = 1 - saturate(surfaceData.smoothness * _ReflSmooth);
        half surfaceReduction = 1.0 - 0.6 * Pow3(perceptualRoughness) + 0.08 * Pow4(perceptualRoughness);
        
        half oneMinusReflectivity = kDielectricSpec.a * (1 - surfaceData.envRefScale * surfaceData.metallic);
        half grazingTerm = saturate(2 - perceptualRoughness - oneMinusReflectivity);
        
        half3 dielectricSpec = lerp(kDielectricSpec.rgb, surfaceData.albedo.rgb, surfaceData.metallic);

        half3 env = surfaceReduction * FresnelLerp(dielectricSpec, grazingTerm, nDotV);
    
        perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
        half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;;
        half4 envReflData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
        half3 envReflCol = DecodeHDREnvironment(envReflData, unity_SpecCube0_HDR);
        
        env = surfaceData.envRefScale * surfaceData.occlusion * _ReflPower * envReflCol * env;
        envRef += env;
        return envRef;
    }

    DiffuseBumpV2F DiffseBumpPassVertex(DiffuseVertexInput input)
    {
        DiffuseBumpV2F output = (DiffuseBumpV2F)0;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);

        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        DiffuseNormalInputs normalInput = GetDiffuseNormalInputs(input.normalOS, input.tangentOS);
        half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
        // 对次要光源逐个计算光照(兰伯特模型), 结果相加
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalTex);
        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV); // 处理LightmapUV(拉伸、偏移)
        DIFFUSE_OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        output.positionWS = vertexInput.positionWS;
        output.shadowCoord = GetShadowCoord(vertexInput);
        output.positionCS = vertexInput.positionCS;
        return output;
    }

    half4 ReflectionDiffuseBumpPassFragment(DiffuseBumpV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        DiffuseSurfaceData surfaceData = InitializeDiffuseBumpSurfaceData(input);

        DiffuseInputData inputData = InitializeDiffuseBumpInputData(input, surfaceData);

        ScreenDitherClip(inputData.normalizedScreenSpaceUV, _ScreenDoorAlpha);
        
        half4 color = DiffuseRender(inputData, surfaceData);
        color.a = 1;
        color.rgb += SSPREnvironmentReflections(inputData, surfaceData);
        
        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }

    half4 DiffuseBumpPassFragment(DiffuseBumpV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        DiffuseSurfaceData surfaceData = InitializeDiffuseBumpSurfaceData(input);

        DiffuseInputData inputData = InitializeDiffuseBumpInputData(input, surfaceData);

        ScreenDitherClip(inputData.normalizedScreenSpaceUV, _ScreenDoorAlpha);
        
        half4 color = DiffuseRender(inputData, surfaceData);
        color.a = 1;
        
        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }

    ENDHLSL

    SubShader
    {
        Tags {"RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline" = "UniversalPipeline"}
        LOD 500

        Pass
        {
            Name "MainPass"
            Tags { "LightMode"="UniversalForward" }
            Cull [_Cull]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _WET_ON
            
            #pragma multi_compile_local _ _SCREEN_DOOR_ON
            #pragma multi_compile _ MC_GLOBAL_SSPR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON
            
            #pragma vertex DiffseBumpPassVertex
            #pragma fragment ReflectionDiffuseBumpPassFragment
            
            ENDHLSL
        }

        Pass
        {
            Name "META"
            Tags {"LightMode"="Meta"}
            Cull Off
            HLSLPROGRAM
        
            #pragma vertex DiffuseVertexMeta
            #pragma fragment DiffuseFragmentMeta

            DiffuseMetaV2F DiffuseVertexMeta(DiffuseMetaVertexInput input)
            {
                DiffuseMetaV2F output;
                output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                return output;
            }
            
            half4 DiffuseFragmentMeta(DiffuseMetaV2F input) : SV_Target
            {
                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = tex2D(_MainTex, input.uv).rgb * _Color.rgb;
                return MetaFragment(metaInput);
            }
            
            ENDHLSL
        }
    }
    
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"}
        LOD 100

        Pass
        {
            Name "MainPass"
            Tags { "LightMode"="UniversalForward" }
            Cull [_Cull]

            HLSLPROGRAM
            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma shader_feature_local _WET_ON

            #pragma multi_compile_local _ _SCREEN_DOOR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON
            
            #pragma vertex DiffseBumpPassVertex
            #pragma fragment DiffuseBumpPassFragment
            
            ENDHLSL
        }
    }

    Fallback "MC/OpaqueShadowCaster"
}
