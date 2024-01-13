Shader "MC/Effect/UICardSweepLight"
{
    Properties
    {
        [HDR]_BrightColor("亮色", Color) = (1,1,1,1)
		[HDR]_MidColor("中间色", Color) = (1,1,1,1)
		[HDR]_DarkColor("暗色", Color) = (1,1,1,1)
		_ColorRange("亮色羽化/暗色羽化/偏移",Vector) = (0,0,0,0)
	    _MainTex("RGBA", 2D) = "black" { } 
        _Sweep("流光", Range(-1,2)) = 0.0
        _MaskTex("R:Noise G:Noise2 B:Mask", 2D) = "black" { } 
        _DistortPower("扭曲强度Noise/Noise2/SinFre/SinAmp",Vector) =  (0,0,0,0)
		_NoiseTex_ST("NoiseUV重复/速度",Vector) =  (1,1,0,0)
		_Noise2Tex_ST("Noise2UV重复/速度",Vector) =  (1,1,0,0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"}
		Blend SrcAlpha OneMinusSrcAlpha
		//Cull [_Cull] Lighting Off Fog { Mode Off }
		ZWrite Off
		//ColorMask [_ColorMask]
		//ZTest [_ZTest]

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma skip_variants FOG_EXP FOG_EXP2
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../CommonUtil.hlsl"

            float Feather (float ramp,float feather) {
                ramp -= 0.5; //以0.5为中心往两边羽化
                feather += 0.001;
                ramp += feather;
                ramp = ramp /(feather * 2);
                ramp = saturate(ramp);
                return ramp;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            float _Sweep;
		    float4 _MainTex_ST,_MaskTex_ST,_NoiseTex_ST,_Noise2Tex_ST,_ColorRange,_DistortPower;
			float4 _BrightColor,_MidColor,_DarkColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv;
               
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float time = fmod(_Time.y,50000);
                i.uv.w += abs(sin(i.uv.x * _DistortPower.z + time + _Sweep * 10)) * _DistortPower.w;
                half noise = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv.zw*_NoiseTex_ST.xy+time*_NoiseTex_ST.zw).r * _MaskTex_ST.z;
                noise = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv.zw*_NoiseTex_ST.xy-time*_NoiseTex_ST.zw*0.5+noise).r * _MaskTex_ST.w;
                half noise1 = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex, i.uv.zw * _Noise2Tex_ST.xy + time * _Noise2Tex_ST.zw + noise).g * 0.3;
                float lightUV = 1-abs(i.uv.w + noise1 * _DistortPower.x - _Sweep);
                lightUV = pow(lightUV + noise1 * _DistortPower.y,_ColorRange.w);
                half3 dark = lerp(_DarkColor,_MidColor,Feather(InvLerp(0, _ColorRange.z ,lightUV), _ColorRange.y));
                half3 bright = lerp(_MidColor,_BrightColor,Feather(InvLerp(_ColorRange.z , 1 ,lightUV), _ColorRange.x));  
			    half3 mixcolor = lerp(dark,bright,InvLerp(_ColorRange.z, _ColorRange.z + 0.01,lightUV));

                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                col.rgb = lerp(col.rgb,col.rgb * _DarkColor.rgb,InvLerp(_Sweep, _Sweep + 0.01,i.uv.w));
                col.rgb += max(mixcolor * lightUV,0);
                
                return col;
            }
            ENDHLSL
        }
    }
}
