Shader "MC/Scene/PoisonCircle"
{
    Properties
    {
        
        _MainTex ("主纹理", 2D) = "white" {}
        _NoiseTex ("噪声", 2D) = "white" {}
        _Color("颜色", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        ZTest LEqual
        ZWrite false
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            Cull back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile _ UBPA_FOG_ENABLE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD3;
            };

            sampler2D _CameraDepthTexture;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            fixed4 _Color;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed noise = tex2D(_NoiseTex, i.uv + float2(0.1*_Time.y,0) ).r;
                noise += tex2D(_NoiseTex, i.uv - float2(_Time.y*0.1,0) - 0.2 ).r;

                float partZ = i.projPos.z;
                float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
                
                // 渐隐距离=16,这里直接写死
                partZ/=16;
                // 从外往里看的透明度变化
                float backAlpha = partZ > 1?1:(partZ*partZ*partZ*partZ*partZ);

                half4 col = tex2D(_MainTex, i.uv + noise);
                col = pow(col.r,2.2) * 4 * backAlpha;
                col += _Color;
                
                if (sceneZ-partZ < 0.1)
                    col += 0.5;
                
                col.rgb = saturate(col.rgb);
                col.a *= max(backAlpha,0.1);
                // apply fog
                // UBPA_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
        
        Pass
        {
            Cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile _ UBPA_FOG_ENABLE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD3;
            };

            sampler2D _CameraDepthTexture;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed noise = tex2D(_NoiseTex, i.uv + float2(0.1*_Time.y,0) ).r;
                noise += tex2D(_NoiseTex, i.uv - float2(_Time.y*0.1,0) - 0.2 ).r;


                half4 col = tex2D(_MainTex, i.uv + noise);
                col = pow(col.r,2.2) * 4;
                col += _Color;
                
                float partZ = i.projPos.z;
                float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
                if (sceneZ-partZ < 0.1)
                    col += 0.5;
                
                // apply fog
                // UBPA_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
