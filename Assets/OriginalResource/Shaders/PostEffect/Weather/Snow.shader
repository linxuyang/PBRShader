Shader "MC/PostEffect/Weather/Snow"
{
    Properties
    {
        // _NoiseTex ("Texture", 2D) = "white" {}
        _Color ("颜色", COLOR) = (1,1,1,1)
        _LAYERS ("层数", Range(1,100)) = 5
        _XSpeed ("横向速度", float) = 0
        _YSpeed ("纵向速度", float) = 0
        _SnowFar ( "远近", Range(5,100)) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
        }

        Pass
        {
            Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                half4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // sampler2D _NoiseTex;
            // float4 _NoiseTex_ST;
            half _LAYERS;
            half _XSpeed;
            half _YSpeed;
            half _SnowFar;
            half4 _Color;


            float Hash11(float p)
            {
                float3 p3 = frac(p.xxx * .1031);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.x + p3.y) * p3.z);
            }

            float2 Hash22(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.xx + p3.yz) * p3.zy);
            }

            half SnowSingleLayer(float2 uv, half layer)
            {
                //透视视野变大效果
                uv *= (_SnowFar + 4 * layer);
                float layerRand = Hash11(layer);
                //增加x轴移动
                float offsetX = uv.y * (layerRand - 0.5) * _XSpeed + layerRand * 3.14;
                //y轴下落过程
                float offsetY = _Time.y * _YSpeed;
                uv.xy += float2(offsetX, offsetY);
                // return fixed3(uv.x,uv.y,0);
                half2 grid = Hash22(floor(uv) + layer * 13.14);
                // return fixed3(grid.x,grid.y,0);
                uv = frac(uv);
                uv -= (grid * 2 - 1) * 0.35;
                uv -= 0.5;
                half r = length(uv);

                //让雪花的大小变化
                half circleSize = 0.05 * (1.0 + 0.3 * sin(_Time.y * grid.x + grid.y));
                half val = smoothstep(circleSize, -circleSize, r);
                val = pow(val, 0.7);
                // return float3(val,0,0);
                half alpha = val * grid.x;
                return alpha;
            }

            half4 Snow(float2 uv)
            {
                half alpha = float(0);
                for (half i = 0; i < _LAYERS; i++)
                {
                    alpha += SnowSingleLayer(uv, i);
                }
                clip(alpha - 0.01);
                half alphaFade = smoothstep(0.15, 0.3, uv.y);
                // return fixed4(1,1,1,alphaFade);
                return half4(_Color.rgb, _Color.a * alpha * alphaFade);
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // sample the texture
                return Snow(i.uv);
            }
            ENDHLSL
        }
    }
}