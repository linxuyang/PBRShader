using System;
using UnityEditor;
using UnityEngine.Assertions;
using UnityEngine;

class SavedParameter<T> where T : IEquatable<T>
{
    internal delegate void SetParameter(string key, T value);

    internal delegate T GetParameter(string key, T defaultValue);

    readonly string m_Key;
    bool m_Loaded;
    T m_Value;

    readonly SetParameter m_Setter;
    readonly GetParameter m_Getter;

    public SavedParameter(string key, T value, GetParameter getter, SetParameter setter)
    {
        Assert.IsNotNull(setter);
        Assert.IsNotNull(getter);

        m_Key = key;
        m_Loaded = false;
        m_Value = value;
        m_Setter = setter;
        m_Getter = getter;
    }

    void Load()
    {
        if (m_Loaded)
            return;

        m_Loaded = true;
        m_Value = m_Getter(m_Key, m_Value);
    }

    public T value
    {
        get
        {
            Load();
            return m_Value;
        }
        set
        {
            Load();

            if (m_Value.Equals(value))
                return;

            m_Value = value;
            m_Setter(m_Key, value);
        }
    }
}

sealed class SavedBool : SavedParameter<bool>
{
    public SavedBool(string key, bool value)
        : base(key, value, EditorPrefs.GetBool, EditorPrefs.SetBool)
    {
    }
}

public enum SurfaceType
{
    Opaque,
    Transparent
}

public enum BlendMode
{
    Alpha, // Old school alpha-blending mode, fresnel does not affect amount of transparency
    Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
    Additive,
    Multiply
}

public enum RenderFace
{
    Front = 2,
    Back = 1,
    Both = 0
}

public enum AoSource
{
    AlbedoAlpha = 0, 
    EmissionAlpha = 1,
    None= 2
}

class Styles
{
    // Catergories

    public static readonly GUIContent surfaceOptions = new GUIContent("Surface Options", "控制材质的基础渲染类型(是否半透明, 单双面渲染等)");

    public static readonly GUIContent surfaceType = new GUIContent("表面类型", "不透明或半透明");

    public static readonly GUIContent blendingMode = new GUIContent("混合模式", "控制半透明物体颜色与前景颜色的混合方式");

    public static readonly GUIContent cullingText = new GUIContent("渲染的面", "选择渲染几何体的正面或背面");

    public static readonly GUIContent alphaClipText = new GUIContent("透明度裁剪", "根据纹理贴图的透明度裁剪模型");

    public static readonly GUIContent alphaClipThresholdText = new GUIContent("裁剪阈值", "透明度低于阈值的区域将被裁剪");

    public static readonly GUIContent receiveShadowText = new GUIContent("接收阴影", "接收其他物体造成的阴影");

    public static readonly GUIContent surfaceInputs = new GUIContent("Surface Inputs", "基础表面纹理参数");

    public static readonly GUIContent baseMap = new GUIContent("基础纹理", "物体表面纹理");

    public static readonly GUIContent baseColor = new GUIContent("基础色调", "物体表面色调");

    public static readonly GUIContent normalMetalSmoothMap = new GUIContent("法线金属光滑度", "控制物体表面法线(RG)、金属度(B)和光滑度(A)");
    
    public static readonly GUIContent normalScale = new GUIContent("法线纹理强度", "增强或减弱法线纹理对模型表面法线的影响");
    
    public static readonly GUIContent metallic = new GUIContent("金属度", "控制模型整体金属度");
    
    public static readonly GUIContent smoothness = new GUIContent("光滑度", "控制模型整体光滑度");
    
    public static readonly GUIContent aoSource = new GUIContent("环境光遮蔽", "环境光遮蔽来源");
    
    public static readonly GUIContent aoScale = new GUIContent("环境光遮蔽强度", "环境光遮蔽强度");
    
    public static readonly GUIContent emissionColor = new GUIContent("自发光颜色", "自发光颜色");
    
    public static readonly GUIContent emissionAOMap = new GUIContent("自发光-环境光遮蔽", "控制物体表面自发光(RGB)、环境光遮蔽(A)");
    
    public static readonly GUIContent environmentReflection = new GUIContent("环境反射", "反射环境间接光");

    public static readonly GUIContent advancedLabel = new GUIContent("Advanced", "渲染底层相关的技术参数");

    public static readonly GUIContent queueSlider = new GUIContent("渲染优先级", "数值越小越优先渲染");
}