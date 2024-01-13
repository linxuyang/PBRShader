Shader "MC/Scene/Tree"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color("叠加色", Color) = (1, 1, 1, 1)
        _MainTex("固有色贴图 (RGBA)", 2D) = "white" {}
        _Cutoff("透明度裁剪", Range(0, 1)) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("剔除模式", Float) = 2
        [Space]
        [Header(Normals)]
        _NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("法线贴图强度", Range(0, 2)) = 1
        [Space]
        [Header(Emission)]
        [Toggle(_EMISSION_ON)]_EmissionToggle(":: 开启自发光", Float) = 0
        [HDR]_EmissionColor("自发光叠加色", Color) = (1, 1, 1, 1)
        _EmissionPower("自发光强度", Range(0, 2)) = 1
        [Space]
        [Header(Shake)]
        [Toggle(_SHAKE_ON)]_Shake(":: 开启抖动", Float) = 0
        _ShakeSpeed("抖动速度", Range(0, 10)) = 1
        _ShakeStrength("抖动强度", Range(0, 1)) = 1
        _WindSpeed("风速", Range(0, 10)) = 1
        _WindRandom("风力", Range(0, 1)) = 1
        _ShakeGradual("底部限定", Range(0, 1)) = 1
        [Space]
        [Header(Screen Door Dither Transparency)]
        [Toggle(_SCREEN_DOOR_ON)]_ScreenDoorToggle(":: 开启透明", Float) = 0
        _ScreenDoorAlpha("透明度", Range(0, 1)) = 1
        [Space]
        [Toggle]_TREEDark(":: 开启内部暗部", Float) = 0
        _DarkStrength("内部阴暗度", Range(0, 10)) = 0
    }
    
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    #include "../SceneCommonUtil.hlsl"
    #include "../../CommonInclude.hlsl"

    sampler2D _MainTex;
    sampler2D _NormalTex;

    half3 _LightningColor;

    CBUFFER_START(UnityPerMaterial)

    half4 _MainTex_ST;
    half4 _Color;

    half _Cutoff;

    half3 _EmissionColor;
    half _EmissionPower;

    half4 _NormalTex_ST;
    half _NormalScale;

    // 树的摇动效果
    half _ShakeSpeed;       // 随机摇动速度
    half _ShakeStrength;    // 随机摇动强度
    half _WindSpeed;        // 风速(定向摇动)
    half _WindRandom;       // 风力(定向摇动)
    half _ShakeGradual;     // 控制底部摇动

    // 树中心的昏暗效果
    half _TREEDark; // 内部阴暗开关
    half _DarkStrength;       // 内部阴暗程度
    half _ScreenDoorAlpha; //点阵透明度
    CBUFFER_END

    struct TreeVertexInput
    {
        float4 positionOS : POSITION;
        half3 normalOS : NORMAL;
        half4 tangentOS : TANGENT;
        half4 color : COLOR;
        half2 texcoord : TEXCOORD0;
        float2 lightmapUV : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct TreeV2F
    {
        float4 positionCS : SV_POSITION;
        half4 uv : TEXCOORD0; // xy:主纹理UV; zw:法线贴图UV
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1); // 烘焙物体:光照贴图, 动态物体:光照探针
        float4 positionWS : TEXCOORD2; // xyz:顶点坐标(世界); w:树叶内部昏暗参数
        half3 normalWS : TEXCOORD3; // 法线(世界)
        half3 viewDirWS : TEXCOORD4; // 观察方向(世界)
        half4 fogFactorAndVertexLight : TEXCOORD6; // x: 雾效, yzw: 次要光源(逐顶点)
        float4 shadowCoord : TEXCOORD7; // 阴影纹理坐标
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct TreeSurfaceData
    {
        half4 albedo;
        half metallic;
        half3 emission;
        half envRefScale; // 环境反射强度
        half2 ssprNoise; // 实时反射UV扰动
    };

    TreeSurfaceData InitializeTreeSurfaceData(TreeV2F input)
    {
        TreeSurfaceData surfaceData = (TreeSurfaceData)0;
        surfaceData.albedo = tex2D(_MainTex, input.uv.xy) * _Color;
        surfaceData.metallic = 0;
        half4 normalTexVal = tex2D(_NormalTex, input.uv.zw);
        
    #if _EMISSION_ON
        surfaceData.emission = surfaceData.albedo.rgb * _EmissionColor * _EmissionPower * normalTexVal.b;
    #endif
        
        return surfaceData;
    }

    struct TreeInputData
    {
        float4 positionWS;
        half3 normalWS;
        half3 viewDirectionWS;
        float4 shadowCoord;
        half fogCoord;
        half3 vertexLighting; // 实时多光源的Lambert光照结果的叠加
        half3 bakedGI; // 全局照明(静态物体是lightmap, 动态物体是lightProbe)
        half2 normalizedScreenSpaceUV;
        half4 shadowMask;
    };
    
    TreeInputData InitializeTreeInputData(TreeV2F input)
    {
        TreeInputData inputData = (TreeInputData)0;
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

    half4 TreeRender(TreeInputData inputData, TreeSurfaceData surfaceData)
    {
        // 获取主光源
        Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS.xyz, inputData.shadowMask);
        // 实时与烘焙光照混合
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
        // 主光源叠加上闪电
        mainLight.color += _LightningColor;
        // 主光源叠加阴影衰减以及距离衰减
        half3 attenuatedLightColor = mainLight.color * mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    
        // 漫反射 + 环境光(光照贴图或光照探针)
        half3 diffuseColor = inputData.bakedGI/* + LightingLambert(attenuatedLightColor, mainLight.direction,
                                                                 inputData.normalWS)*/;

        // 逐像素多光源
    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS.xyz, inputData.shadowMask);
            half3 attenLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
            diffuseColor += LightingLambert(attenLightColor, light.direction, inputData.normalWS);
        }
    #endif
        // 逐顶点多光源
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        diffuseColor += inputData.vertexLighting;
    #endif
        // 漫反射 + 高光反射 + 自发光
        half3 finalColor = diffuseColor * surfaceData.albedo.rgb + surfaceData.emission;
        
        // 树的内部昏暗度
        finalColor.rgb += surfaceData.albedo.rgb * mainLight.color * inputData.positionWS.w;
        return half4(finalColor, 1);
    }

    float3 Shake(float3 oriPositionWS, half3 vertexColor, half3 positionOS, half2 uv)
    {
        half magicHalf = 43758.5453;
        half2 magicHalf2 = half2(12.9898, 78.233);
        half nois = frac(sin(dot(uv, magicHalf2)) * magicHalf);
        half noisX = frac(sin(dot(oriPositionWS.xz, magicHalf2)) * magicHalf);
        half noisY = frac(sin(dot(oriPositionWS.xy, magicHalf2)) * magicHalf) * 0.25;
        half noisZ = frac(sin(dot(oriPositionWS.zy, magicHalf2)) * magicHalf) * 0.5;
        
        half groupid = vertexColor.r + vertexColor.g + vertexColor.b * 0.5;
        half Wt = sin(_Time.y * _WindSpeed + oriPositionWS.z);
        // 随风向摇动
        half t1 = sin((nois + Wt * 10) * groupid * 3.1415 / 5) * _WindRandom * 0.125;
        // 自身随机摇动
        half t2 = sin(_Time.y * _ShakeSpeed * 10 * noisX * noisZ * groupid * 3.1415 / 8) * _ShakeStrength * noisY;
        // _ShakeGradual取0存在精度问题，导致_ShakeGradual实际为极小的负值，最终产生一个极大的y偏移
        half y = pow(smoothstep(-1, 1, positionOS.y), saturate(_ShakeGradual) + 0.01);
        float3 shakedPos = oriPositionWS;
        shakedPos.xz += t1 * y;
        shakedPos.xyz += t2 * y;
        return shakedPos;
    }
    
    TreeV2F TreeVertex(TreeVertexInput input)
    {
        TreeV2F output = (TreeV2F)0;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);

        float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
        // 树的摇动
        #if _SHAKE_ON
            positionWS = Shake(positionWS, input.color, input.positionOS, input.texcoord);
        #endif
        // 树的内部昏暗度计算
        output.positionWS.w = input.tangentOS.w * _DarkStrength * _TREEDark;
        
        float4 positionCS = TransformWorldToHClip(positionWS);
        half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
        // 对次要光源逐个计算光照(兰伯特模型), 结果相加
        half3 vertexLight = VertexLighting(positionWS, normalInput.normalWS);
        half fogFactor = ComputeFogFactor(positionCS.z);

        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalTex);
        output.normalWS = normalInput.normalWS;
        output.viewDirWS = viewDirWS;

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV); // 处理LightmapUV(拉伸、偏移)
        DIFFUSE_OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        output.positionWS.xyz = positionWS;
        output.shadowCoord = TransformWorldToShadowCoord(positionWS);
        output.positionCS = positionCS;
        return output;
    }

    half4 TreeFragment(TreeV2F input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        TreeSurfaceData surfaceData = InitializeTreeSurfaceData(input);

        clip(surfaceData.albedo.a - _Cutoff);

        TreeInputData inputData = InitializeTreeInputData(input);

        ScreenDitherClip(inputData.normalizedScreenSpaceUV, _ScreenDoorAlpha);
        
        half4 color = TreeRender(inputData, surfaceData);

        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        return color;
    }

    ///////////////////////////// META相关begin

    struct TreeMetaVertexInput
    {
        float4 positionOS : POSITION;
        half2 texcoord : TEXCOORD0;
    };

    struct TreeMetaV2F
    {
        float4 positionCS : SV_POSITION;
        half4 uv : TEXCOORD0;
    };

    TreeMetaV2F TreeVertexMeta(TreeMetaVertexInput input)
    {
        TreeMetaV2F output = (TreeMetaV2F)0;
        output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
        
    #if _EMISSION_ON
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalTex);
    #endif
        return output;
    }

    half4 TreeFragmentMeta(TreeMetaV2F input) : SV_Target
    {
        MetaInput metaInput = (MetaInput)0;
        metaInput.Albedo = tex2D(_MainTex, input.uv.xy).rgb * _Color.rgb;

    #if _EMISSION_ON
        half4 normalTexVal = tex2D(_NormalTex, input.uv.zw);
        metaInput.Emission = metaInput.Albedo * _EmissionColor * _EmissionPower * normalTexVal.b;
    #endif
        return MetaFragment(metaInput);
    }

    ///////////////////////////// META相关end

    ENDHLSL

    SubShader
    {
        Tags {"RenderType"="TransparentCutout" "Queue" = "AlphaTest" "RenderPipeline" = "UniversalPipeline"}
        LOD 500

        Pass
        {
            Name "MainPass"
            Tags {"LightMode"="UniversalForward"}
            Cull [_Cull]

            HLSLPROGRAM

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _SHAKE_ON
            
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
            #pragma skip_variants VERTEXLIGHT_ON SHADOWS_SCREEN

            #pragma vertex TreeVertex
            #pragma fragment TreeFragment
            
            ENDHLSL
        }
        
        Pass
        {
            Name "META"
            Tags {"LightMode" = "Meta"}
            Cull Off
            HLSLPROGRAM
            #pragma shader_feature_local _EMISSION_ON
            
            #pragma vertex TreeVertexMeta
            #pragma fragment TreeFragmentMeta
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex CutoffShadowVertex
            #pragma fragment CutoffShadowFragment

            float3 _LightDirection;
            
            struct ShadowCasterVertexInput
            {
                float4 positionOS   : POSITION;
                half2 texcoord : TEXCOORD0;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct CutoffShadowCasterVertexOutput
            {
                float4 positionCS   : SV_POSITION;
                half2 uv : TEXCOORD0;
            };
            
            float4 GetShadowPositionHClip(ShadowCasterVertexInput input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            
                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
            
                return positionCS;
            }

            CutoffShadowCasterVertexOutput CutoffShadowVertex(ShadowCasterVertexInput input)
            {
                CutoffShadowCasterVertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                output.positionCS = GetShadowPositionHClip(input);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                return output;
            }
            
            half4 CutoffShadowFragment(CutoffShadowCasterVertexOutput input) : SV_TARGET
            {
                half4 color = tex2D(_MainTex, input.uv) * _Color;
                clip(color.a - _Cutoff);
                return 1;
            }
            ENDHLSL
        }
    }

    SubShader
    {
        Tags {"RenderType"="TransparentCutout" "Queue" = "AlphaTest" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "MainPass"
            Tags {"LightMode" = "UniversalForward"}
            Cull [_Cull]

            HLSLPROGRAM

            #pragma shader_feature_local _EMISSION_ON
            #pragma shader_feature_local _SHAKE_ON

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
            #pragma skip_variants VERTEXLIGHT_ON SHADOWS_SCREEN
            
            #pragma vertex TreeVertex
            #pragma fragment TreeFragment
            
            ENDHLSL
        }
    }

    
}