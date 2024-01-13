Shader "MC/Scene/GroundGrass"
{
    Properties
    {
        [Header(Grass Color)]
        _Grass ("草纹理", 2D) = "white" {}
        [HDR] _TopColor ("顶部颜色",color) = (1,1,1,1)
        [HDR] _BottomColor ("底部颜色",color) = (1,1,1,1)

        _Cutout("透明度裁剪阈值",Range(0,1)) = 1

        [Space]
        [Header(Ambient Color)]
        [Toggle(_AMBIENT_ON)] _AmbientToggle("开启环境光", Int) = 0
        _AmbientStrength("环境光强度", Range(0,1)) = 1
        _lerpScale("插值范围", Range(0,1)) = 1

        [Space]
        [Header(Specular)]
        [Toggle(_SPECULAR_ON)] _SpecularToggle("开启高光", Float) = 0
        [HDR] _SpecularColor ("高光叠加色", Color) = (1,1,1,1)
        [PowerSlider(2)]_Glossiness ("光滑度", Range(0, 1)) = .5
        [PowerSlider(2)]_SpecularPower ("高光强度", Range(0, 1)) = .2

        [Space]
        [Header(Grass Motion)]
        _WindSpeed("风速",Range(0,1)) = 1
        _WindRandom("风强",Range(0,1)) = 1

        [Space]
        [Header(Grass Interactive)]
        _Strength("弯曲强度", float) = 1
        _PushRadius("弯曲系数", float) = 1

        [Space]
        [Header(Grass Rippling)]
        [Toggle(_Rippling_ON)]_RipplingToggle("开启麦浪", Int) = 0
        _Rippling("麦浪噪声", 2D) = "white" {}
        [HDR]_RipplingColor("麦浪颜色", Color) = (1,1,1,1)
        _Ripplingspeed("麦浪摆动速度", Range( 0 , 10)) = 0
        _RipplingFluctuation("摆动强度", Range( 0 , 1)) = 0
        _VerticalPower("根部固定系数",Range(0,1)) = 1
        _Angle("摆动角度", Range( 0 , 360)) = 0
        _Gradual ("渐变", Range( 0 , 5)) = 0

        [Space]
        [Header(Lightning)]
        _LightningIntensity ("雷光强度", Range(0,1)) = 1

    }

    SubShader
    {
        Tags
        {
            "Queue"="AlphaTest" "RenderPipeline" = "UniversalPipeline" "RenderType"="Grass" "IgnoreProjector" = "True"
        }
        LOD 100
        Cull Off

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile_fwdbase
            // #pragma multi_compile_fog
            #pragma skip_variants FOG_EXP FOG_EXP2


            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma skip_variants DIRLIGHTMAP_COMBINED LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON SHADOWS_SHADOWMASK

            #pragma shader_feature _AMBIENT_ON
            #pragma shader_feature _Rippling_ON
            #pragma shader_feature_local _SPECULAR_ON
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "../../CommonInclude.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Grass_ST;
            half4 _TopColor;
            half4 _BottomColor;
            half _Cutout;
            half _AmbientStrength;
            half _lerpScale;
            half4 _SpecularColor; // 高光颜色
            half _Glossiness;
            half _SpecularPower;
            half _WindSpeed;
            half _WindRandom;
            half _Strength;
            half _PushRadius;
            half4 _Rippling_ST;
            half4 _RipplingColor;
            half _Ripplingspeed;
            half _RipplingFluctuation;
            half _Angle;
            half _Gradual;
            half _LightningIntensity;
            half _VerticalPower;
            CBUFFER_END

            float4 _PlayerPos;

            float _End;
            float _Start;
            // 打雷
            half3 _LightningColor;

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(half4, _groundColor) //外部传入地表的颜色
            UNITY_INSTANCING_BUFFER_END(Props)

            TEXTURE2D(_Grass);
            SAMPLER(sampler_Grass);
            TEXTURE2D(_Rippling);
            SAMPLER(sampler_Rippling);

            struct a2v
            {
                half4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal :NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 Ruv : TEXCOORD1;
                float3 worldPos :TEXCOORD2;
                half3 worldNormal :TEXCOORD3;
                float4 worldView : TEXCOORD4; //w = distance(view)
                half3 worldLight : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 shadowCoord : TEXCOORD7;
                float1 fogCoord: TEXCOORD8;
                half3 sh: TEXCOORD9;
            };

            float3 pushDown(float3 worldPos, float4 height)
            {
                float dis = distance(_PlayerPos.xyz, worldPos);
                float pushDown = saturate(((1 - dis) + _PushRadius) * height.y * 0.23 * _Strength);
                float3 direction = normalize(worldPos.xyz - _PlayerPos.xyz);
                // direction.y *= 0.5;
                worldPos.xyz += direction * pushDown;

                return worldPos;
            }

            float2 rotateUV(float2 uv, float radians)
            {
                float s, c;
                sincos(radians, s, c);
                float2x2 rotate = float2x2(float2(c, -s), float2(s, c));
                return mul(rotate, uv);
            }

            float3 mod2D289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float2 mod2D289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float3 permute(float3 x) { return mod2D289(((x * 34.0) + 1.0) * x); }

            float snoise(float2 v)
            {
                const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
                float2 i = floor(v + dot(v, C.yy));
                float2 x0 = v - i + dot(i, C.xx);
                float2 i1;
                i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
                float4 x12 = x0.xyxy + C.xxzz;
                x12.xy -= i1;
                i = mod2D289(i);
                float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
                float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
                m = m * m;
                m = m * m;
                float3 x = 2.0 * frac(p * C.www) - 1.0;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;
                m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
                float3 g;
                g.x = a0.x * x0.x + h.x * x0.y;
                g.yz = a0.yz * x12.xz + h.yz * x12.yw;
                return 100.0 * dot(m, g);
            }


            //BlinnPhong 模型的高光
            inline half3 Specular(half3 N, float3 V, half3 L, half NdL, half3 diffuse, half gloss, half specular)
            {
                //取中间值
                float3 halfDir = normalize(V + L);
                gloss *= 128;
                gloss = max(.005, gloss);
                // 归一化系数，为了维持能量守恒，反射光不能大于入射光。 原理:http://www.thetenthplanet.de/archives/255
                half normalizationTerm = (gloss + 2.0) / (2 * PI); // normalized blinn-phong
                specular *= normalizationTerm;

                float NdH = max(0.0001, dot(N, halfDir));
                // Blinn-Phong 计算
                half specTerm = max(0, pow(NdH, gloss)) * specular;
                half3 col = specTerm * _SpecularColor.rgb * _SpecularColor.a;
                // 叠加固有色
                #if _SPECULAR_DIFFUSE
		                col *= diffuse;
                #endif
                return col;
            }

            v2f vert(a2v v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);


                o.uv.xy = TRANSFORM_TEX(v.uv, _Grass);
                o.uv.zw = v.uv;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);


                //顶点动画
                float Y = pow(v.uv.y, _VerticalPower * 5);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);

                float mulTime = _Time.y * 0.25;
                float2 temp_cast = (mulTime).xx;
                float simplePerlin = snoise(temp_cast) * 2;
                float RandomDirection = sin(simplePerlin * _WindSpeed * 8 + o.worldPos.z) * _WindRandom;
                o.worldPos.xz += RandomDirection * Y;
                o.worldPos.xyz = pushDown(o.worldPos, v.vertex.y);


                //风吹麦浪
                #if _Rippling_ON
                float Angle = radians(_Angle);
                o.Ruv.xy = TRANSFORM_TEX(rotateUV(o.worldPos.xz, Angle ), _Rippling);
                half4 Rippling = SAMPLE_TEXTURE2D_LOD(_Rippling, sampler_Rippling,
                                                      o.Ruv.xy + _Time.x * 0.25 * _Ripplingspeed, 0);

                float Rs = Rippling.r * _RipplingFluctuation * Y;
                o.worldPos.xz -= Rs;

                //
                //片段着色
                o.Ruv.z = Rippling.r;
                o.Ruv.w = v.uv.y;
                #endif

                o.pos = TransformWorldToHClip(o.worldPos);
                o.worldView.xyz = GetWorldSpaceViewDir(o.worldPos.xyz);
                // 计算高光
                #if _SPECULAR_ON
                o.worldView.w = length(o.worldView.xyz); //物体到视角的距离
                // o.worldView.w = 1 - saturate(o.worldView.w / _SpecularFade);
                #endif

                o.worldLight.xyz = _MainLightPosition.xyz - o.worldPos;

                o.sh = SampleSH(o.worldNormal);

                o.shadowCoord = TransformWorldToShadowCoord(o.worldPos);
                o.fogCoord = ComputeFogFactor(o.pos.z);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 topColor = _TopColor;
                half4 bottomColor = _BottomColor;
                half4 col = SAMPLE_TEXTURE2D(_Grass, sampler_Grass, i.uv.xy);

                half3 worldNormal = normalize(i.worldNormal);
                //灯光方向
                half3 worldLightDir = normalize(_MainLightPosition.xyz);
                half NDL = max(0, dot(worldNormal, worldLightDir)) * 0.5 + 0.5;

                //因为地表的颜色中已经有环境色，所以提前算，以免计算2次	
                #if _AMBIENT_ON
                topColor.rgb *= i.sh * _AmbientStrength;
                bottomColor *= UNITY_ACCESS_INSTANCED_PROP(Props, _groundColor); //地表的颜色*底部的颜色
                #endif


                // 计算高光
                #if _SPECULAR_ON
                half3 SpecLightDir = GetSpecularLightDir(i.worldLight, i.worldPos);
                topColor.rgb += Specular(worldNormal, i.worldView, SpecLightDir, NDL, topColor.rgb,
                                                  _Glossiness, _SpecularPower);
                #endif

                half4 addColor = lerp(bottomColor, topColor, i.uv.w * _lerpScale);

                #if _AMBIENT_ON
                col.rgb = addColor;
                #else
				col.rgb *= addColor.rgb;
                #endif
                clip(col.a - _Cutout);

                half3 diffuse = (1 + _LightningColor.rgb * _LightningIntensity) * col.rgb;

                // 麦浪颜色
                #if _Rippling_ON
                float distance = length(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                float DFactor = (_End - abs(distance)) / (_End - _Start);

                diffuse += saturate(pow(i.Ruv.w * 2.3, _Gradual * 2.3)) * _RipplingColor * saturate(DFactor);
                #endif

                diffuse = MixFog(diffuse, i.fogCoord);
                return half4(diffuse, 1);
            }
            ENDHLSL
        }

    }

    // FallBack "Diffuse"

}