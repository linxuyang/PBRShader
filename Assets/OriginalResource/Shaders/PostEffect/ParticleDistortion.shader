Shader "MC/PostEffect/Particle Distortion" {

    Properties {
       
        _MainTex ("Alpha (A)", 2D) = "white" {}
        _NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
        // _RimPower ("侧面硬度", Range(0.1, 8)) = 1
        // _IgnoreCenter ("正面挖空", Range(0, 1)) = 0
       //   ("Heat Time", range (0,1.5)) = 1
	   // _HeatForce  ("Heat Force", range (0,1)) = 0.1
        [Toggle(_ZCULL)]_ZCullToggle("深度测试", Float) = 1
       
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
                #pragma shader_feature _ZCULL
                #include "UnityCG.cginc"

                struct a2v {
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    float4 vertex : POSITION;
                    float4 color : COLOR;
                    float4 uv : TEXCOORD0;
                    // xy:alpha zw:noise
                    float4 uv1 : TEXCOORD1;
                    // uv方向强度
                    float4 uv2 : TEXCOORD2;
                //    float3 normal : NORMAL;
                };

                struct v2f {
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    float4 color : COLOR;
                    float4 pos : SV_POSITION;
                //    float3 normal : TEXCOORD0;
                    float4 uvgrab : TEXCOORD0;
                    float4 uv : TEXCOORD1;
                    float4 uv2 : TEXCOORD2;
                    #if _ZCULL
                        float4 projPos : TEXCOORD3;
                    #endif
                  
                };

               // float  _HeatForce;
                float4 _ParticleDistortionTex_TexelSize,_MainTex_ST,_NoiseTex_ST;
                // 透明、噪声
                sampler2D _MainTex, _NoiseTex;
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
                 //   o.uvgrab = ComputeGrabScreenPos(o.pos); 
                 //    COMPUTE_EYEDEPTH(o.uvgrab.z);
                 #if UNITY_UV_STARTS_AT_TOP
	                float scale = -1.0;
	                #else
	                float scale = 1.0;
	                #endif
                    o.uvgrab.xy = (float2(o.pos.x, o.pos.y*scale) + o.pos.w) * 0.5;
	                o.uvgrab.zw = o.pos.zw;
                //    float time = fmod(_Time.y,20000); //解决time太大小数位精度不够的问题
                    o.uv.xy = TRANSFORM_TEX( v.uv, _MainTex ) + v.uv.zw;   //CustomData1
                    o.uv.zw = TRANSFORM_TEX( v.uv, _NoiseTex ) + v.uv1.xy ;
                    o.uv2.xy = v.uv1.zw;//CustomData2
                    o.uv2.zw = v.uv2.xy;
                    // float3 worldNorm = UnityObjectToWorldNormal(v.normal);
                    // float3 viewPos = UnityObjectToViewPos(v.vertex);
                    // half NdV = dot(normalize(ObjSpaceViewDir(v.vertex)), v.normal); // NdV : [-1,1]
                    // #if _HIGH_QUAL
                        // o.viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                        // o.viewDir.xyz = normalize(viewPos);
                        // o.viewDir.w = NdV;
                    // #else
                        // float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                        // float3 viewDir = normalize(viewPos);
                        // float3 viewCross = cross(viewDir, viewNorm);
                        // viewNorm = float3(-viewCross.y, viewCross.x, 0);
                        // o.normal = viewNorm;
                        // o.normal *= smoothstep(1 - _RimPower, 1, NdV);
                        // o.normal *= smoothstep(_IgnoreCenter-.1, _IgnoreCenter+.1, length(viewNorm.xy));
                    // #endif
                    return o;
                }

                float4 frag (v2f i) : SV_Target
                {
                    UNITY_SETUP_INSTANCE_ID(i);
                    // #if _HIGH_QUAL
                        // float3 viewCross = cross(i.viewDir.xyz, i.viewNorm);
                        // i.normal = float3(-viewCross.y, viewCross.x, 0.0);
                        // i.normal *= smoothstep(_IgnoreCenter-.1, _IgnoreCenter+.1, length(i.normal));
                        // i.normal *= smoothstep(1 - _RimPower, 1, i.viewDir.w);
                    // #endif
                    half2 refracted ;

                    //noise effect
	                half4 offsetColor1 = tex2D(_NoiseTex, i.uv.zw);
                   // half4 offsetColor2 = tex2D(_NoiseTex, i.uv.zw - _Time.yx*_HeatTime);
	                refracted.x = ((offsetColor1.r + offsetColor1.r) - 1)  * i.uv2.x ;
	                refracted.y = ((offsetColor1.g + offsetColor1.g) - 1)  * i.uv2.y ;
                    //i.uvgrab /= i.uvgrab.w;
                    float4 uvOffset = i.uvgrab ;
                  //  uvOffset.xy *= 200 / uvOffset.w;
                    uvOffset.xy += refracted * 200 ;
                    uvOffset.xy /= uvOffset.w ;
                   // uvOffset.xy = UNITY_PROJ_COORD(uvOffset) - UNITY_PROJ_COORD(i.uvgrab);
                    half4 alpha = tex2D( _MainTex, i.uv.xy);
                    uvOffset.xy *= alpha.a * i.color.a;
                    #if _ZCULL
                        float sceneEyeDepth = DECODE_EYEDEPTH(tex2D(_CameraDepthTexture, i.projPos.xy / i.projPos.w));
                        float zCull = sceneEyeDepth > i.projPos.z;
                        return float4(uvOffset.xy,0,0) * zCull;
                    #else
                        return float4(uvOffset.xy,0,0);
                    #endif
                }
                ENDCG
            }
        }
    }
}