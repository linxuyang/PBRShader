// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MC/Effect/OutLighting_Stencil" {
Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _OutlineWidth ("OutlineWidth", Range(0,1)) = 0.05
    [HDR]_OutlineColor ("OutlineColor", Color) = (1, 1, 1, 1)
}
 
SubShader {
    //Queue需要设置为Transparent透明队列，因为一般场景里面建筑物等物件的Queue都是Geometry不透明队列，这里需要保证
    //这个shader渲染的角色需要比场景不透明物件渲染得晚，这样才能知道深度有没被场景物件刷新过，当前shader渲染
    //的角色有没有被场景物件“遮住”
    Tags { "Queue"="Transparent" "RenderType"="Opaque" }
 
    CGINCLUDE
    #include "UnityCG.cginc"
 
    struct v2f {
        float4 vertex : SV_POSITION;
        half2 texcoord : TEXCOORD0;
    };
 
    sampler2D _MainTex;
    float4 _MainTex_ST;
    float _OutlineWidth;
    float4 _OutlineColor;
 
    //没被遮住部分的顶点着色器
    v2f vert (appdata_base v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
        return o;
    }
 
    //被遮住部分的顶点着色器
    v2f vert_outline (appdata_base v)
    {
        v2f o;  
		//float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
		//viewNormal.z = -0.5;
		//viewNormal = normalize(viewNormal);
		//float3 viewPos = viewNormal * _OutlineWidth;
		//float3 pPos = mul(UNITY_MATRIX_P,viewPos);
		//o.vertex = UnityObjectToClipPos(v.vertex);
		//o.vertex.xy += pPos * _OutlineWidth; 

		float4 viewPos = mul(UNITY_MATRIX_MV,v.vertex);
		float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
		normal.z = -0.4;
		viewPos = viewPos + float4(normalize(normal),0) * _OutlineWidth;
		o.vertex = mul(UNITY_MATRIX_P,viewPos);

		//float2 offset = TransformViewToProjection(viewNormal.xy); 
		//o.vertex = UnityObjectToClipPos(v.vertex);
        //o.vertex.xy += offset * _OutlineWidth;
        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
        return o;
    }

    ENDCG
 
    //没被遮住部分的Pass
    Pass {
        //ZTest LEqual
        Stencil
        {
            Ref 1
            Comp Always
            Pass Replace 
            ZFail Replace 
        }
 
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

		fixed4 frag (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.texcoord);
			UNITY_OPAQUE_ALPHA(col.a);
			return col;
		}
        ENDCG
    }
 
    //被遮住部分的Pass
    Pass {
        //ZTest Greater
        Stencil
        {
            Ref 1
            Comp NotEqual
        }
 
        CGPROGRAM
        #pragma vertex vert_outline
        #pragma fragment frag_outline

		fixed4 frag_outline (v2f i) : SV_Target
		{
			return _OutlineColor;
		}
        ENDCG
    }
}
 
}