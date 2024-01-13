Shader "MC/Scene/GerstnerWaveWater"
{
    Properties
    {
        _Color("水体颜色", Color) = (0.615, 0.864, 0.981, 0.658)

        _DiffuseIntensity ("漫反射强弱", Range(0,1)) = 0.5
        _GlossColor("高光颜色", Color) = (1, 1, 1, 1)
        _Gloss("高光强度", Range(0, 10)) = 10.0
        _Shininess("高光范围", Range(0.001, 0.01)) = 0.005
        _FresnelPower("菲涅尔指数", Range(0.1, 5)) = 0.7

        [Header(FakeLight Motion)]
        [Toggle(FAKELIGHT_ON)]_FakeLight ("伪光", Float) = 0
        _FakeLightRotation("伪光方向", Vector) = (30, 0, 0)
        _FakeLightColor("伪光颜色", Color) = (1, 1, 1, 1)
        _FakeLightColorStrength("伪光强度", Range(0.1, 4)) = 1

        [Header(Normal Tex)]
        _NormalTexture("法线贴图1", 2D) = "bump" {}
        _NormalTexture2("法线贴图2", 2D) = "bump" {}
        _NormalScale("法线强度", Range(0, 5)) = 1
        _FlowSpeed("流动速度", Vector) = (0.3, -0.3, 0, 0)

        [Header(Reflection)]
        _ReflectionRate("反射率", Range(0, 1)) = 0.3
        _UVOffsetScale("倒影扭曲强度", Range(0, 1)) = 0.1
        _ReflectionOffsetByVertex("顶点动画倒影校正", Range(-1, 0)) = -0.9

        [Header(Refraction)]
        _RefractionScale("折射扭曲强度", Range(0, 0.03)) = 0.005
        _DepthScale("不透光系数(水越深越不透明)", Range(0.01,5)) = 1.11
        _DepthPower("不透光指数", Range(0.01,1)) = 0.59

        [Header(Caustic)]
        _CausticScale("焦散尺寸", Range(0.02, 1)) = 0.2
        _CausticPower("焦散强度", Range(0, 5)) = 3
        _CausticColor("焦散颜色", Color) = (1, 1, 1, 1)
        _CausticSpeed("闪烁速度", Range(0, 5)) = 1
        _CausticOffsetScale("焦散扭曲强度", Range(0, 1)) = 0.05

        [Header(Foam)]
        [HDR]_FoamColor("RGB-水沫颜色, A-水沫强度", Color) = (1, 1, 1, 1)
        _WaveParams ("波浪参数:发生源(XY), 频率(Z), 速度(W)", Vector) = (1, 0, 1, 1)
        [NoScaleOffset]_DepthTex ("深度图", 2D) = "white" {}
        _WaveChange ("变频", Float) = 0.05
        _NearSmoothMin ("近岸过渡Min", Range(0, 1)) = 0.9
        _NearSmoothMax ("近岸过渡Max", Range(0, 1)) = 1
        _FarSmoothMin ("远岸过渡Min", Range(0, 1)) = 0
        _FarSmoothMax ("远岸过渡Max", Range(0, 1)) = 0.1
        [Header(Shape Noise)]
        _ShapeNoise ("潮水形状噪声", 2D) = "white" {}
        _ShapeNoiseStrength ("噪声强度", Range(0, 1)) = 1
        [Header(Mask Noise)]
        _Mask ("潮水遮罩", 2D) = "white" {}
        _MaskStrength ("潮水遮罩强度", Range(0, 1)) = 1
        _FoamTex ("水沫贴图", 2D) = "white" {}

        [Header(Vertex Wave Total)]
        [Toggle(WAVE_ON)]_WaveOn ("水波顶点动画", Float) = 0
        _Steepness("波形", Range(0, 1)) = 0.8
        _Amplitude("振幅", Range(0.001, 0.5)) = 0.1
        _WaveLength("波长", Range(0.1, 5)) = 0.5
        _WindDir("移动方向", Range(0, 180)) = 0
        _WindSpeed("移动速度", Range(-1, 1)) = 0.1
        [HideInInspector][Header(Wave 1)]
        [HideInInspector]_Amplitude1("振幅1", Range(0.01, 2)) = 1.8
        [HideInInspector]_WaveLen1("波长1", Range(0.1, 1)) = 0.541
        [HideInInspector]_WindSpeed1("移动速度1", Range(-1, 1)) = 0.305
        [HideInInspector]_WindDir1("移动方向1", Range(0, 360)) = 11        
        [HideInInspector][Header(Wave 2)]
        [HideInInspector]_Amplitude2("振幅2", Range(0.01, 2)) = 0.8
        [HideInInspector]_WaveLen2("波长2", Range(0.1, 1)) = 0.7
        [HideInInspector]_WindSpeed2("移动速度2", Range(-1, 1)) = 0.5
        [HideInInspector]_WindDir2("移动方向2", Range(0, 360)) = 99
        [HideInInspector][Header(Wave 3)]
        [HideInInspector]_Amplitude3("振幅3", Range(0.01, 2)) = 0.5
        [HideInInspector]_WaveLen3("波长3", Range(0.1, 1)) = 0.2
        [HideInInspector]_WindSpeed3("移动速度3", Range(-1, 1)) = 0.34
        [HideInInspector]_WindDir3("移动方向3", Range(0, 360)) = 167
        [HideInInspector][Header(Wave 4)]
        [HideInInspector]_Amplitude4("振幅4", Range(0.01, 2)) = 0.3
        [HideInInspector]_WaveLen4("波长4", Range(0.1, 1)) = 0.3
        [HideInInspector]_WindSpeed4("移动速度4", Range(-1, 1)) = 0.12
        [HideInInspector]_WindDir4("移动方向4", Range(0, 360)) = 300
        [HideInInspector][Header(Wave 5)]
        [HideInInspector]_Amplitude5("振幅5", Range(0.01, 2)) = 0.1
        [HideInInspector]_WaveLen5("波长5", Range(0.1, 1)) = 0.5
        [HideInInspector]_WindSpeed5("移动速度5", Range(-1, 1)) = 0.74
        [HideInInspector]_WindDir5("移动方向5", Range(0, 360)) = 10
        [HideInInspector][Header(Wave 6)]
        [HideInInspector]_Amplitude6("振幅6", Range(0.01, 2)) = 0.08
        [HideInInspector]_WaveLen6("波长6", Range(0.1, 1)) = 0.3
        [HideInInspector]_WindSpeed6("移动速度6", Range(-1, 1)) = 0.11
        [HideInInspector]_WindDir6("移动方向6", Range(0, 360)) = 180
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent-10" "ForceNoShadowCasting" = "True"
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "../../CommonInclude.hlsl"
            
            #define WAVE_NUM 6

            sampler2D _NormalTexture;
            sampler2D _NormalTexture2;
            sampler2D _DepthTex;
            sampler2D _ShapeNoise;
            sampler2D _Mask;
            sampler2D _FoamTex;
            sampler2D _SSPR_RT;

            CBUFFER_START(UnityPerMaterial)
            // 水面渲染相关参数
            half4 _Color;
            half3 _GlossColor;
            half _DepthScale, _DepthPower, _DiffuseIntensity, _Gloss, _Shininess, _FresnelPower;
            // 伪光源
            half3 _FakeLightRotation;
            half3 _FakeLightColor;
            half _FakeLightColorStrength;

            // 水面法线贴图相关参数
            half4 _NormalTexture_ST;
            half4 _NormalTexture2_ST;
            half _NormalScale;
            half2 _FlowSpeed;

            // 反射相关参数
            half _ReflectionRate;
            half _UVOffsetScale;
            half _ReflectionOffsetByVertex;

            // 折射相关参数
            half _RefractionScale;

            // 水体焦散相关参数
            half _CausticFade;
            half _CausticScale;
            half _CausticPower;
            half _CausticOffsetScale;
            half _CausticSpeed;
            half3 _CausticColor;

            // 水沫相关参数
            half4 _FoamColor;
            half4 _ShapeNoise_ST;
            half _ShapeNoiseStrength;
            half4 _Mask_ST;
            half _MaskStrength;
            half4 _WaveParams;
            half _WaveChange;
            half _NearSmoothMin, _NearSmoothMax;
            half _FarSmoothMin, _FarSmoothMax;
            half4 _FoamTex_ST;

            // 水波相关参数
            half _WaveLength, _Amplitude, _Steepness;
            half _WindDir, _WindSpeed;
            half _Amplitude1, _WaveLen1, _WindSpeed1, _WindDir1;
            half _Amplitude2, _WaveLen2, _WindSpeed2, _WindDir2;
            half _Amplitude3, _WaveLen3, _WindSpeed3, _WindDir3;
            half _Amplitude4, _WaveLen4, _WindSpeed4, _WindDir4;
            half _Amplitude5, _WaveLen5, _WindSpeed5, _WindDir5;
            half _Amplitude6, _WaveLen6, _WindSpeed6, _WindDir6;
            CBUFFER_END

            #pragma shader_feature_local FAKELIGHT_ON
            #pragma shader_feature_local WAVE_ON

            #pragma multi_compile_instancing
            // #pragma multi_compile_fog

            #pragma skip_variants FOG_EXP FOG_EXP2

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float3 positionOS : POSITION;
                half2 texcoord : TEXCOORD0;
                half4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                half4 uv : TEXCOORD0;
                half4 normalWS : TEXCOORD1; // xyz:法线(世界); w:观察方向(世界).x
                half4 tangentWS : TEXCOORD2; // xyz:切线(世界); w:观察方向(世界).y
                half4 bitangentWS : TEXCOORD3; // xyz:副切线(世界); w:观察方向(世界).z
                float4 screenPos : TEXCOORD4;
                #if FAKELIGHT_ON
                float3 fakeLightDir : TEXCOORD5;
                #endif
            };

            struct Wave
            {
                float3 wavePos;
                float3 waveNormal;
            };

            // 根据水波参数计算顶点偏移以及法线偏移(原理及计算公式参考Gerstner波函数)
            Wave GerstnerWave(float2 posXZ, float amp, float waveLen, float speed, int dir)
            {
                Wave o;
                float w = TWO_PI / (waveLen * _WaveLength);
                float A = amp * _Amplitude;
                float WA = w * A;
                float Q = _Steepness / (WA * WAVE_NUM);
                float dirRad = radians((dir + _WindDir) % 360);
                float2 D = normalize(float2(sin(dirRad), cos(dirRad)));
                float common = w * dot(D, posXZ) + _Time.y * sqrt(9.8 * w) * speed * _WindSpeed;
                float sinC = sin(common);
                float cosC = cos(common);
                o.wavePos.xz = Q * A * D.xy * cosC;
                o.wavePos.y = A * sinC / WAVE_NUM;
                o.waveNormal.xz = -D.xy * WA * cosC;
                o.waveNormal.y = -Q * WA * sinC;
                return o;
            }

            inline half4 RefractColor(float4 screenPos, half2 refractOffset, float oriDepthDiff)
            {
                // 折射偏移量
                refractOffset = refractOffset * _RefractionScale;

                // 水面距离摄像机的距离
                float depthOfWater = screenPos.z;

                // 屏幕UV叠加上折射偏移量
                float2 depthUV = screenPos.xy + refractOffset;
                // 采样折射偏移后的深度
                float depthOfBottom = LinearEyeDepth(SampleSceneDepth(depthUV / screenPos.w), _ZBufferParams);
                // 折射后的水底与水面之间的深度差
                float depthDiff = depthOfBottom - depthOfWater;
                // 标记最终输出的是偏移后的采样结果(1)还是未偏移的采样结果(0)
                // 这么做是为了防止偏移后采样拿到了水面以上的物体的图元
                // 因此在偏移后的水底水面深度差depthDiff小于0(即采样得到了水面以上的物体)时, 输出未偏移的采样结果
                half isRefrac = step(0, depthDiff);
                depthDiff = max(0, depthDiff);

                // 根据isRefrac决定最终输出的深度差
                float finalDepthDiff = lerp(oriDepthDiff, depthDiff, isRefrac);
                // 根据水体深度值计算出一个0~1的值
                half waterDepth = pow(saturate(finalDepthDiff * _DepthScale), _DepthPower);

                // 采样抓屏颜色(isRefrac = 0时不做折射偏移, isRefrac = 1时添加折射偏移)
                half2 screenUV = screenPos.xy + refractOffset * isRefrac;
                half4 refract = half4(SampleSceneColor(screenUV / screenPos.w), waterDepth);

                return refract;
            }

            half3 RotateFakeLight(half3 lightDir, float3 rotation)
            {
                half sx, sy, sz, cx, cy, cz;
                sincos(rotation.x, sx, cx);
                sincos(rotation.y, sy, cy);
                sincos(rotation.z, sz, cz);
                float3x3 M = float3x3(cy * cz + sz * sy * sz, -cy * sz + sx * sy * cz, cx * sy,
                                      cx * sz, cx * cz, -sx,
                                      -sy * cz + sx * cy * sz, sy * sz + sx * cy * cz, cx * cy
                );
                return mul(M, lightDir);
            }

            // 基于连续空间旋转min叠加，实现焦散[https://blog.csdn.net/tjw02241035621611/article/details/80135626]
            float CausticRotateMin(float2 uv, float time)
            {
                float3x3 mat = float3x3(2, 1, -2, 3, -2, 1, 1, 2, 2); //1.2.操作矩阵
                float3 vec1 = mul(mat * 0.5, float3(uv, time)); //3.对颜色空间进行操作
                float3 vec2 = mul(mat * 0.4, vec1); //4.重复2，3操作
                float3 vec3 = mul(mat * 0.3, vec2);
                float val = min(length(frac(vec1) - 0.5), length(frac(vec2) - 0.5)); //5.集合操作 min
                val = min(val, length(frac(vec3) - 0.5));
                val = pow(val, 7.0) * 25.; //6.亮度调整
                return val;
            }

            // 焦散
            inline half3 CausticColor(float2 uv, float time, half depth, half viewDirY, half2 disortOffset)
            {
                half power = smoothstep(0, 1, viewDirY);
                power *= saturate(depth) * _CausticPower;
                return CausticRotateMin(uv / _CausticScale + disortOffset * _CausticOffsetScale, time * _CausticSpeed) * _CausticColor * power;
            }

            // 垂直于海岸线移动的水沫
            half Foam(half2 uv, float time)
            {
                // 采样海底高度图
                float3 depthTex = tex2D(_DepthTex, uv).rgb;
                // R通道储存海底高度, 即值越大水越浅
                float depth = depthTex.r;
                // GB通道储存海底表面法线的倾斜方向的垂直向量(即海底地势图的切线方向)
                float2 uvDir = 2 * depthTex.gb - 1;
                float2 noiseUV = uv * _ShapeNoise_ST.xy + _ShapeNoise_ST.zw;
                // 采样近岸海浪形状噪声(用于形成随机扭曲的潮水线)
                half noise = tex2D(_ShapeNoise, noiseUV).r;
                // 采样水沫遮罩(用于使不同区域的水沫产生强度差别)
                half mask = tex2D(_Mask, uv * _Mask_ST.xy + _Mask_ST.zw).r;
                // 计算水波中心点到该点的方向waveDir
                half2 waveDir = half2(uv - _WaveParams.xy);
                half2 normalizedWaveDir = normalize(waveDir);
                // 计算得到waveDir方向的垂直向量
                half2 waveDirTangent = cross(half3(normalizedWaveDir.x, 0, normalizedWaveDir.y), half3(0, 1, 0)).xz;
                // 计算出该点到水波中心点的距离
                float constDis = distance(uv, _WaveParams.xy);
                constDis *= _WaveParams.z; // 水波频率
                constDis += _WaveChange * depth; // 根据海底高度增加距离(形成与海岸线贴合的水波纹)
                float changeDis = constDis + PI - time * _WaveParams.w; // 水波扩散速度
                changeDis += _ShapeNoiseStrength * (noise - 0.5); // 潮水形状噪声

                float waveY = 0.5f * cos(changeDis) + 0.5f; // 简易版 单纯使用三角函数模拟周期性的水波
                // 取海底地势切线和水波切线的平均方向
                uvDir = normalize(uvDir + waveDirTangent);
                // 以水波前进的方向作为采样水沫贴图的UV的X分量
                half foamU = frac((changeDis - PI) / TWO_PI);
                // 以原始uv在uvDir方向的投影作为采样水沫贴图的UV的Y分量
                half foamV = dot(uvDir, uv);
                // 采样水沫贴图
                float2 foamUV = float2(foamU, foamV) * _FoamTex_ST.xy + _FoamTex_ST.zw;
                float foamTexCol = tex2D(_FoamTex, foamUV).r;

                // 应用水沫遮罩
                float wave = waveY * lerp(1, mask, _MaskStrength);
                // 屏蔽掉水非常浅的区域和深海区域的水沫, 只保留中间区域的水沫
                wave *= saturate(
                    smoothstep(_FarSmoothMin, _FarSmoothMax, depth) - smoothstep(
                        _NearSmoothMin, _NearSmoothMax, depth));
                // 应用水沫贴图
                wave *= foamTexCol;
                return wave;
            }

            v2f vert(appdata input)
            {
                float3 waveOffset = float3(0.0, 0.0, 0.0);
                half3 waveNormal = float3(0.0, 0.0, 0.0);
                #if WAVE_ON
                // 计算多层水波并将计算结果叠加
                Wave wave = GerstnerWave(input.positionOS.xz, _Amplitude1, _WaveLen1, _WindSpeed1, _WindDir1);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;
                wave = GerstnerWave(input.positionOS.xz, _Amplitude2, _WaveLen2, _WindSpeed2, _WindDir2);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;
                wave = GerstnerWave(input.positionOS.xz, _Amplitude3, _WaveLen3, _WindSpeed3, _WindDir3);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;
                wave = GerstnerWave(input.positionOS.xz, _Amplitude4, _WaveLen4, _WindSpeed4, _WindDir4);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;
                wave = GerstnerWave(input.positionOS.xz, _Amplitude5, _WaveLen5, _WindSpeed5, _WindDir5);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;
                wave = GerstnerWave(input.positionOS.xz, _Amplitude6, _WaveLen6, _WindSpeed6, _WindDir6);
                waveOffset += wave.wavePos;
                waveNormal += wave.waveNormal;

                input.positionOS.xyz += waveOffset;
                #endif
                waveNormal.y = 1 - waveNormal.y;

                v2f output = (v2f)0;

                float3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(waveNormal, input.tangentOS);
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);

                output.uv.xy = input.texcoord;

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.screenPos.z = -TransformWorldToView(positionWS).z;

                // 伪光源方向
                #if FAKELIGHT_ON
                output.fakeLightDir = normalize(RotateFakeLight(half3(0, 0, -1), radians(_FakeLightRotation)));
                #endif

                output.uv.z = ComputeFogFactor(output.positionCS.z);
                output.uv.w = waveOffset.y;
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                // 定义一个竖直朝上的世界空间法线
                half3 upWorldNormal = half3(0, 1, 0);

                // 从法线贴图中采样切线空间法线, 然后转换到世界空间
                float time = _Time.y;
                half2 normalUV1 = input.uv.xy * _NormalTexture_ST.xy + _NormalTexture_ST.zw + _FlowSpeed * time;
                half3 tangentNormal = UnpackCustomNormal(tex2D(_NormalTexture, normalUV1), _NormalScale);
                half2 normalUV2 = input.uv.xy * _NormalTexture2_ST.xy + _NormalTexture2_ST.zw + _FlowSpeed.yx * time;
                half3 tangentNormal2 = UnpackCustomNormal(tex2D(_NormalTexture2, normalUV2), _NormalScale);
                tangentNormal = (tangentNormal + tangentNormal2);
                half3 worldNormalInTexture = TransformTangentToWorld(tangentNormal, half3x3(input.tangentWS.xyz,
                    input.bitangentWS.xyz, upWorldNormal));
                worldNormalInTexture = normalize(worldNormalInTexture);

                // 水面距离摄像机的距离
                float depthOfWater = input.screenPos.z;
                // 水底距离摄像机的距离
                float depthOfBottom = LinearEyeDepth(SampleSceneDepth(input.screenPos.xy / input.screenPos.w), _ZBufferParams);
                // 未折射的水底与水面之间的深度差
                float oriDepthDiff = max(0, depthOfBottom - depthOfWater);

                // 根据水体深度计算水沫系数
                half foam = Foam(input.uv.xy, time);
                foam *= _FoamColor.a;

                // 经过顶点动画的法线叠加上法线贴图中的法线偏移量(worldNormalInTexture - upWorldNormal)
                // 水沫系数越大, 法线贴图对水面法线的影响越小
                float3 normalWS = normalize(input.normalWS.xyz + (worldNormalInTexture - upWorldNormal) * (1 - foam));

                half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
                
                // 伪光源
            #if FAKELIGHT_ON
                half3 lightDirWS = input.fakeLightDir;
                half3 lightColor = _FakeLightColor * _FakeLightColorStrength;
            #else
                Light mainLight = GetMainLight();
                half3 lightDirWS = mainLight.direction;
                half3 lightColor = mainLight.color;
            #endif
                
                float3 halfDir = SafeNormalize(float3(lightDirWS) + float3(viewDirWS));
                float normalDotHalf = max(0, dot(halfDir, normalWS));

                float2 screenUV = input.screenPos.xy / input.screenPos.w;

                // 折射
                // 把水面的法线偏移(相对竖直向上的法线)从世界坐标转换到裁剪坐标, 否则会出现折射方向随着摄像机角度的变化而变化
                half3 clipSpaceNormal = mul((float3x3)UNITY_MATRIX_VP, normalWS - upWorldNormal);
                clipSpaceNormal.y *= _ProjectionParams.x;
                half4 refract = RefractColor(input.screenPos, clipSpaceNormal.xy, oriDepthDiff);

                // 根据水深计算得到的水体透明度
                half waterAlpha = lerp(_Color.a, 1, refract.a);

                // 反射
                // 根据前面顶点动画的Y偏移量对反射采样UV进行一定的偏移(反射面上升, 镜像物体也要跟着上移, 即UV的Y值减小)
                float2 reflectionUv = screenUV + half2(0, _ReflectionOffsetByVertex * input.uv.w);
                // 根据法线对反射采样UV进行一定的偏移
                reflectionUv += normalWS.xz * _UVOffsetScale * float2(0.05, 0.05);
                half3 reflection = tex2D(_SSPR_RT, reflectionUv).rgb;

                // 空气到水的反射系数
                half R = 0.02;
                // 水体菲涅尔系数
                half fresnel = R + (1 - R) * pow(abs(0.5 - 0.5 * dot(viewDirWS, normalWS)), _FresnelPower);

                // 水体颜色
                half3 baseColor = _Color.rgb * lightColor;
                // 漫反射
                baseColor *= saturate(dot(normalWS, lightDirWS) * _DiffuseIntensity + (1 - _DiffuseIntensity));
                // 根据水沫系数在漫反射结果与水沫颜色做插值
                baseColor = lerp(baseColor, _FoamColor.rgb, foam);
                // 根据水沫系数在水体透明度与1(因为水沫是不透明的)之间做插值, 再用插值结果在折射颜色与漫反射颜色之间插值
                half3 color = lerp(refract.rgb, baseColor, lerp(waterAlpha, 1, foam));

                // 以下焦散、反射、高光都需要根据水沫系数做衰减
                // 焦散
                half3 caustic = CausticColor(0.5 * (normalUV1 + normalUV2), _Time.y, refract.a, viewDirWS.y,
                                            normalWS.xz);
                half3 causticColor = (1 - _Color.a) * caustic * lightColor;
                color += causticColor * (1 - foam);
                // 反射
                color += reflection * fresnel * _ReflectionRate * (1 - foam) * waterAlpha;
                // 高光
                color += pow(normalDotHalf, 1 / _Shininess) * _Gloss * lightColor.rgb * _GlossColor * waterAlpha * (1 -
                    foam);
                // 环境光
                color += baseColor.rgb * SampleSH(normalWS) * waterAlpha;
                color = MixFog(color, input.uv.z);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}