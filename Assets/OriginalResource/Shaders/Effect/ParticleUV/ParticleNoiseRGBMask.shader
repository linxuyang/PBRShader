Shader "MC/Effect/ParticleNoiseRGBMask"
{
    Properties
    {
        _Offset_Z("Z Offset-深度偏移", Float) = 0
        [HDR]_MainColor("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" {}
        _MainSpeed_U("U Speed", Float) = 0
        _MainSpeed_V("V Speed", Float) = 0
        [Space]
        [Header(UV Noise)]
        _DistorFator("NoiseStrength-噪声强度", Float) = 1
        [Header(Noise01)]
		_NoiseTex01("NoiseTex-噪声纹理", 2D) = "black" {}
		_Noise01Speed_U("U Speed", Float) = 0
		_Noise01Speed_V("V Speed", Float) = 0
        [Header(Noise02)]
        [Toggle(_NOISE02_ON)]_Noise02On("开启第二噪声纹理", Float) = 0
		_NoiseTex02("NoiseTex-噪声纹理", 2D) = "black" {}
		_Noise02Speed_U("U Speed", Float) = 0
		_Noise02Speed_V("V Speed", Float) = 0
        [Space]
        [Header(Color Mask)]
        [Toggle(_COLOR_MASK_ON)]_ColorMaskOn("开启色彩遮罩", Float) = 0
		[NoScaleOffset]_Mask("Color Mask-色彩遮罩", 2D) = "white" {}
		_MaskSpeed("UV Speed", Vector) = (0, 0, 0, 0)
        [Space]
        [Header(Blend Mode)]
        [Enum(Off, 0, Front, 1, Back, 2)]_Cull("Cull Mode-裁剪模式", Float) = 2
        [Enum(One, 1, SrcAlpha, 5)] _ColorSrc("Src Blend-目标混合系数", Float) = 5
        [Enum(One, 1, OneMinusSrcAlpha, 10)] _ColorDst("Dst Blend-背景混合系数", Float) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent"
        }

        Cull [_Cull]
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            Blend[_ColorSrc][_ColorDst]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature_local _NOISE02_ON
            #pragma shader_feature_local _COLOR_MASK_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct v2f
            {
                half4 uv : TEXCOORD0;
                half4 noiseUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
                half4 color : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half _Offset_Z;
            half _MainSpeed_U;
            half _MainSpeed_V;
            half4 _MainColor;
            
            half _DistorFator;
            TEXTURE2D(_NoiseTex01);
            SAMPLER(sampler_NoiseTex01);
            half4 _NoiseTex01_ST;
            half _Noise01Speed_U, _Noise01Speed_V;
            
            #if _NOISE02_ON
            TEXTURE2D(_NoiseTex02);
            SAMPLER(sampler_NoiseTex02);
            half4 _NoiseTex02_ST;
            half _Noise02Speed_U, _Noise02Speed_V;
            #endif
            
            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);
            half4 _MaskSpeed;

            v2f vert(appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                //在(顶点->摄像机)方向做偏移
                float3 offsetVector = normalize(GetCameraPositionWS() - worldPos);
                worldPos += offsetVector * _Offset_Z;
                //顶点坐标从世界空间转换到裁剪空间
                o.vertex = TransformWorldToHClip(worldPos.xyz);
                o.color = v.color;
                o.uv.xy = v.uv; //原始UV
                o.uv.zw = TRANSFORM_TEX(v.uv, _MainTex); //主纹理拉伸、偏移后的UV
                o.noiseUV.xy = TRANSFORM_TEX(v.uv, _NoiseTex01); //噪声纹理01拉伸、偏移后的UV
                #if _NOISE02_ON
                o.noiseUV.zw = TRANSFORM_TEX(v.uv, _NoiseTex02); //噪声纹理01拉伸、偏移后的UV
                #endif
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                half time = _Time.y;
                
                //噪声纹理01UV叠加时间偏移
                half2 uv = i.noiseUV.xy + time * half2(_Noise01Speed_U, _Noise01Speed_V);
                half2 noise = SAMPLE_TEXTURE2D(_NoiseTex01,sampler_NoiseTex01,uv).rg;
                
                #if _NOISE02_ON
                //噪声纹理02UV叠加时间偏移
                uv = i.noiseUV.zw + time * half2(_Noise02Speed_U, _Noise02Speed_V);
                noise *= SAMPLE_TEXTURE2D(_NoiseTex02,sampler_NoiseTex02,uv);
                noise *= _DistorFator;
                #endif
                
                //主纹理UV叠加时间偏移与噪声偏移
                uv = i.uv.zw + time * half2(_MainSpeed_U, _MainSpeed_V) + noise;
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);
                
                #if _COLOR_MASK_ON
                //遮罩纹理UV叠加时间偏移
                uv = i.uv.xy + time * _MaskSpeed;
                half3 mask = SAMPLE_TEXTURE2D(_Mask,sampler_Mask,uv);
                col.rgb *= mask;
                #endif
                
                col *= _MainColor * i.color;
                return col;
            }
            ENDHLSL
        }
    }
}
