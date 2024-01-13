Shader "MC/Scene/WaterNew"
{
    Properties
    {
        [Header(WaterNormal)]
        _NormalTex ("海水法线(影响海浪)", 2D) = "bump" {}
        _NormalScale( "海水法线强度", Range(0, 2)) = 1
        [Header(Refraction)]
        _RefractionDisort("扭曲强度(和法线强度一起作用)", Range(0, 1)) = 0.1
        [Header(Wind)]
        _WindDir("风力方向（世界坐标轴）", Vector) = (0.01, 0, 0)
        [Header(Vertex Wave)]
        [Toggle(_VERTEX_WAVE_ON)]_VertexWaveToggle("顶点波动开关", float) = 0
        _WaveScale("波动振幅", Range(0.0, 0.1)) = 0.04
        _WaveSpeed("波动速度", Range(0.0, 1)) = 0.5
        [PowerSlider(2)]_WaveFrequency("波动频率", Range(1, 4)) = 2
        [Header(FakeLight Motion)]
        [Toggle(FAKELIGHT_ON)]_FakeLight ("伪光", Float) = 1
        _FakeLightRotation("伪光方向", Vector) = (30, 0, 0)
        _FakeLightColor("伪光颜色", Color) = (1, 1, 1, 1)
        _FakeLightColorStrength("伪光强度", Range(0.1, 4)) = 1
        [Header(RealTime Reflection)]
        [KeywordEnum(NONE, REALTIME, CUBE,IBL)]_Reflection("反射类型", float) = 0
        [NoScaleOffset]_IBLTex("IBL反射贴图", CUBE) = "black" {}
        _IblLuminance("反射贴图亮度", Range(0.01, 5)) = 1
        [Header(Gradience)]
        _ShallowColor("浅水颜色", Color) = (0.06, 0.66, 0.68, 0.0)
        _DeepColor ("深水颜色", Color) = (0.09, 0.4, 0.56, 1)
        _DepthScale("深度Scale", Range(0.01, 1)) = 0.6
        [PowerSlider(0.5)]_DepthPower("深度Power", Range(0.01, 1)) = 0.9
        [Header(Diffuse)]
        _DiffuseIntensity("漫反射强弱", range(0, 1)) = 0.5
        [Header(Specular)]
        [HDR]_SpecularColor("高光顔色", Color) = (1, 1, 1, 1)
        _SpecularPower("高光强度", Range(0, 1.9)) = 1
        _Gloss("光泽度", Range(0.01, 2) ) = 0.5
        [Header(Caustic)]
        _CausticFade("焦散显示距离", Range(0, 2)) = 1
        _CausticScale("焦散尺寸(越大越小)", Range(1, 40)) = 20
        _CausticPower("焦散强度", Range(0, 2)) = 0.2
        _CausticColor("焦散颜色", Color) = (1, 1, 1, 1)
        _CausticSpeed("闪烁速度", Range(0, 5)) = 1
        [Header(Foam)]
        [Toggle(_FOAM_ON)]_FoamToggle("浪花开关", Float) = 0
        [NoScaleOffset]_WaterFoamTex("浪花", 2D) = "white" {}
        [HDR]_FoamColor("浪花颜色", Color) = (1, 1, 1, 1)
        _FoamSpeed("浪花速度(相对于波浪)", Range(0, 2))= 1
        _FoamDistort("浪花扭曲程度", Range(0, 0.4))= 0.1
        _FoamScale("浪花尺寸", Range(0, 2)) = 0.4
        [Header(Fade)]
        _FadeShape("远处渐隐", 2D) = "white" {}
        _FadeIntensity("远处渐隐强度", Range(1, 5)) = 1
        [Header(Edge)]
        [HDR]_EdgeColor("边界渐变色", Color) = (0, 0, 0)
        _DistanceSmoothStart("渐变起点(粗调)", Range(0, 1)) = 1
        _DistanceStartTrim("渐变起点(微调)", Range(-1, 1)) = 0
        _DistanceSmoothEnd("渐变羽化", Range(0, 0.1)) = 0.1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector"="True" "Queue"="Transparent-10" "ForceNoShadowCasting" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 500

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            ZWrite on
            ZTest on

            HLSLPROGRAM
            #include "WaterNewInclude.hlsl"

            #pragma shader_feature_local FAKELIGHT_ON
            #pragma shader_feature_local _FOAM_ON
            #pragma shader_feature_local _VERTEX_WAVE_ON
            #pragma shader_feature_local _REFLECTION_NONE _REFLECTION_REALTIME _REFLECTION_CUBE _REFLECTION_IBL

            // #pragma multi_compile_instancing
            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(appdata input)
            {
                v2f output = (v2f)0;

                float3 positionOS = input.positionOS;
                float time = fmod(_Time.y, 10000.0);

                #ifdef _VERTEX_WAVE_ON
                WaterWave(positionOS, time);
                #endif

                float3 positionWS = TransformObjectToWorld(positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                half3 viewDirWS = GetWorldSpaceViewDir(positionWS);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

                output.uv.xy = TRANSFORM_TEX(input.texcoord, _NormalTex);
                output.uv.zw = input.texcoord;

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.screenPos.z = -TransformWorldToView(positionWS).z;

                // 风向
                output.wind.x = dot(normalInput.tangentWS, _WindDir);
                output.wind.y = dot(normalInput.bitangentWS, _WindDir);

                // 伪光
                #if FAKELIGHT_ON
                output.fakeLightDir = normalize(RotateFakeLight(half3(0, 0, -1), radians(_FakeLightRotation)));
                #endif
                half fogFactor = ComputeFogFactor(output.positionCS.z);
                output.fogFactorAndVertexSH.x = fogFactor;
                half3 vertexSH = SampleSH(normalInput.normalWS);
                output.fogFactorAndVertexSH.yzw = vertexSH;
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                float time = fmod(_Time.y, 10000.0);
                half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));

                #if FAKELIGHT_ON
                half3 lightDirWS = input.fakeLightDir;
                half3 lightColor = _FakeLightColor * _FakeLightColorStrength;
                #else
                Light mainLight = GetMainLight();
                half3 lightDirWS = mainLight.direction;
                half3 lightColor = mainLight.color;
                #endif
                // 打雷
                lightColor.rgb += _LightningColor.rgb;

                half3 normalTS = GetNormalTangentSpace(input.wind, time, input.uv.xy);

                half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,
                                                                           input.bitangentWS.xyz, input.normalWS.xyz));
                normalWS = normalize(normalWS);

                float3 halfVectorWS = SafeNormalize(float3(viewDirWS) + float3(lightDirWS));
                half nDotH = saturate(dot(normalWS, halfVectorWS));

                float depthDelta, disortDepthDelta, finalDepthDelta;
                GetWaterDepthParams(input.screenPos, normalTS, depthDelta, disortDepthDelta, finalDepthDelta);

                // 屏幕深度差 = 水底深度 - 水面深度
                // 深度系数 = pow(saturate(屏幕深度差 / 过渡深度), 过渡系数)
                // 水体基础颜色 = lerp(浅水颜色, 深水颜色, 深度系数)
                half realDepth = finalDepthDelta * viewDirWS.y * _DepthScale;
                half alphaLerp = saturate(pow(saturate(realDepth), _DepthPower * 1.5));
                half waterAlpha = lerp(_ShallowColor.a, _DeepColor.a, alphaLerp);
                half colorLerp = saturate(pow(saturate(0.65 * realDepth), _DepthPower));
                half3 baseColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, colorLerp);

                // 折射
                half3 refract = RefractColor(input.screenPos, normalTS, depthDelta);

                // 漫反射
                baseColor *= saturate(dot(normalWS, lightDirWS) * _DiffuseIntensity + (1 - _DiffuseIntensity));

                half4 col;
                col.a = 1;
                col.rgb = lerp(refract, baseColor, waterAlpha);

                // 焦散[https://www.shadertoy.com/view/MdKXDm]
                col.rgb += CausticColor(input.uv.xy, time, disortDepthDelta, viewDirWS.y,
                                        normalTS.xy * _RefractionDisort);

                #if _REFLECTION_REALTIME || _REFLECTION_CUBE || _REFLECTION_IBL
                half3 reflColor = ReflectColor(input.screenPos, normalWS, viewDirWS, saturate(finalDepthDelta * _DepthScale));
                col.rgb = lerp(col.rgb, reflColor, FresnelTerm(0.2, dot(normalWS, viewDirWS)) * waterAlpha);
                #endif

                col.rgb += pow(nDotH, _Gloss * 128) * _SpecularPower * lightColor * _SpecularColor * waterAlpha;

                // 假的海浪
                #if _FOAM_ON
                float2 foamUV = input.uv.xy + _FoamDistort * normalTS.xy;
                col.rgb += FoamColor(foamUV, input.wind, time) * saturate(1 - input.screenPos.z * 0.02) * waterAlpha;
                #endif
                // 环境光
                col.rgb += baseColor * SampleSHPixel(input.fogFactorAndVertexSH.yzw, normalWS) * waterAlpha;

                // 远处渐隐
                col.rgb = lerp(refract, col.rgb, saturate(tex2D(_FadeShape, input.uv.zw).r * _FadeIntensity));
                // 边缘渐变色
                half edgeLerp = smoothstep(_DistanceFinalStart, _DistanceFinalStart + _DistanceSmoothEnd, input.screenPos.z / _ProjectionParams.z);
                col.rgb = lerp(col.rgb, _EdgeColor, edgeLerp);
                col.rgb = MixFog(col.rgb, input.fogFactorAndVertexSH.x);
                return col;
            }
            ENDHLSL
        }

        pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #include "WaterNewInclude.hlsl"

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma multi_compile_instancing

            #pragma vertex WaterShadowVertex
            #pragma fragment WaterShadowFragment
            ENDHLSL
        }
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector"="True" "Queue"="Transparent-10" "ForceNoShadowCasting" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            ZWrite on
            ZTest on

            HLSLPROGRAM
            #include "WaterNewInclude.hlsl"
            #pragma shader_feature_local FAKELIGHT_ON
            #pragma shader_feature_local _FOAM_ON

            // #pragma multi_compile_instancing
            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(appdata input)
            {
                v2f output = (v2f)0;

                float3 positionOS = input.positionOS;

                float3 positionWS = TransformObjectToWorld(positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                half3 viewDirWS = GetWorldSpaceViewDir(positionWS);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

                output.uv.xy = TRANSFORM_TEX(input.texcoord, _NormalTex);
                output.uv.zw = input.texcoord;

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.screenPos.z = -TransformWorldToView(positionWS).z;

                // 风向
                output.wind.x = dot(normalInput.tangentWS, _WindDir);
                output.wind.y = dot(normalInput.bitangentWS, _WindDir);

                // 伪光
                #if FAKELIGHT_ON
                output.fakeLightDir = normalize(RotateFakeLight(half3(0, 0, -1), radians(_FakeLightRotation)));
                #endif
                half fogFactor = ComputeFogFactor(output.positionCS.z);
                output.fogFactorAndVertexSH.x = fogFactor;
                half3 vertexSH = SampleSH(normalInput.normalWS);
                output.fogFactorAndVertexSH.yzw = vertexSH;
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                float time = fmod(_Time.y, 10000.0);
                half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));

                #if FAKELIGHT_ON
                half3 lightDirWS = input.fakeLightDir;
                half3 lightColor = _FakeLightColor * _FakeLightColorStrength;
                #else
                Light mainLight = GetMainLight();
                half3 lightDirWS = mainLight.direction;
                half3 lightColor = mainLight.color;
                #endif
                // 打雷
                lightColor.rgb += _LightningColor.rgb;

                half3 normalTS = GetNormalTangentSpace(input.wind, time, input.uv.xy);

                half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,
                                                                           input.bitangentWS.xyz, input.normalWS.xyz));
                normalWS = normalize(normalWS);

                float3 halfVectorWS = SafeNormalize(float3(viewDirWS) + float3(lightDirWS));
                half nDotH = saturate(dot(normalWS, halfVectorWS));

                float depthDelta, disortDepthDelta, finalDepthDelta;
                GetWaterDepthParams(input.screenPos, normalTS, depthDelta, disortDepthDelta, finalDepthDelta);

                // 屏幕深度差 = 水底深度 - 水面深度
                // 深度系数 = pow(saturate(屏幕深度差 / 过渡深度), 过渡系数)
                // 水体基础颜色 = lerp(浅水颜色, 深水颜色, 深度系数)
                half realDepth = finalDepthDelta * viewDirWS.y * _DepthScale;
                half alphaLerp = saturate(pow(saturate(realDepth), _DepthPower * 1.5));
                half waterAlpha = lerp(_ShallowColor.a, _DeepColor.a, alphaLerp);
                half colorLerp = saturate(pow(saturate(0.65 * realDepth), _DepthPower));
                half3 baseColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, colorLerp);

                // 折射
                half3 refract = RefractColor(input.screenPos, normalTS, depthDelta);

                // 漫反射
                baseColor *= saturate(dot(normalWS, lightDirWS) * _DiffuseIntensity + (1 - _DiffuseIntensity));

                half4 col;
                col.a = 1;
                col.rgb = lerp(refract, baseColor, waterAlpha);

                col.rgb += pow(nDotH, _Gloss * 128) * _SpecularPower * lightColor * _SpecularColor * waterAlpha;

                // 假的海浪
                #if _FOAM_ON
                half2 foamUV = input.uv.xy + _FoamDistort * normalTS.xy;
                col.rgb += FoamColor(foamUV, input.wind, time) * saturate(1 - input.screenPos.z * 0.02) * waterAlpha;
                #endif
                // 环境光
                col.rgb += baseColor * input.fogFactorAndVertexSH.yzw * waterAlpha;

                // 远处渐隐
                col.rgb = lerp(refract, col.rgb, saturate(tex2D(_FadeShape, input.uv.zw).r * _FadeIntensity));
                // 边缘渐变色
                half edgeLerp = smoothstep(_DistanceFinalStart, _DistanceFinalStart + _DistanceSmoothEnd, input.screenPos.z / _ProjectionParams.z);
                col.rgb = lerp(col.rgb, _EdgeColor, edgeLerp);
                col.rgb = MixFog(col.rgb, input.fogFactorAndVertexSH.x);
                return col;
            }
            ENDHLSL
        }
    }

    Fallback "MC/OpaqueShadowCaster"
}