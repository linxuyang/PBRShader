Shader "MC/Scene/Skybox/NightSky"
{
	Properties
	{
		[Header(Base)]
		[HDR]_BaseColor ("Base Color", Color) = (1, 1, 1, 1)
		_BaseSmoothStep1 ("Base Smoothstep 1", Range(-2, 2)) = 1
		_BaseSmoothStep2 ("Base Smoothstep 2", Range(-2, 2)) = 0

		[Header(Star)]
		_StarTex ("Star Tex", 2D) = "black" {}
		[HDR]_TintColor ("Tint Color", Color) = (1, 1, 1, 1)
		_StarSpeed ("Star Speed", Vector) = (0, 0, 0, 0)

		[Header(Cloud)]
		_CloudTex ("Cloud Tex", 2D) = "black" {}
		[HDR]_CloudTintColor ("Cloud Tint Color", Color) = (1, 1, 1, 1)
		_CloudSpeed ("Cloud Speed", Vector) = (0, 0, 0, 0)

		[Header(Mask)]
		[HDR]_MaskColor ("Mask Color", Color) = (1, 1, 1, 1)
		_MaskSmoothStep1 ("Mask Smoothstep 1", Range(-2, 2)) = 0
		_MaskSmoothStep2 ("Mask Smoothstep 2", Range(-2, 2)) = 1

		[Header(Emission)]
		[HDR]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)
		_EmissionSmoothStep1 ("Emission Smoothstep 1", Range(-2, 2)) = 0
		_EmissionSmoothStep2 ("Emission Smoothstep 2", Range(-2, 2)) = 1
	}

	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="AlphaTest+50" "RenderType"="Background" }

		Zwrite Off

		Pass
		{
			Tags
            {
                "LightMode"="UniversalForward"
            }
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			half3 _BaseColor;
			half _BaseSmoothStep1, _BaseSmoothStep2;
			sampler2D _StarTex;
			half4 _StarTex_ST;
			half4 _TintColor;
			half2 _StarSpeed;
			sampler2D _CloudTex;
			half4 _CloudTex_ST;
			half4 _CloudTintColor;
			half2 _CloudSpeed;
			
			half4 _MaskColor;
			half _MaskSmoothStep1, _MaskSmoothStep2;

			half4 _EmissionColor;
			half _EmissionSmoothStep1, _EmissionSmoothStep2;


			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 rectangular : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;

				float3 t = v.vertex.xyz * _ProjectionParams.z + _WorldSpaceCameraPos.xyz;
				// o.pos = UnityObjectToClipPos(float4(t, 1));
				o.pos = TransformObjectToHClip(t);
#if SHADER_API_D3D11 || SHADER_API_METAL || SHADER_API_VULKAN
				o.pos.z = 0;
#else
				o.pos.z = o.pos.w;
#endif

				float2 uv1 = TRANSFORM_TEX(v.rectangular, _StarTex);
				float2 uv2 = TRANSFORM_TEX(v.rectangular, _CloudTex);
				o.uv = float4(uv1, uv2);
				// o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = TransformObjectToWorldNormal(v.normal);

				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half3 worldNormal = normalize(i.worldNormal);

				half baseVal = smoothstep(_BaseSmoothStep1, _BaseSmoothStep2, worldNormal.y);
				half3 baseCol = _BaseColor * baseVal;

				half2 uvOffset = _StarSpeed * _Time.x;
				half4 starCol = _TintColor * tex2D(_StarTex, i.uv.xy + uvOffset);

				uvOffset = _CloudSpeed * _Time.x;
				half4 couldCol = _CloudTintColor * tex2D(_CloudTex, i.uv.zw + uvOffset);

				half maskVal = _MaskColor.a * smoothstep(_MaskSmoothStep1, _MaskSmoothStep2, worldNormal.y);

				half emissionVal = smoothstep(_EmissionSmoothStep1, _EmissionSmoothStep2, worldNormal.y);
				half3 emissionCol = _EmissionColor.rgb * _EmissionColor.a * emissionVal;

				half4 finalCol = half4(baseCol, 1);
				finalCol.rgb += starCol.rgb * starCol.a;
				finalCol.rgb += couldCol.rgb * couldCol.a;
				finalCol.rgb = lerp(finalCol.rgb, _MaskColor.rgb, maskVal);
				finalCol.rgb += emissionCol;

				return finalCol;
			}
			ENDHLSL
		}
	}
	Fallback Off
}
