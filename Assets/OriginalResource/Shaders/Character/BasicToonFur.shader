Shader "MC/Character/Toon/BasicToonFur"
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
        _MainTex("固有色 (RGBA)", 2D) = "white" {}
        _ShadowTex("暗面叠加色 (RGB)", 2D) = "white" {}
        [HideInInspector]
        _AlphaScale("透明度", Range(0, 1)) = 1
        [Space]
        [Header(Shading)]
        _ToonStep("明暗线位置", Range(0, 1)) = .5
        _ToonFeather("羽化", Range(0, 1)) = 0
        
        // 毛发
        [Space(20)]
        [Header(Fur)]
        _LayerTex("毛发噪声", 2D) = "white" {}
        _FurLength("毛发长度", Range(0.001, 0.2)) = 0.04
        _FurDensity("长度系数", Range(0, 1)) = 0.5
        _UVOffset("UV偏移", Vector) = (0, 0, 0, 0) 
        _SubTexUV("UV系数", Vector) = (1, 1, 0, 0)
        _FurMask("毛发遮罩", 2D) = "white" {}
        _FurMaskClip("遮罩裁剪值", Range(0.01, 1)) = 0.01
        
        // 风和重力
        _Wind("风力", Vector) = (0, 0, 0, 0)
        _WindSpeed("风速", float) = 1
        _Gravity("重力", Vector) = (0, -0.4, 0)

        // 渲染相关
        _FresnelLV("轮廓光强度", Range(0, 10)) = 0
        _LightFilter("平行光毛发穿透",  Range(-0.5, 0.5)) = 0.0
        _DirLightExposure("平行光曝光度", Range(0.1, 4)) = 1
        _OcclusionColor("遮挡颜色", Color) = (1, 1, 1, 1)
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
        
        [HideInInspector][Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("模板操作", float) = 0
        [HideInInspector]_StencilVal("模板值", float) = 2
        
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "../CommonInclude.hlsl"
    #include "BasicToonInclude.hlsl"
    
    sampler2D _MainTex;
    sampler2D _ShadowTex;
    sampler2D _DyeFlowMask;
    sampler2D _LayerTex;
    sampler2D _FurMask;

    half _FUR_OFFSET;
    
    CBUFFER_START(UnityPerMaterial)
    half _AlphaScale;
    half _ToonStep, _ToonFeather;
    
    half _Dye;
    half3 _Offset1, _Offset2, _Offset3;

    half3 _Wind;
    half _WindSpeed;
    half3 _Gravity;
    half3 _OcclusionColor;

    half _FurLength;
    half _FurDensity;

    half2 _UVOffset;
    half2 _SubTexUV;

    half4 _MainTex_ST;
    half4 _FurMask_ST;
    half _FurMaskClip;

    half _FresnelLV;
    half _LightFilter;

    half _DirLightExposure;
    CBUFFER_END
    
    void DyeColor(inout half3 color, half2 uv)
    {
        [branch]if(_Dye == 1)
        {
            half3 dyeMask = tex2D(_DyeFlowMask, uv).rgb;
            half4 dyeSwitchAndIntensity = CaclulateDyeSwitchAndIntensity(dyeMask);
            half intensity = dyeSwitchAndIntensity.a;
            half3 offsetHSV = _Offset1 * dyeSwitchAndIntensity.r + _Offset2 * dyeSwitchAndIntensity.g + _Offset3 * dyeSwitchAndIntensity.b;
    
            half3 hsv = RgbToHsv(color);
            hsv.x = offsetHSV.x;
            hsv.y = saturate(hsv.y + offsetHSV.y);
            hsv.z = saturate(hsv.z + offsetHSV.z);
            color = lerp(color, HsvToRgb(hsv), intensity);
        }
    }

    float3 WindAndGravity(float3 pos)
    {
        half3 gravity = TransformWorldToObjectDir(_Gravity + sin(_WindSpeed * _Time.y) * _Wind, false);
        half k = pow(_FUR_OFFSET, 3);
        return pos + gravity * k * _FurLength;
    }
    ENDHLSL
    
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" "Queue" = "AlphaTest"}
        Cull Back
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        
        Stencil
        {
            Ref [_StencilVal]
            Comp Always
            Pass [_StencilOp]
        }

        Pass //0
        {
            Tags {"LightMode" = "FurRendererBase" "Queue" = "Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True"}
            Blend [_SrcBlend] [_DstBlend], One OneMinusSrcAlpha
            ZWrite [_ZWrite]
            
            HLSLPROGRAM
            
            // #pragma multi_compile_fog
            
            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex Vertex   
            #pragma fragment Fragment 
            
            struct VertexInput
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                half2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            VertexOutput Vertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput) 0;
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }
            
            half4 Fragment(VertexOutput input) : SV_Target
            {
                // 固有色
                half3 albedo = tex2D(_MainTex, input.uv).rgb;
            
                half3 normalWS = normalize(input.normalWS);
                Light mainLight = GetMainLight();
                
                //染色处理
                DyeColor(_Dye, _DyeFlowMask, albedo, input.uv, _Offset1, _Offset2, _Offset3);
            
                half nDotL = max(dot(mainLight.direction, normalWS), 0);
                
                // 暗面叠加色
                half3 shadow = albedo * tex2D(_ShadowTex, input.uv).rgb;
                half3 newAlbedo = CalcToonColor(albedo, shadow, nDotL, _ToonStep, _ToonFeather);

                // 环境光
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * newAlbedo;
                // 漫反射
                half3 diffuse = mainLight.color * newAlbedo * nDotL;
                // 逐像素多光源
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    nDotL = max(dot(light.direction, normalWS), 0);
                    diffuse += light.color * newAlbedo * nDotL;
                }
                return half4(ambient + diffuse, _AlphaScale);
            }
            ENDHLSL
        }

        Pass //1
        {
            Tags{"LightMode" = "FurRendererLayer"}
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            
            struct VertexInput
            {
                float3 positionOS : POSITION;
                half3 normalOS : NORMAL;
                half2 texcoord : TEXCOORD0;
            };
            
            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                half4 uv : TEXCOORD0;
                half4 colorAndNDotL : TEXCOORD1;
                half2 oriUV : TEXCOORD2;
            };

            VertexOutput Vertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput) 0;
                // 偏移UV
                half2 uvOffset = _UVOffset.xy * _FUR_OFFSET * _FurLength;
                uvOffset *= 0.1;
                // 顶点外扩
                float3 newPos = input.positionOS.xyz + input.normalOS * _FurLength * _FUR_OFFSET;
                // 计算重力和风
                newPos = WindAndGravity(newPos);
            
                output.positionCS = TransformObjectToHClip(newPos);
                output.oriUV = input.texcoord;
                // 偏移UV
                output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex) + uvOffset / _SubTexUV;
                output.uv.zw = TRANSFORM_TEX(input.texcoord, _MainTex) * _SubTexUV + uvOffset;
                
                half3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float3 positionWS = mul(UNITY_MATRIX_M, float4(newPos, 1)).xyz;
                
                half3 viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
                Light mainLight = GetMainLight();
                mainLight.color *= CHARACTER_LIGHT_INTENSITY;
            
                // 环境光遮蔽
                half occlusion = _FUR_OFFSET + 0.04; 
            
                // 环境色
                half3 sh = max(0, SampleSH(normalWS));
                half3 color = sh;
            
                color = lerp(_OcclusionColor * color, color, occlusion);
            
                // 边缘光
                half fresnel = 1 - max(0, dot(normalWS, viewDirWS));
                half3 rimLight = fresnel * occlusion * _FresnelLV * (mainLight.color + sh);
                // 平行光
                half nDotL = dot(mainLight.direction, normalWS);
                // _LightFilter控制平行光扩散，模拟毛发特性
                half dirLight = saturate(nDotL + _LightFilter + _FUR_OFFSET);
                half3 diffuse = dirLight * mainLight.color * _DirLightExposure;

                // 逐顶点多光源
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, positionWS);
                    nDotL = dot(light.direction, normalWS);
                    dirLight = saturate(nDotL + _LightFilter + _FUR_OFFSET);
                    diffuse += dirLight * light.color * _DirLightExposure;
                    rimLight += fresnel * occlusion * _FresnelLV * light.color;
                }

                color += diffuse;
                color += rimLight;
                output.colorAndNDotL.xyz = color;
                output.colorAndNDotL.w = nDotL;
                return output;
            }
            
            half4 Fragment(VertexOutput input) : SV_Target
            {
                // 采样毛发遮罩纹理 并根据遮罩裁剪值判断是否放弃该片段
                half2 maskUV = input.oriUV * _FurMask_ST.xy + _FurMask_ST.zw;
                half furMask = tex2D(_FurMask, maskUV).r;
                clip(furMask - _FurMaskClip);
                
                // 固有色
                half3 albedo = tex2D(_MainTex, input.uv.xy).rgb;
                // 毛发形状噪声
                half noise = tex2D(_LayerTex, input.uv.zw).r;
                // 外扩毛发粗细控制
                half alpha = clamp(noise - _FUR_OFFSET * _FUR_OFFSET * _FurDensity, 0, 1);
                clip(alpha - 0.001);
            
                DyeColor(albedo, input.uv.xy);

                // 暗面叠加色
                half3 shadow = albedo * tex2D(_ShadowTex, input.uv.xy).rgb;
                half nDotL = saturate(input.colorAndNDotL.w);
                half3 newAlbedo = CalcToonColor(albedo, shadow, nDotL, _ToonStep, _ToonFeather);
                half3 col = newAlbedo * input.colorAndNDotL.xyz;
                return half4(col, alpha * _AlphaScale);
            }
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}
