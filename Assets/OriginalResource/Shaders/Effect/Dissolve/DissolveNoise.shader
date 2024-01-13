Shader "MC/Effect/DissolveNoise"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色 (RGB)", Color) = (1,1,1,1)
        _MainTex("固有色 (RGB)", 2D) = "white"{}
        [Toggle(_VCOLOR_ALPHA_ON)] _VColorAlphaToggle ("用粒子A通道控制透明度", Float) = 0
        [KeywordEnum(None, Burn, Mask)] _Debug ("Debug", Float) = 0
        [Header(Dissolve)]
        _Cutoff("溶解", Range(0,1)) = 0
        [Toggle(_VCOLOR_A_REV_BURN_ON)] _VColorAlphaRevToggle ("反转粒子A通道控制溶解", Float) = 0
        _LineWidth("溶解边缘宽度", Range(0,.2)) = .1
        [HDR]_BurnColor ("溶解颜色 (RGB)", Color) = (0,0,0,0)
        [HDR]_BurnEdgeColor ("溶解边缘颜色 (RGB)", Color) = (0,0,0,0)
        [KeywordEnum(UV, XZ, XY, YZ)] _BurnUVMode ("使用UV或世界坐标系", Float) = 0
        _BurnMap("溶解纹理 (R)", 2D) = "white"{}
        _BurnSpeedX ("溶解U速度", Float) = 0
        _BurnSpeedY ("溶解V速度", Float) = 0
        _BurnAngle ("溶解UV角度", Range(0, 360)) = 0
        [Space]
        [Toggle(_BURN_MAP_NOISE_ON)] _BurnNoiseToggle ("用噪波图扰动溶解纹理", Float) = 0
        [KeywordEnum(UV, Add, Sub, Mul)] _BurnNoiseMode ("噪波的影响", Float) = 0
        _NoiseMap ("噪波图 (R/RG)", 2D) = "white"{}
        _NoisePower ("噪波强度", Float) = 0
        _NoiseSpeedX ("噪波U速度", Float) = .1
        _NoiseSpeedY ("噪波V速度", Float) = .1
        _NoiseAngle ("噪波UV角度", Range(0, 360)) = 0
        [Toggle(_BURN_MAP_NOISE_DUAL_LAYERS)] _BurnNoiseDualLayersToggle ("双层反向噪波", Float) = 0
        [Space]
        [Header(Flow)]
        [Toggle(_MAINTEX_FLOW_ON)] _MainTexFlowToggle ("UV流动", Float) = 0
        _FlowSpeedX ("U速度", Float) = .1
        _FlowSpeedY ("V速度", Float) = .1
        [Space]
        [Header(Wave)]
        [Toggle(_WAVE_ON)] _WaveToggle ("顶点扰动", Float) = 0
        _WaveNoiseMap("顶点扰动噪波图 (R)", 2D) = "white"{}
        _WaveVertOffset ("顶点扰动偏移Offset", Float) = 0
        _WaveVertUVSpeedX ("顶点扰动UV速度X", Float) = .1
        _WaveVertUVSpeedY ("顶点扰动UV速度Y", Float) = .1

