Shader "MC/Scene/TransparentWithReflectCube"
{
    Properties
    {
        // _MainCube ("反射盒", Cube) = "white" {}
        _Color("玻璃颜色与透明度", Color) = (0.5,0.5,0.5,0.5)
        _MIP_LEVEL("模糊等级", Range(0,4)) = 1
        // _FresnelScale("菲涅尔系数", Range(0,0.05)) = 0.01
        [PowerSlider(2)]_ReflIntensity("反射强度", Range(0,2)) = 0.1
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("背面剔除", float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One OneMinusSrcAlpha
        LOD 100
        Cull [_Cull]
        ZWrite off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2
			#pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            inline float Pow5(float src)
            {
                return src*src*src*src*src;
            }

            UNITY_DECLARE_TEXCUBE(_MainCube);
            half4 _MainCube_HDR;
            half4 _Color;
            half _MIP_LEVEL;
            // half _FresnelScale;
            half _ReflIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i,fixed facing : VFACE) : SV_Target
            {
                i.worldNormal = normalize(i.worldNormal);
                i.worldNormal *= facing>0?1:-1;
                float3 worldView = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 reflDir = reflect(-worldView,i.worldNormal);
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir,_MIP_LEVEL);
                half3 env = DecodeHDR(rgbm, unity_SpecCube0_HDR) * _ReflIntensity;
                // half fresnel = _FresnelScale + (1 - _FresnelScale)*Pow5(1 - dot(worldView, i.worldNormal));
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, env);
                // return half4((fresnel).xxx,1);
                return half4(env + _Color.rgb * _Color.a, _Color.a);
            }
            ENDCG
        }
    }
}
