Shader "MC/Scene/RealReflectionWater"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _GlossColor("高光颜色", Color) = (1, 1, 1, 1)
        _Gloss("高光强度", Range(0, 10)) = 10.0
        _Shininess("高光范围", Range(0.001, 0.01)) = 0.005
        _FresnelPower("菲涅尔系数", Range(1, 100)) = 3

        _NormalTexture("法线贴图", 2D) = "bump" {}
        _NormalTexture2("法线贴图2", 2D) = "bump" {}
        _NormalScale("法线强度", Range(0, 5)) = 5
        _FlowSpeed("流动速度", Vector) = (1, 1, 0, 0)
        _UVOffsetScale("倒影扭曲强度", Range(0, 0.1)) = 0.03
        _AlphaSmoothstep("透明度渐变", Range(0, 0.1)) = 0
    }

    SubShader
    {
        LOD 500
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent-10" "ForceNoShadowCasting" = "True"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../ComMonInclude.hlsl"

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _SSPR_RT;
            sampler2D _NormalTexture;
            sampler2D _NormalTexture2;

            float3 _PlayerPos;

            CBUFFER_START(UnityPerMaterial)
            half3 _Color, _GlossColor;
            half _Gloss, _Shininess, _FresnelPower, _NormalScale, _UVOffsetScale;
            half4 _NormalTexture_ST;
            half4 _NormalTexture2_ST;
            half2 _FlowSpeed;
            half _AlphaSmoothstep;
            CBUFFER_END

            struct appdata
            {
                float3 positionOS : POSITION;
                half2 texcoord : TEXCOORD0;
                half4 tangentOS : TANGENT;
                half3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 screenPos: TEXCOORD0;
                half4 uv : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                half4 normalWS : TEXCOORD3; // xyz:法线(世界); w:观察方向(世界).x
                half4 tangentWS : TEXCOORD4; // xyz:切线(世界); w:观察方向(世界).y
                half4 bitangentWS : TEXCOORD5; // xyz:副切线(世界); w:观察方向(世界).z
                half fogFactor : TEXCOORD6;
            };

            v2f vert(appdata input)
            {
                v2f output = (v2f)0;
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                half3 viewDirWS = GetWorldSpaceViewDir(output.positionWS);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);

                output.screenPos = ComputeScreenPos(output.positionCS);

                half time = _Time.y;
                output.uv.xy = TRANSFORM_TEX(input.texcoord, _NormalTexture) + _FlowSpeed * time;
                output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalTexture2) + _FlowSpeed.yx * time;
                
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                half3 tangentNormal = UnpackCustomNormal(tex2D(_NormalTexture, input.uv.xy), _NormalScale);
                half3 tangentNormal2 = UnpackCustomNormal(tex2D(_NormalTexture2, input.uv.zw), _NormalScale);
                tangentNormal = (tangentNormal + tangentNormal2);

                half3 normalWS = TransformTangentToWorld(tangentNormal, half3x3(input.tangentWS.xyz,
                    input.bitangentWS.xyz, input.normalWS.xyz));
                normalWS = normalize(normalWS);

                half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));

                Light mainLight = GetMainLight();
                // 开启伪高光的话拿外部传进来的光源方向
                half3 specularLightDir = GetSpecularLightDir(mainLight.direction, input.positionWS);
                
                half3 halfDir = SafeNormalize(float3(specularLightDir) + float3(viewDirWS));
                half nDotL = max(0, dot(halfDir, normalWS));

                // 高光颜色
                half3 specTerm = _Gloss * pow(nDotL, 1 / _Shininess) * mainLight.color * _GlossColor;

                half playerLen = length(input.positionWS.xz - _PlayerPos.xz);
                half playerDistort = smoothstep(0, 5, playerLen);

                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                half3 reflectionTerm = tex2D(_SSPR_RT, screenUV + normalWS.xz * _UVOffsetScale * playerDistort * half2(1, 0.05)).rgb;

                reflectionTerm += specTerm;

                half reflCoeff = pow(1 - saturate(dot(viewDirWS, normalWS)), 1 / _FresnelPower);

                half3 color = lerp(_Color, reflectionTerm, reflCoeff);
                
                color = MixFog(color, input.fogFactor);
                // 为了水面的边缘处不要有硬边，根据像素离摄像机的距离做透明度的渐变（越远的像素越透明）
                half distanceAlpha = smoothstep(0, _AlphaSmoothstep, input.positionCS.z);
                // 根据视线与水面的夹角做透明过渡（夹角越小越透明）
                half viewDotNormalAlpha = dot(viewDirWS, input.normalWS.xyz);
                // 距离透明度与视角透明度取max（防止摄像机在水面上方较高处往下看时，水面变透明）
                half alpha = max(distanceAlpha, viewDotNormalAlpha);
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }

    SubShader
    {
        LOD 100
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent-10" "ForceNoShadowCasting" = "True"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Blend srcAlpha OneMinusSrcAlpha
            ZWrite On

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../ComMonInclude.hlsl"
            #pragma multi_compile_instancing
            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2
            
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _SSPR_RT;

            float3 _PlayerPos;

            CBUFFER_START(UnityPerMaterial)
            half3 _Color, _GlossColor;
            half _Gloss, _Shininess, _FresnelPower, _NormalScale, _UVOffsetScale;
            half2 _FlowSpeed;
            half _AlphaSmoothstep;
            CBUFFER_END

            struct appdata
            {
                float3 positionOS : POSITION;
                half2 texcoord : TEXCOORD0;
                half4 tangentOS : TANGENT;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 screenPos: TEXCOORD0;
                half4 viewDirWSAndFogFactor : TEXCOORD2;
            };

            v2f vert(appdata input)
            {
                v2f output = (v2f)0;
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.viewDirWSAndFogFactor.xyz = GetWorldSpaceViewDir(positionWS);
                output.viewDirWSAndFogFactor.w = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                half3 normalWS = half3(0, 1, 0);
                half3 viewDirWS = SafeNormalize(input.viewDirWSAndFogFactor.xyz);

                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                half3 reflectionTerm = tex2D(_SSPR_RT, screenUV).rgb;

                half reflCoeff = pow(1 - saturate(dot(viewDirWS, normalWS)), 1 / _FresnelPower);

                half3 color = lerp(_Color, reflectionTerm, reflCoeff);
                color = MixFog(color, input.viewDirWSAndFogFactor.w);
                
                // 为了水面的边缘处不要有硬边，根据像素离摄像机的距离做透明度的渐变（越远的像素越透明）
                half distanceAlpha = smoothstep(0, _AlphaSmoothstep, input.positionCS.z);
                // 根据视线与水面的夹角做透明过渡（夹角越小越透明）
                half viewDotNormalAlpha = dot(viewDirWS, normalWS);
                // 距离透明度与视角透明度取max（防止摄像机在水面上方较高处往下看时，水面变透明）
                half alpha = max(distanceAlpha, viewDotNormalAlpha);
                // 远处渐隐
                return float4(color, alpha);
            }
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}