Shader "Custom/PBR"
{
    Properties
    {
        [MainTexture] _BaseMap("基础纹理", 2D) = "white" {}
        [MainColor] _BaseColor("基础颜色", Color) = (1, 1, 1, 1)
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5
        _Metallic("金属度", Range(0.0, 1.0)) = 0.0
        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.5
        _NormalScale("法线纹理强度", Range(-2.0, 2.0)) = 1.0
        _NormalMetalSmoothMap("法线(RG) 金属度(B) 光滑度(A)", 2D) = "white" {}
        _AoSource("环境光遮蔽来源", Float) = 0
        _OcclusionStrength("AO", Range(0.0, 1.0)) = 1.0
        [HDR] _EmissionColor("自发光", Color) = (0, 0, 0)
        _EmissionAOMap("自发光(RGB) AO(A)", 2D) = "white" {}
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
        _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

    TEXTURE2D(_BaseMap);
    SAMPLER(sampler_BaseMap);
    TEXTURE2D(_NormalMetalSmoothMap);
    SAMPLER(sampler_NormalMetalSmoothMap);
    TEXTURE2D(_EmissionAOMap);
    SAMPLER(sampler_EmissionAOMap);
    
    half3 _LightDirection;

    CBUFFER_START(UnityPerMaterial)
    half4 _BaseMap_ST;
    half4 _BaseColor;
    half _Cutoff;
    half _Metallic;
    half _Smoothness;
    half _NormalScale;
    half3 _EmissionColor;
    half _OcclusionStrength;
    half _Surface;
    CBUFFER_END

    struct VertexInput
    {
        float4 positionOS : POSITION;
        half3 normalOS : NORMAL;
        half4 tangentOS : TANGENT;
        half2 texcoord : TEXCOORD0;
        half2 lightmapUV : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct VertexOutput
    {
        half2 uv : TEXCOORD0;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
        float3 positionWS : TEXCOORD2;
        half3 normalWS : TEXCOORD3;
        half4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
        half3 viewDirWS : TEXCOORD5;
        half4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light
        #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            float4 shadowCoord : TEXCOORD7;
        #endif
        float4 positionCS : SV_POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    inline SurfaceData InitPBRSurfaceData(half2 uv)
    {
        SurfaceData outSurfaceData;
        half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
        outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;

    #if defined(_ALPHATEST_ON)
        clip(outSurfaceData.alpha - _Cutoff);
    #endif

        outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

        half3 normalTS = half3(0, 0, 1);
        outSurfaceData.metallic = _Metallic;
        outSurfaceData.smoothness = _Smoothness;
        
    #if defined(_NORMAL_METAL_SMOOTH_MAP)
        half4 normalMetallicSmooth = SAMPLE_TEXTURE2D(_NormalMetalSmoothMap, sampler_NormalMetalSmoothMap, uv);
        outSurfaceData.metallic *= normalMetallicSmooth.b;
        outSurfaceData.smoothness *= normalMetallicSmooth.a;
        normalTS.xy = normalMetallicSmooth.xy * 2.0 - 1.0;
        normalTS.xy *= _NormalScale;
        normalTS.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy))));
    #endif
        
        outSurfaceData.normalTS = normalTS;

        half4 emissionAO = half4(1, 1, 1, 1);
    #if defined(_EMISSION_AO_MAP)
        emissionAO = SAMPLE_TEXTURE2D(_EmissionAOMap, sampler_EmissionAOMap, uv);
    #endif
        
    #if defined(_AO_ALBEDO_CHANGE_A)
        emissionAO.a = albedoAlpha.a;//取自基础贴图
    #elif !defined(_AO_EMISSION_CHANGE_A) && !defined(_AO_ALBEDO_CHANGE_A)
        emissionAO.a = 1;//两个贴图都不取，即None
    #endif
        outSurfaceData.occlusion = 1.0 - _OcclusionStrength + emissionAO.a * _OcclusionStrength;
        outSurfaceData.emission = emissionAO.rgb * _EmissionColor;
    
        outSurfaceData.clearCoatMask = 0.0h;
        outSurfaceData.clearCoatSmoothness = 0.0h;
        outSurfaceData.specular = 0;
        
        return outSurfaceData;
    }

    inline InputData InitPBRInputData(VertexOutput input, half3 normalTS)
    {
        InputData inputData = (InputData)0;
    
        inputData.positionWS = input.positionWS;
    
        half3 viewDirWS = SafeNormalize(input.viewDirWS);
        float sgn = input.tangentWS.w;      // should be either +1 or -1
        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
        inputData.normalWS = normalize(inputData.normalWS);
        inputData.viewDirectionWS = viewDirWS;
    
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
        inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif
    
        inputData.fogCoord = input.fogFactorAndVertexLight.x;
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
        inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
        inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

        return inputData;
    }

    inline void InitBRDFData(half3 albedo, half metallic, half smoothness, out BRDFData outBRDFData)
    {
        half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
        half reflectivity = 1.0 - oneMinusReflectivity;
        half3 brdfDiffuse = albedo * oneMinusReflectivity;
        half3 brdfSpecular = lerp(kDieletricSpec.rgb, albedo, metallic);
        outBRDFData.diffuse = brdfDiffuse;
        outBRDFData.specular = brdfSpecular;
        outBRDFData.reflectivity = reflectivity;
        
        outBRDFData.perceptualRoughness = 1.0 - smoothness;
        outBRDFData.roughness           = max(outBRDFData.perceptualRoughness * outBRDFData.perceptualRoughness, HALF_MIN_SQRT);
        outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
        outBRDFData.grazingTerm         = saturate(smoothness + reflectivity);
        outBRDFData.normalizationTerm   = outBRDFData.roughness * 4.0h + 2.0h;
        outBRDFData.roughness2MinusOne  = outBRDFData.roughness2 - 1.0h;
    }

    half3 IndirectColor(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
    {
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        half NoV = saturate(dot(normalWS, viewDirectionWS));
        half fresnelTerm = Pow4(1.0 - NoV);
    
        half3 indirectDiffuse = bakedGI * occlusion;
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);
    
        half3 color = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
    
        return color;
    }

    half3 DirectColor(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
    {
        half NdotL = saturate(dot(normalWS, light.direction));
        half3 radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation * NdotL);
    
        half3 brdf = brdfData.diffuse;
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, light.direction, viewDirectionWS);
        return brdf * radiance;
    }

    half4 PBRFragment(InputData inputData, SurfaceData surfaceData)
    {
        BRDFData brdfData;
    
        InitBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, brdfData);
    
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif
    
        Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
        
        half3 color = IndirectColor(brdfData, inputData.bakedGI, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);
        
        color += DirectColor(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);
    
    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
            color += DirectColor(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif
    
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif
    
        color += surfaceData.emission;
    
        return half4(color, surfaceData.alpha);
    }

    VertexOutput ForwardPassVertex(VertexInput input)
    {
        VertexOutput output = (VertexOutput)0;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

        // normalWS and tangentWS already normalize.
        // this is required to avoid skewing the direction during interpolation
        // also required for per-vertex lighting and SH evaluation
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

        half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

        output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

        // already normalized from normal transform to WS.
        output.normalWS = normalInput.normalWS;
        output.viewDirWS = viewDirWS;
        half sign = input.tangentOS.w * GetOddNegativeScale();
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
        output.tangentWS = tangentWS;

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
        OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

        output.positionWS = vertexInput.positionWS;

        #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = GetShadowCoord(vertexInput);
        #endif

        output.positionCS = vertexInput.positionCS;

        return output;
    }

    half4 ForwardPassFragment(VertexOutput input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
    
        SurfaceData surfaceData = InitPBRSurfaceData(input.uv);
    
        InputData inputData = InitPBRInputData(input, surfaceData.normalTS);
    
        half4 color = PBRFragment(inputData, surfaceData);
    
        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        color.a = OutputAlpha(color.a, _Surface);
    
        return color;
    }

    struct ShadowCasterVertexInput
    {
        float4 positionOS : POSITION;
        half3 normalOS : NORMAL;
        half2 texcoord : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct ShadowCasterVertexOutput
    {
        half2 uv : TEXCOORD0;
        float4 positionCS : SV_POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
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
    
    ShadowCasterVertexOutput ShadowPassVertex(ShadowCasterVertexInput input)
    {
        ShadowCasterVertexOutput output;
        UNITY_SETUP_INSTANCE_ID(input);
    
        output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
        output.positionCS = GetShadowPositionHClip(input);
        return output;
    }
    
    half4 ShadowPassFragment(ShadowCasterVertexOutput input) : SV_TARGET
    {
    #if defined(_ALPHATEST_ON)
        half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
        alpha *= _BaseColor.a;
        clip(alpha - _Cutoff);
    #endif
        return 0;
    }

    struct MetaVertexInput
    {
        float4 positionOS : POSITION;
        half2 texcoord0 : TEXCOORD0;
        half2 texcoord1 : TEXCOORD1;
        half2 texcoord2 : TEXCOORD2;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    
    struct MetaVertexOutput
    {
        half2 uv : TEXCOORD0;
        float4 positionCS : SV_POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    inline void InitMetaSurfaceData(float2 uv, out SurfaceData outSurfaceData)
    {
        outSurfaceData = (SurfaceData)0;
        half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
        outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;;

    #if defined(_ALPHATEST_ON)
        clip(outSurfaceData.alpha - _Cutoff);
    #endif

        outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

        outSurfaceData.metallic = _Metallic;
        outSurfaceData.smoothness = _Smoothness;
        
    #if defined(_NORMAL_METAL_SMOOTH_MAP)
        half4 normalMetallicSmooth = SAMPLE_TEXTURE2D(_NormalMetalSmoothMap, sampler_NormalMetalSmoothMap, uv);
        outSurfaceData.metallic *= normalMetallicSmooth.b;
        outSurfaceData.smoothness *= normalMetallicSmooth.a;
    #endif
        
        outSurfaceData.emission = _EmissionColor;
    #if defined(_EMISSION_AO_MAP)
        outSurfaceData.emission *= SAMPLE_TEXTURE2D(_EmissionAOMap, sampler_EmissionAOMap, uv).rgb;
    #endif
    }

    MetaVertexOutput MetaPassVertex(MetaVertexInput input)
    {
        MetaVertexOutput output;
        output.positionCS = MetaVertexPosition(input.positionOS, input.texcoord1, input.texcoord2, unity_LightmapST, unity_DynamicLightmapST);
        output.uv = TRANSFORM_TEX(input.texcoord0, _BaseMap);
        return output;
    }
    
    half4 MetaPassFragment(MetaVertexOutput input) : SV_Target
    {
        SurfaceData surfaceData;
        InitMetaSurfaceData(input.uv, surfaceData);
    
        BRDFData brdfData;
        InitBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, brdfData);
    
        MetaInput metaInput;
        metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
        metaInput.SpecularColor = 0;//surfaceData.specular;
        metaInput.Emission = surfaceData.emission;
    
        return MetaFragment(metaInput);
    }
    ENDHLSL

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "ShaderModel"="4.5"
        }
        LOD 300

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
            
            HLSLPROGRAM
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _NORMAL_METAL_SMOOTH_MAP
            #pragma shader_feature_local_fragment _EMISSION_AO_MAP
            #pragma shader_feature_local_fragment _AO_ALBEDO_CHANGE_A
            #pragma shader_feature_local_fragment _AO_EMISSION_CHANGE_A
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            
            #pragma vertex ForwardPassVertex
            #pragma fragment ForwardPassFragment
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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            ENDHLSL
        }
        
        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            #pragma shader_feature_local_fragment _EMISSION_AO_MAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "PBRShader"
}