Shader "MC/Scene/Diffuse_Bump_Transparent"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色", Color) = (1,1,1,1)
        _MainTex ("固有色贴图 (RGBA)", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("剔除模式", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcFactor ("源颜色", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstFactor ("目标颜色", Float) = 10
        [Space]
        [Header(Normals)]
        _NormalTex ("法线贴图(RG:法线; B:自发光遮罩; A:环境反射遮罩)", 2D) = "bump" {}
        _NormalScale ("法线贴图强度", Range(0, 2)) = 1
        [Space]
        [Header(Blinn Phong Specular)]
        [NoScaleOffset] _SpecularMaskTex ("高光强度/光滑度遮罩 (R/RG)", 2D) = "black" {}
        [HDR] _SpecularColor ("高光叠加色", Color) = (1,1,1,1)
        [Toggle] _SpecularDiffuseToggle(":: 高光颜色叠加固有色", Float) = 0
        [PowerSlider(2)]_Glossiness ("光滑度", Range(0, 1)) = .5
        [PowerSlider(2)]_SpecularPower ("高光强度", Range(0, 1)) = .2
        [Space]
        [Header(Enviroment Reflection)]
        [Toggle(_ENVREFLECT_ON)] _ENVREFLECTToggle("开启环境反射", float) = 0
        _ReflPower("环境反射强度",Range(1,4)) = 1
        _ReflSmooth("环境反射光泽度增强",Range(1,10)) = 1
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)] _EmissionToggle(":: 开启自发光", Float) = 0
        [HDR]_EmissionColor ("自发光叠加色", Color) = (1,1,1,1)
        _EmissionPower ("自发光强度", Range(0, 2)) = 1
        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)] _ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha ("透明度", Range(0, 1)) = 1
    }
    
    HLSLINCLUDE
    #include "DiffuseCommon.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    #include "../SceneCommonUtil.hlsl"

    sampler2D _MainTex;
    sampler2D _SpecularMaskTex;
    sampler2D _NormalTex;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _Color;
    half4 _SpecularColor;
    half _Glossiness, _SpecularPower;
    half _SpecularDiffuseToggle;

    half3 _EmissionColor;
    half _EmissionPower;

    half4 _NormalTex_ST;
    half _NormalScale;


    half _ReflPower; // 环境光增强
    half _ReflSmooth; // 环境光光泽度增强
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
        
    #if _EMISSION_ON
        surfaceData.emission = surfaceData.albedo.rgb * _EmissionColor * _EmissionPower * normalTexVal.b;
    #endif
        
    #if _ENVREFLECT_ON
        surfaceData.envRefScale = normalTexVal.a;
        surfaceData.diffuseScale *= kDielectricSpec.a * (1 - surfaceData.envRefScale * surfaceData.metallic);
        surfaceData.diffuseScale = clamp(surfaceData.diffuseScale, 0.02, 1);
    #endif
        return surfaceData;
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

    half4 DiffuseTransparentBumpPassFragment(DiffuseBumpV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        DiffuseSurfaceData surfaceData = InitializeDiffuseBumpSurfaceData(input);
    
        DiffuseInputData inputData = InitializeDiffuseBumpInputData(input, surfaceData);
    
        ScreenDitherClip(inputData.normalizedScreenSpaceUV, _ScreenDoorAlpha);
            
        half4 color = DiffuseRender(inputData, surfaceData);
    
        color.rgb += EnvironmentReflections(inputData, surfaceData, _ReflSmooth, _ReflPower);

        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }
    
    ENDHLSL
    
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
        LOD 100

        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            Name "Transparent"
            Cull [_Cull]
            ZWrite Off
            Blend [_SrcFactor] [_DstFactor]

            HLSLPROGRAM

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _ENVREFLECT_ON
            
            #pragma multi_compile_local _ _SCREEN_DOOR_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING

            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma skip_variants VERTEXLIGHT_ON SHADOWS_SCREEN
            
            #pragma vertex DiffseBumpPassVertex
            #pragma fragment DiffuseTransparentBumpPassFragment
            
            ENDHLSL
        }

        Pass
        {
            Name "META"
            Tags {"LightMode"="Meta"}
            Cull Off
            HLSLPROGRAM
            #pragma shader_feature_local _EMISSION_ON
            
            #pragma vertex DiffuseBumpVertexMeta
            #pragma fragment DiffuseBumpFragmentMeta

            DiffuseMetaV2F DiffuseBumpVertexMeta(DiffuseMetaVertexInput input)
            {
                DiffuseMetaV2F output;
                output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
            #if _EMISSION_ON
                output.emissionUV = TRANSFORM_TEX(input.texcoord, _NormalTex);
            #endif
                return output;
            }

            half4 DiffuseBumpFragmentMeta(DiffuseMetaV2F input) : SV_Target
            {
                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = tex2D(_MainTex, input.uv).rgb * _Color.rgb;
            #if _EMISSION_ON
                half emissionMask = tex2D(_NormalTex, input.emissionUV).b;
                metaInput.Emission = metaInput.Albedo * _EmissionColor * _EmissionPower * emissionMask;
            #endif
                return MetaFragment(metaInput);
            }

            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}
