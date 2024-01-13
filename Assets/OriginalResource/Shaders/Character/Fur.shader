Shader "MC/Character/Toon/Fur"
{
    Properties
    {
        [Header(Basics)]
        [BlendMode]_Mode("渲染类型", Float) = 0.0
        [HideInInspector]_SrcBlend("__src", Float) = 1.0
        [HideInInspector]_DstBlend("__dst", Float) = 0.0
        [HideInInspector]_SrcAlphaBlend("__srcAlpha", Float) = 1.0
        [HideInInspector]_DstAlphaBlend("__dstAlpha", Float) = 0.0
        [HideInInspector]_ZWrite("__zw", Float) = 1.0
        [HideInInspector]_AlphaScale("透明度", Range(0, 1)) = 1
        
		_MainTex("固有色(RGB)", 2D) = "white" {}
        _NormalTex("法线贴图", 2D) = "bump" {}
        [Space(20)]
        
        [Header(Shape)]
		_LayerTex("毛发噪声(R)", 2D) = "black" {}
		_CutoffEnd("毛发粗细", Range(0, 1)) = 0.5
		_FurLength("毛发长度", Range(0, 1)) = 0.25
		_EdgeFade("柔和度", Range(0, 0.5)) = 0.4

        [Space(10)]
        [Header(Lighting)]
        _LightFilter("平行光毛发穿透",  Range(-0.5, 0.5)) = 0.0
        _FresnelLv("轮廓光强度", Range(0, 10)) = 0
        _OcclusionColor("遮挡颜色", Color) = (1, 1, 1, 1)
        [Space(10)]
        [Header(Out Force)]
        _Gravity("重力方向(世界坐标)", Vector) = (0, -1, 0, 0)
		_GravityStrength("重力系数", Range(0, 0.3)) = 0
        
        //染色
        [Space(20)]
        [Header(Dye)]
        [Toggle]_Dye("染色开关", Float) = 0
        [Space]
        [DyeColor]_Offset1("染色R", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset2("染色G", Vector) = (0, 0, 0, 0)
        [DyeColor]_Offset3("染色B", Vector) = (0, 0, 0, 0)
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "../CommonInclude.hlsl"
    #include "BasicToonInclude.hlsl"

    half _FUR_OFFSET;
    sampler2D _MainTex;
    sampler2D _LayerTex;
    sampler2D _NormalTex;
    sampler2D _DyeFlowMask;
    
    CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _LayerTex_ST;
    half4 _NormalTex_ST;
    half _CutoffEnd, _FurLength, _EdgeFade;
    
    half3 _Gravity;
    half _GravityStrength;

    half _LightFilter, _FresnelLv;
    half3 _OcclusionColor;
    half _AlphaScale;

    half _Dye;
    half3 _Offset1, _Offset2, _Offset3;
    CBUFFER_END

    struct VertexInput
    {
        float3 positionOS : POSITION;
        half3 normalOS : NORMAL;
        half4 tangentOS : TANGENT;
        half4 color : COLOR;
        half2 texcoord : TEXCOORD0;
    };
    
    struct VertexOutput
    {
        float4 positionCS : SV_POSITION;
        half4 uv : TEXCOORD0;
        half3 normalUV : TEXCOORD1;
        half4 normalWS : TEXCOORD2;
        half4 tangentWS : TEXCOORD3;
        half4 bitangentWS : TEXCOORD4;
        float3 positionWS : TEXCOORD5;
    };

    VertexOutput Vertex(VertexInput input)
    {
        VertexOutput output = (VertexOutput)0;
        // 重力方向从世界空间转换到模型空间
        half3 gravity = TransformWorldToObject(_Gravity);
        // 这里的法线是用来表示毛发生长方向的法线, 可能与模型真正的法线方向不同, 不能用于光照计算
        // 在法线的基础上叠加重力方向, 作为顶点偏移(毛发)的方向
        half3 direction = lerp(input.normalOS, lerp(input.normalOS, gravity, _GravityStrength), _FUR_OFFSET);
        // 挤出顶点, 挤出距离(毛发长度)由_FurLength和顶点色的透明度共同控制
        input.positionOS += direction * input.color.a * _FurLength * _FUR_OFFSET;
        // 这里用1或0表示该顶点有无毛发, 传递给frag
        output.normalUV.z = step(0, input.color.a * _FurLength - 0.0001);
    
        output.positionCS = TransformObjectToHClip(input.positionOS);
        // 计算各纹理UV
        output.uv.xy = TRANSFORM_TEX(input.texcoord, _MainTex);
        output.uv.zw = TRANSFORM_TEX(input.texcoord, _LayerTex);
        output.normalUV.xy = TRANSFORM_TEX(input.texcoord, _NormalTex);
        // 正常计算世界空间下的坐标、法线、切线、副切线
        float3 positionWS = TransformObjectToWorld(input.positionOS);
        output.positionWS = positionWS;
        half3 viewDirWS = GetWorldSpaceViewDir(positionWS);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        output.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
        return output;
    }

    half4 Fragment(VertexOutput input) : SV_Target
    {
        // 抛弃掉没有毛发的部位外扩出来的片元
        clip(input.normalUV.z - _FUR_OFFSET);
        // 这一步是为了将裸漏表面(即无毛发)的_FUR_OFFSET值改成0.5, 减小后续光照计算结果与毛发光照的差别
        // 避免出现毛发很亮, 但裸漏的皮肤很暗的情况
        half furOffset = lerp(0.5, _FUR_OFFSET, input.normalUV.z);
        // 采样毛发噪声纹理
        half alpha = tex2D(_LayerTex, input.uv.zw).r;
        // 调整整体毛发粗细
        half cutoff = lerp(0, 1 - _CutoffEnd, _FUR_OFFSET);
        clip(alpha - cutoff);
    
        // 固有色
        half4 color = tex2D(_MainTex, input.uv.xy);

        DyeColor(_Dye, _DyeFlowMask, color.rgb, input.uv.xy, _Offset1, _Offset2, _Offset3);

        // 采样法线纹理并通过矩阵计算出模型真正的法线, 用于光照计算
        half3 normalTS = UnpackCustomNormal(tex2D(_NormalTex, input.uv.xy), 1);
        half3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz,input.bitangentWS.xyz, input.normalWS.xyz));
        
        half3 viewDirWS = SafeNormalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));

        Light mainLight = GetMainLight();
        mainLight.color *= CHARACTER_LIGHT_INTENSITY;
        half nDotL = dot(mainLight.direction, normalWS);
        half vDotN = dot(normalWS, viewDirWS);
        
        // 直接光
        half3 dirLight = saturate(nDotL + _LightFilter + furOffset) * mainLight.color;
        // 环境光
        half3 SH = max(0, SampleSH(normalWS));
        // 环境光遮蔽系数
        half occlusion = furOffset * furOffset;
        occlusion += 0.04;
        // 菲涅尔系数
        half fresnel = 1 - max(0, vDotN);
        // 边缘光系数
        half rim = fresnel * occlusion;
        rim *= rim;
        rim *= _FresnelLv;
        // 边缘光
        half3 rimLight = rim * mainLight.color;
        // 经毛发遮蔽效果后的环境光
        half3 SHL = lerp(color.rgb * _OcclusionColor * SH, SH, occlusion);

        // 逐像素多光源
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, input.positionWS);
            nDotL = dot(light.direction, normalWS);
            dirLight += saturate(nDotL + _LightFilter + furOffset) * light.color;
            rimLight += rim * light.color;
        }
        // 在固有色的基础叠加各项光照
        color.rgb *= SHL + dirLight + rimLight;
    
        // 越靠近毛发末端越透明
        color.a = 1 - furOffset * furOffset;
        // 模型表面法线与视角方向越垂直, 越透明(表现毛发在侧向观察时的半透明)
        color.a += 0.5f * vDotN - _EdgeFade;
        // 限制透明度范围
        color.a = saturate(color.a);
        color.a *= _AlphaScale;
        return color;
    }
    ENDHLSL
    
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"}
        Cull Back
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass // 正常表面渲染
        {
            Tags {"LightMode" = "FurRendererBase" "RenderType" = "Opaque" "Queue" = "Geometry"}
            Blend [_SrcBlend] [_DstBlend], [_SrcAlphaBlend] [_DstAlphaBlend]
            ZWrite [_ZWrite]
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
        
        Pass
        {
            Tags{"LightMode" = "FurRendererLayer"}
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
    Fallback "MC/OpaqueShadowCaster"
}