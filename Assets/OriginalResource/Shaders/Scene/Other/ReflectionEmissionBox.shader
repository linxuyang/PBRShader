    Shader "MC/Scene/ReflectionEmissionBox"
{
    Properties
    {
        [Header(Basics)]
        [HDR]_Color ("叠加色", Color) = (1,1,1,1)
        _MainTex ("固有色贴图 (RGBA)", 2D) = "white" {}
        _Cutoff ("透明度裁剪", Range(0, 1)) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("剔除模式", Float) = 2
     
        // [Space]
        // [Header(Normals)]
        
        // _NormalTex ("法线贴图", 2D) = "bump" {}
        // _NormalScale ("法线贴图强度", Range(0, 2)) = 1Cube
        // _Parallax ("高度系数", Range (0.000, 0.08)) = 0
        
        _ReflectionTex ("反射贴图 (cube)", 2D) = "black" {}
        _ReflectRim ("反射范围往边缘衰减", Range(0.01, 5)) = 1
        _CubeLOD ("反射贴图LOD", Range(1, 20)) = 0
        _CubeRotation ("反射旋转", Range(0, 360)) = 0
        [HDR]_ReflectColor ("反射叠加色", Color) = (1,1,1,0)
         
        [Space]
        [Header(Emission)]
       
        [NoScaleOffset] _EmissionTex ("自发光强度遮罩 (R通道)", 2D) = "white" {}
        [HDR]_EmissionColor ("自发光叠加色", Color) = (1,1,1,1)
        [HDR]_MetalColor ("金属叠加色", Color) = (1,1,1,1)
    
     
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            
            Tags { "LightMode"="always" }
            Cull [_Cull]

            CGPROGRAM
            #pragma vertex vert_main_box
            #pragma fragment frag_main_box
            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma multi_compile_instancing
            #pragma multi_compile_fwdbase
            
            // 当前项目没有: 1.实时阴影和烘培阴影混合
            #pragma skip_variants LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_SCREEN

           
           // #pragma enable_d3d11_debug_symbols

            #include "UnityCG.cginc"
            //samplerCUBE _ReflectionTex;
            sampler2D _MainTex,_EmissionTex,_ReflectionTex;
            float4 _ReflectionTex_ST,_NoiseMask_ST,_NoisePara,_MainTex_ST; 
            fixed4 _ReflectColor,_Color,_EmissionColor,_MetalColor;
            float _ReflectRim,_CubeLOD,_Cutoff,_CubeRotation;
            
            struct appdata_r
                {
                    
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                    float2 uv : TEXCOORD0;
                    half3 normal : NORMAL;
                
                };

            struct v2f_main_r
                {
                   
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR;
                    float4 uv : TEXCOORD0;
                    float3 OView : TEXCOORD1;
                    float3 ONormal :TEXCOORD2;
                    UNITY_FOG_COORDS(3)
                };

            v2f_main_r vert_main_box (appdata_r v)
                {
                    v2f_main_r o;
                   // float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    
                   
                    o.OView = ObjSpaceViewDir(v.vertex);
                    o.ONormal = v.normal;
                    o.color = v.color;
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = v.uv;
                    
                    UNITY_TRANSFER_FOG(o,o.pos);
                    return o;
                }

                
            half4 frag_main_box (v2f_main_r i) : SV_Target
                {
                    
                    float time = fmod(_Time.y,50000);
                    // 开启凹凸，先取出视差图（高度图）。依据视差图修改UV。
                    
                    // 取出固有色
                    half4 baseColor = tex2D(_MainTex, i.uv.xy) * _Color * i.color.a;
                   
                    // 透明度裁剪
                    clip(baseColor.a - _Cutoff);
            
                   
                    
                    float3 V = normalize(i.OView);
                    float3 N = normalize(i.ONormal);

                    half4 col = baseColor;
                    col.a *= 3;
                    col.a = saturate(col.a);

                    
                   
                    float NdV = saturate(dot(N, V));
                    float3 cubemapUV = 2 * dot(V, N) * N - V; //-reflect(V,N)

                    if (_CubeRotation > 0)
                    {
                        float s, c;
                        sincos(radians(_CubeRotation), s, c);
                        cubemapUV.xz = mul(float2x2(float2(c, s), float2(-s, c)), cubemapUV.xz);
                    }
                    
                    half4 cubemap = tex2Dlod(_ReflectionTex, float4(V.xy * _ReflectionTex_ST.xy +_ReflectionTex_ST.zw + N.xy,V.z,_CubeLOD));
                   // half4 cubemap = texCUBElod(_ReflectionTex, float4(cubemapUV,_CubeLOD));
                    cubemap *= pow(1-NdV,_ReflectRim);
                 //      Cube
                 //  float2 maskUV = i.uv.zw * _NoiseMask_ST.xy + _NoiseMask_ST.zw * time;
                 //  fixed3 mask = tex2D(_NoiseMask, maskUV);
                 //  float2 maskUV1 = i.uv.zw * _NoiseMask_ST.xy *_NoisePara.z - _NoisePara.w * time;
                 //  fixed3 mask2 = tex2D(_NoiseMask, maskUV1);
                    fixed3 emission = tex2D(_EmissionTex, i.uv.xy);
                    col.rgb += _MetalColor * cubemap.rgb * emission.r;
                    col.rgb += col.rgb * _EmissionColor * i.color.rgb * emission.b;
                    col.rgb = lerp(col.rgb, cubemap.rgb * _ReflectColor.rgb ,_ReflectColor.a * (1-emission.g ));
           
                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                }
            ENDCG
        }
    }

    
}
