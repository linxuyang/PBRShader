Shader "MC/UI/UIRenderTexture"
{
	Properties
	{
		_Color ("Tint", Color) = (1,1,1,1)
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}

		//支持Mask 裁剪的部分
		//Start
		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15
		//End
	}
	SubShader
	{
		Tags
		{ 
			"RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
		}

		//支持Mask 裁剪的部分
		//Start
		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}
		ColorMask[_ColorMask]
		//End

		// No culling or depth
		Cull Off
		Lighting Off
		ZWrite Off
		Fog{ Mode Off }
		ColorMask RGB
		AlphaTest Greater .01
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMaterial AmbientAndDiffuse
		
		//透明底
		Blend One OneMinusSrcAlpha  //正常

		//带alpha底
		//Blend One SrcAlpha	//mi

		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			half4 _Color;
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			float4 _MainTex_ST;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color    : COLOR;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				half2 uv : TEXCOORD0;
				half4 color    : COLOR;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = TRANSFORM_TEX(v.uv,_MainTex);
				v.color.rgb *= v.color.a;	//混合方式的原因，rgb乘上a才能得到想要的效果
				o.color = v.color * _Color;//使用顶点颜色，才能在ugui中的color变量控制颜色
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * i.color;
				return col;
			}
			ENDHLSL
		}
	}
}
