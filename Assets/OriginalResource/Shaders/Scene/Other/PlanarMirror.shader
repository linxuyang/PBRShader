Shader "MC/Scene/PlanarMirror"
{
	Properties
	{
		_Color("镜面颜色", Color) = (1, 1, 1, 1)
		_EmissionCol("自发光", Color) = (1, 1, 1, 1)
		_EmissionPow("自发光衰减", Range(1, 50)) = 1
		_EmissionClamp("自发光范围", Range(0, 1)) = 0
		_MirrorPow("镜面衰减", Range(1, 5)) = 1
		_MirrorClamp("镜面范围", Range(0, 1)) = 1
		_MirrorScale("镜面增强", Range(1, 20)) = 1
		_NormalTex("法线贴图", 2D) = "bump" {}
		_NormalScale("法线强度", Range(0.01, 0.1)) = 0.02
		_FlowSpeed("流动速度", Range(0.1, 1)) = 0
		_HorizonMin("渐隐远边界", Range(0, 1)) = 0
		_HorizonMax("渐隐近边界", Range(0, 1)) = 0.4
		_Flow("涟漪中心", Vector) = (0.5, 0.5, 0, 0)
	}

	SubShader
	{
		Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos: TEXCOORD0;
				float2 uv : TEXCOORD1;
				float2 normalUv : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
			};

			TEXTURE2D(_ReflectionTex);
			SAMPLER(sampler_ReflectionTex);
			half4 _Color;
			half3 _EmissionCol;
			half _EmissionPow, _EmissionClamp;
			half _MirrorPow, _MirrorClamp, _MirrorScale;
			TEXTURE2D(_NormalTex);
			SAMPLER(sampler_NormalTex);
			half4 _NormalTex_ST;
			half _NormalScale, _HorizonMin, _HorizonMax;
			half _FlowSpeed;
			half2 _Flow;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = TransformObjectToWorldNormal(v.normal);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.uv = v.uv;
				o.normalUv = TRANSFORM_TEX(v.uv, _NormalTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half distanceVal = distance(i.uv, half2(0.5, 0.5));
				distanceVal = 1 - distanceVal * 2;

				float3 worldViewDir = normalize(GetWorldSpaceViewDir(i.worldPos));
				float vDotN = saturate(dot(worldViewDir, normalize(i.worldNormal)));
				vDotN = smoothstep(_HorizonMin, _HorizonMax, vDotN);

				float2 flowDir = normalize(i.uv - _Flow);
				half timeVal = _Time.y * _FlowSpeed;
				half phase0 = frac(timeVal);
				half phase1 = frac(timeVal + 0.5f);
				half flowLerp = abs((0.5f - phase0) * 2);
				half2 uvOffset0 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.normalUv-flowDir*phase0)).xy;
				half2 uvOffset1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.normalUv-flowDir*phase1)).xy;
				half2 uvOffset = lerp(uvOffset0, uvOffset1, flowLerp);

				half3 refleCol = SAMPLE_TEXTURE2D(_ReflectionTex,sampler_ReflectionTex,i.screenPos.xy/i.screenPos.w+uvOffset*_NormalScale).rgb;
				half refleVal = smoothstep(1 - _MirrorClamp, 1, distanceVal);
				refleVal = pow(refleVal, _MirrorPow);
				refleCol *= _MirrorScale * refleVal;

				half emissionVal = pow(smoothstep(0, 1 - _EmissionClamp, distanceVal), _EmissionPow);
				half3 mix = lerp(refleCol, _EmissionCol, emissionVal);

				half4 finalCol = _Color;
				finalCol.rgb = finalCol.rgb + mix;
				finalCol.a *= vDotN;

				return finalCol;
			}
			ENDHLSL
		}
	}
}
