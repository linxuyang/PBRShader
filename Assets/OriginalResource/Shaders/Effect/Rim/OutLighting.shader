// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MC/Effect/OutLighting" //Shader文件索引路径
{
    Properties
    {
        _MainTex("Texture(RGB)",2D) = "grey"{} //主纹理
        _Color("Color",Color) = (0,0,0,1) //主纹理颜色
        _AtmoColor("Atmosphere Color",Color) = (0,0,0,0) //光晕颜色
        _Size("Size",Range(0,1)) = 0.1 //光晕范围
        _OutLightPow("Falloff",Range(1,10)) = 5 //光晕系数
        _OutLightStrength("Transparency",Range(5,20)) = 15 //光晕强度

        [HideInInspector]
        _AlphaScale("透明渐隐", Range(0, 1)) = 1
    }

    SubShader
    {
        Pass
        {
            Name "PlaneBase"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull Back //剔除背面

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
            float4 _AtmoColor;
            float _Size;
            float _OutLightPow;
            float _OutLightStrength;
            half _AlphaScale;
            CBUFFER_END

            struct appdata_base
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldvertpos : TEXCOORD1;
                float2 texcoord : TEXCOORD2;
            };

            //顶点着色器
            vertexOutput vert(appdata_base v)
            {
                vertexOutput o;
                //顶点位置
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                //法线
                o.normal = v.normal;
                //世界坐标顶点位置
                o.worldvertpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag(vertexOutput i) : COLOR
            {
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                color *= _Color;
                color.a *= _AlphaScale;
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "AtmosphereBase"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            Cull Front
            Blend SrcAlpha One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _AtmoColor;
            float _Size;
            float _OutLightPow;
            float _OutLightStrength;
            half _AlphaScale;
            CBUFFER_END

            struct appdata_base
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldvertpos : TEXCOORD1;
            };

            vertexOutput vert(appdata_base v)
            {
                vertexOutput o;
                //顶点位置以法线方向向外延伸
                v.vertex.xyz += v.normal * _Size;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.worldvertpos = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            float4 frag(vertexOutput i) : SV_Target
            {
                i.normal = normalize(i.normal);
                //视角法线
                float3 viewdir = normalize(i.worldvertpos.xyz - GetCameraPositionWS().xyz);
                float vdotN = dot(viewdir, i.normal);
                float4 color = _AtmoColor;
                //视角法线与模型法线点积形成中间为1向四周逐渐衰减为0的点积值，赋值透明通道，形成光晕效果
                color.a = pow(saturate(vdotN), _OutLightPow);
                color.a *= _OutLightStrength * vdotN;
                color.a *= _AlphaScale;
                return color;
            }
            ENDHLSL
        }

    }
    FallBack "Universal Render Pipeline/Simple Lit"
}