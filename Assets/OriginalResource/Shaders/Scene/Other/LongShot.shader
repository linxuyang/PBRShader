// 给中远景面片使用，透明、只开启高度雾
Shader "MC/Scene/LongShot"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        [Space]
        [Header(World Space Height Fog)]
        [Toggle(_HFOG_ON)] _HFogToggle(":: 开启高度雾", Float) = 1
        _HFogColor1 ("高度雾顶部颜色", Color) = (.5,.5,.5,.5)
        _HFogColor2 ("高度雾底部颜色", Color) = (.5,.5,.5,.5)
        _HFogStart ("高度雾区域起始位置(世界坐标Y轴)", Float) = 0
        _HFogHeight ("高度雾区域的厚度", Float) = 0
        [KeywordEnum(Linear, Exp)] _HFogFunc ("高度雾衰减方式", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #pragma multi_compile _ UBPA_FOG_ENABLE
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2

            //#pragma shader_feature_local _HFOG_ON
            //#pragma shader_feature _HFOGFUNC_LINEAR _HFOGFUNC_EXP
            #include "UnityCG.cginc"



            struct appdata
            {
                half4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos: TEXCOORD1;
            };

            sampler2D _MainTex;
            half4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.1);
                
                return col;
            }
            ENDCG
        }
    }
}
