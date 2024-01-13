// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//深度图渲染Shader
Shader "Hidden/DepthMapRenderer"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		
		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#define UP_VECTOR float3(0, 1, 0)

			uniform float _MaxDepth;
			uniform float _DepthPower;
			uniform float _WaterHeight;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float depth : TEXCOORD0;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

				o.depth = _WaterHeight - worldPos.y;

				o.worldNormal = normalize(TransformObjectToWorldNormal(v.normal));

				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float depth = pow(saturate(1 - i.depth / _MaxDepth), _DepthPower);
				float depthStep = step(0, i.depth);
				float3 contourTangent = cross(UP_VECTOR, normalize(i.worldNormal));
				float2 uvDir = contourTangent.xz;
				uvDir = uvDir * 0.5f + 0.5f;
				float4 outPut = float4(depth, uvDir, depthStep);
				// outPut.rgb = GammaToLinearSpace(outPut.rgb);
				return outPut;
			}
			ENDHLSL
		}
	}
}
