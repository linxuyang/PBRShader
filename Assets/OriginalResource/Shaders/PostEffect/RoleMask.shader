// 3d角色遮罩
Shader "MC/PostEffect/RoleMask"
{
    Properties {
        _TopColor("顶部颜色",COLOR)=(0,0,0,1)
        _BottomColor("底部颜色",COLOR)=(1,1,1,1)
        _StarColor("星星颜色", Color) = (1,1,0,0.1)
        _Alpha("透明度", Range(0,1)) = 1
    }
    SubShader {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                //todo 角色stenciID目前为2,考虑改成变量
                Ref 2
                Comp Equal
            }
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            // 全屏三角形UV变换
            float2 TransformTriangleVertexToUV(float2 vertex)
            {
                float2 uv = (vertex + 1.0) * 0.5;
                return uv;
            }

            // 全屏三角形的顶点处理
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
                o.uv = TransformTriangleVertexToUV(v.vertex.xy);
                #if UNITY_UV_STARTS_AT_TOP
                    o.uv = o.uv * float2(1.0, -1.0) + float2(0.0, 1.0);
                #endif
                return o;
            }
            
            //升级版伪随机，接受一个vec2，产生x和y都是0到1的vec2
            float2 random2( float2 p ) {
                return frac(sin(float2(dot(p,float2(234234.1,54544.7)), sin(dot(p,float2(33332.5,18563.3))))) *323434.34344);
            }


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half3 _TopColor;
            half3 _BottomColor;
            half4 _StarColor;
            half _Alpha;

            half4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                // 计算随机星星(星星密度用50写死)
                // 格子坐标
                float2 ipos = floor(uv*50);
                // 每个格子的uv(0->1)
                float2 fpos = frac(uv*50);
                // 随机坐标(x,y)(0~1之间)
                float2 targetPoint = random2(ipos);
                // 计算半径
                half dist = length(fpos - targetPoint);
                half4 starColor = _StarColor;
                // 半径小于0.06的亮起来
                starColor.rgb *= 1 - step(0.06,dist);
                // 自底向上的渐变加星星颜色，再计算透明度
                half4 color = half4(lerp(_BottomColor,_TopColor,uv.y) + starColor.rgb * starColor.a,_Alpha);
                return color;
            }
            ENDHLSL
        }
    }
}
