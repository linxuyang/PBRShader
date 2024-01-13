Shader "MC/PostEffect/Particle Mesh Distortion" {

    Properties {
        _DistortionPower("扭曲幅度", range (-100,100)) = -20
        _RimPower ("侧面硬度", Range(0.1, 8)) = 1
        _IgnoreCenter ("正面挖空", Range(0, 1)) = 0
        [Toggle(_ZCULL)]_ZCullToggle("深度测试", Float) = 0
        [Toggle(_HIGH_QUAL)]_HighQualToggle("高质量", Float) = 0
    }

    Category {
        SubShader {
            
            Pass {
                Blend One One
                Cull Off
                ZWrite Off
                ZTest Always
                
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_instancing
                #pragma shader_feature _HIGH_QUAL
                #pragma shader_feature _ZCULL
                #include "UnityCG.cginc"

                struct a2v {
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    float4 vertex : POSITION;
                    float4 color : COLOR;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2f {
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    float4 color : COLOR;
                    float4 pos : SV_POSITION;
                    float3 normal : TEXCOORD0;
                    float4 uvgrab : TEXCOORD1;
                    #if _ZCULL
                        float4 projPos : TEXCOORD2;
                    #endif
                    #if _HIGH_QUAL
                        float4 viewDir : TEXCOORD5;
                        float3 viewNorm : TEXCOORD6;
                    #endif
                };

                float _DistortionPower, _ColorPower, _RimPower, _IgnoreCenter;
                float4 _ParticleDistortionTex_TexelSize;
                #if _ZCULL
                    sampler2D_float _CameraDepthTexture;
                #endif

                v2f vert (a2v v)
                {
                    v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, o);
                    o.color = v.color;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    #if _ZCULL
                        o.projPos = ComputeScreenPos(o.pos);
                        COMPUTE_EYEDEPTH(o.projPos.z);
                    #endif
                    o.uvgrab = ComputeGrabScreenPos(o.pos); 
                    float3 worldNorm = UnityObjectToWorldNormal(v.normal);
                    float3 viewPos = UnityObjectToViewPos(v.vertex);
                    half NdV = dot(normalize(ObjSpaceViewDir(v.vertex)), v.normal); // NdV : [-1,1]
                    #if _HIGH_QUAL
                        o.viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                        o.viewDir.xyz = normalize(viewPos);
                        o.viewDir.w = NdV;
                    #else
                        float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                        float3 viewDir = normalize(viewPos);
                        float3 viewCross = cross(viewDir, viewNorm);
                        viewNorm = float3(-viewCross.y, viewCross.x, 0);
                        o.normal = viewNorm;
                        o.normal *= smoothstep(1 - _RimPower, 1, NdV);
                        o.normal *= smoothstep(_IgnoreCenter-.1, _IgnoreCenter+.1, length(viewNorm.xy));
                    #endif
                    return o;
                }

                float2 frag (v2f i) : SV_Target
                {
                    UNITY_SETUP_INSTANCE_ID(i);

                    #if _HIGH_QUAL
                        float3 viewCross = cross(i.viewDir.xyz, i.viewNorm);
                        i.normal = float3(-viewCross.y, viewCross.x, 0.0);
                        i.normal *= smoothstep(_IgnoreCenter-.1, _IgnoreCenter+.1, length(i.normal));
                        i.normal *= smoothstep(1 - _RimPower, 1, i.viewDir.w);
                    #endif
                    half3 refracted = i.normal * abs(i.normal) * i.color.a * _DistortionPower;
                    float4 uvOffset = i.uvgrab;
                    uvOffset.xy = refracted.xy * uvOffset.w + uvOffset.xy;
                    uvOffset.xy = UNITY_PROJ_COORD(uvOffset) - UNITY_PROJ_COORD(i.uvgrab);
                    #if _ZCULL
                        float sceneEyeDepth = DECODE_EYEDEPTH(tex2D(_CameraDepthTexture, i.projPos.xy / i.projPos.w));
                        float zCull = sceneEyeDepth > i.projPos.z;
                        return float2(uvOffset.xy) * zCull;
                    #else
                        return float2(uvOffset.xy);
                    #endif
                }
                ENDCG
            }
        }
    }
}