//        [Space]
        // [Header(Debug)]
        // [KeywordEnum(None, Burn, Mask)] _Debug ("Debug", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest" "RenderType"="TransparentCutout" "PreviewType"="Plane" }
        Lighting Off 
        ZWrite On
        Cull Off
        
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature_local _VCOLOR_ALPHA_ON
            #pragma shader_feature_local _BURN_MAP_NOISE_ON
            #pragma shader_feature_local _VCOLOR_A_REV_BURN_ON
            #pragma shader_feature_local _BURNUVMODE_UV _BURNUVMODE_YZ _BURNUVMODE_XY _BURNUVMODE_XZ 
            #pragma shader_feature_local _BURNNOISEMODE_UV _BURNNOISEMODE_ADD _BURNNOISEMODE_SUB _BURNNOISEMODE_MUL
            #pragma shader_feature_local _BURN_MAP_NOISE_DUAL_LAYERS
            #pragma shader_feature_local _MAINTEX_FLOW_ON 
            #pragma shader_feature_local _WAVE_ON 

            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            half4 _Color;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;

            half _Cutoff;
            half _LineWidth;
            half4 _BurnColor, _BurnEdgeColor;
            TEXTURE2D(_BurnMap);
            SAMPLER(sampler_BurnMap);
            half4 _BurnMap_ST;
            half _BurnSpeedX, _BurnSpeedY, _BurnAngle;
            #if _BURN_MAP_NOISE_ON
                TEXTURE2D(_NoiseMap);
                SAMPLER(sampler_NoiseMap);
                half4 _NoiseMap_ST;
                half _NoisePower, _NoiseSpeedX, _NoiseSpeedY, _NoiseAngle;
            #endif
            #if _MAINTEX_FLOW_ON
                half _FlowSpeedX, _FlowSpeedY;
            #endif
            #if _WAVE_ON
                TEXTURE2D(_WaveNoiseMap);
                SAMPLER(sampler_WaveNoiseMap);
                half4 _WaveNoiseMap_ST;
                half _WaveVertOffset;
                half _WaveVertUVSpeedX;
                half _WaveVertUVSpeedY;
            #endif


            struct appdata_t 
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                half4 color : TEXCOORD1;
                #if _BURN_MAP_NOISE_ON
                    #if _BURN_MAP_NOISE_DUAL_LAYERS
                        float4 noiseUV : TEXCOORD2;
                    #else
                        float2 noiseUV : TEXCOORD2;
                    #endif
                #endif
                half fogFactor : TEXCOORD3;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                ZERO_INITIALIZE(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.color = v.color;
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                #if _BURNUVMODE_UV
                    float2 uv = v.uv;
                #elif _BURNUVMODE_XY
                    float2 uv = positionWS.xy;
                #elif _BURNUVMODE_XZ
                    float2 uv = positionWS.xz;
                #elif _BURNUVMODE_YZ
                    float2 uv = positionWS.yz;
                #endif
                o.uv.zw = TRANSFORM_TEX(uv, _BurnMap);
                o.uv.zw = Rotate2D(o.uv.zw, radians(_BurnAngle));
                o.uv.z += _BurnSpeedX * _Time.y / 2;
                o.uv.w += _BurnSpeedY * _Time.y / 2;
                #if _BURN_MAP_NOISE_ON
                    o.noiseUV.xy = TRANSFORM_TEX(uv, _NoiseMap);
                    o.noiseUV.xy = Rotate2D(o.noiseUV.xy, radians(_NoiseAngle));
                    #if _BURN_MAP_NOISE_DUAL_LAYERS
                        // 双层noise要略微大小不一, 速度不一, 这样随机效果较好
                        o.noiseUV.zw = uv * _NoiseMap_ST.xy * .8 + _NoiseMap_ST.zw;
                        o.noiseUV.z -= _NoiseSpeedX * _Time.y / 1.8;
                        o.noiseUV.w -= _NoiseSpeedY * _Time.y / 1.8;
                    #endif
                    o.noiseUV.x += _NoiseSpeedX * _Time.y / 2;
                    o.noiseUV.y += _NoiseSpeedY * _Time.y / 2;
                #endif

                #if _WAVE_ON
                    _WaveNoiseMap_ST.z += _WaveVertUVSpeedX * _Time.y / 2;
                    _WaveNoiseMap_ST.w += _WaveVertUVSpeedY * _Time.y / 2;
                    float4 waveNoiseuv = float4(v.uv * _WaveNoiseMap_ST.xy + _WaveNoiseMap_ST.zw , 0,0) ;
                    half waveNoise = SAMPLE_TEXTURE2D_LOD(_WaveNoiseMap,sampler_WaveNoiseMap,waveNoiseuv.xy,waveNoiseuv.w);

                    float dist = distance(v.vertex, float4(0, 0, 0, 0));//得到顶点距离中心点的距离
                    float h = waveNoise * sin(dist * 2 ) / 5 * _WaveVertOffset;//得到顶点高度：随距离和时间变化
                    o.pos = v.vertex + v.normal * h;//沿法线偏移
                    o.pos = TransformObjectToHClip(o.pos.xyz);
                #else
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                #endif
                o.fogFactor = ComputeFogFactor(o.pos.z);
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half2 uvTmp = i.uv.xy;
                #if _MAINTEX_FLOW_ON
                    uvTmp.x += _Time.y * _FlowSpeedX;  
                    uvTmp.y += _Time.y * _FlowSpeedY;  
                #endif

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvTmp) * i.color * _Color;
                col *= 2;
                // #if !_DEBUG_BURN && !_DEBUG_MASK
                //     if (_Cutoff == 0) 
                //         return half4(col, 1);
                // #endif
                #if _BURN_MAP_NOISE_ON && _BURNNOISEMODE_UV
                    half2 noiseUVshift = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,i.noiseUV.xy).rg * _NoisePower;
                    i.uv.zw += noiseUVshift.xy;
                    #if _BURN_MAP_NOISE_DUAL_LAYERS
                        noiseUVshift = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,i.noiseUV.zw).rg * _NoisePower;
                        i.uv.zw += noiseUVshift.xy;
                    #endif
                #endif
                half burn = SAMPLE_TEXTURE2D(_BurnMap,sampler_BurnMap,i.uv.zw).r;
                #if _BURN_MAP_NOISE_ON
                    half noiseshift = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,i.noiseUV.xy).r * _NoisePower;
                    #if _BURNNOISEMODE_ADD
                        burn += noiseshift;
                    #elif _BURNNOISEMODE_SUB
                        burn -= noiseshift;
                    #elif _BURNNOISEMODE_MUL
                        burn *= noiseshift;
                    #endif
                    #if _BURN_MAP_NOISE_DUAL_LAYERS
                        noiseshift = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,i.noiseUV.zw).r * _NoisePower;
                        #if _BURNNOISEMODE_ADD
                            burn += noiseshift;
                        #elif _BURNNOISEMODE_SUB
                            burn -= noiseshift;
                        #elif _BURNNOISEMODE_MUL
                            burn *= noiseshift;
                        #endif
                    #endif
                    burn = saturate(burn);
                #endif
                _Cutoff *= 1.0001;
                #if _VCOLOR_A_REV_BURN_ON
                    half curFade = _Cutoff * (1 - i.color.a);
                #else
                    half curFade = _Cutoff * i.color.a;
                #endif
                half cut = burn - curFade;
                half edge = 1 - InvLerp(0, _LineWidth, cut);
                #if _DEBUG_MASK
                    half3 colorCut = half3(1, 0, 0);
                    half3 colorEdge = half3(0, 0, 1);
                    half3 colorBase = half3(0, 1, 0);
                    return cut >= 0 ? 
                        half4(burn * .5 + .5 * lerp(colorBase, colorEdge, edge), 1) : 
                        half4(burn * .5 + .5 * colorCut, 1);
                #endif
                clip(cut);
                float4 burnColor = lerp(_BurnColor, _BurnEdgeColor, edge);
                burnColor = pow(burnColor, 5);
                float3 finalColor = lerp(col, burnColor, edge * Remap(0, .1, 0, 1, curFade)).rgb;
                finalColor.rgb = MixFog(finalColor.rgb,i.fogFactor);
                // #if _DEBUG_NONE
                    return half4(finalColor, 1);
                // #elif _DEBUG_BURN
                //     burnColor = lerp(0, burnColor, edge * Remap(0, .1, 0, 1, curFade));
                //     return half4(burnColor, 1);
                // #endif
            }

            ENDHLSL
        }
    }
    Fallback  "Unlit/Transparent Cutout"
}
