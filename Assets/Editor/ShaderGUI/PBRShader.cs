using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class PBRShader : ShaderGUI
{
    protected MaterialEditor materialEditor { get; set; }
    protected MaterialProperty baseMapProp { get; set; }
    protected MaterialProperty baseColorProp { get; set; }
    protected MaterialProperty alphaCutoffProp { get; set; }
    protected MaterialProperty metallicProp { get; set; }
    protected MaterialProperty smoothnessProp { get; set; }
    protected MaterialProperty normalScaleProp { get; set; }
    protected MaterialProperty normalMetalSmoothMapProp { get; set; }
    protected MaterialProperty emissionColorProp { get; set; }
    
    protected MaterialProperty aoSourceProp { get; set; }
    protected MaterialProperty occlusionStrengthProp { get; set; }
    protected MaterialProperty emissionAOMapProp { get; set; }
    protected MaterialProperty environmentReflectionsProp { get; set; }
    protected MaterialProperty receiveShadowsProp { get; set; }
    protected MaterialProperty alphaClipProp { get; set; }
    protected MaterialProperty surfaceTypeProp { get; set; }
    protected MaterialProperty blendModeProp { get; set; }
    protected MaterialProperty cullingProp { get; set; }
    protected MaterialProperty queueOffsetProp { get; set; }
    public bool m_FirstTimeApply = true;
    private const string k_KeyPrefix = "UniversalRP:Material:UI_State:";
    private string m_HeaderStateKey = null;

    protected string headerStateKey
    {
        get { return m_HeaderStateKey; }
    }

    SavedBool m_SurfaceOptionsFoldout;
    SavedBool m_SurfaceInputsFoldout;
    SavedBool m_AdvancedFoldout;

    public void FindProperties(MaterialProperty[] properties)
    {
        baseMapProp = FindProperty("_BaseMap", properties, false);
        baseColorProp = FindProperty("_BaseColor", properties, false);
        alphaCutoffProp = FindProperty("_Cutoff", properties);
        metallicProp = FindProperty("_Metallic", properties, false);
        smoothnessProp = FindProperty("_Smoothness", properties, false);
        normalScaleProp = FindProperty("_NormalScale", properties, false);
        normalMetalSmoothMapProp = FindProperty("_NormalMetalSmoothMap", properties, false);
        emissionColorProp = FindProperty("_EmissionColor", properties, false);
        aoSourceProp = FindProperty("_AoSource", properties, false);
        occlusionStrengthProp = FindProperty("_OcclusionStrength", properties, false);
        emissionAOMapProp = FindProperty("_EmissionAOMap", properties, false);
        environmentReflectionsProp = FindProperty("_EnvironmentReflections", properties, false);
        receiveShadowsProp = FindProperty("_ReceiveShadows", properties, false);
        queueOffsetProp = FindProperty("_QueueOffset", properties, false);
        alphaClipProp = FindProperty("_AlphaClip", properties);
        surfaceTypeProp = FindProperty("_Surface", properties);
        blendModeProp = FindProperty("_Blend", properties);
        cullingProp = FindProperty("_Cull", properties);
    }

    public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
    {
        if (materialEditorIn == null)
            throw new ArgumentNullException("materialEditorIn");
        FindProperties(properties);
        materialEditor = materialEditorIn;
        Material material = materialEditor.target as Material;
        if (m_FirstTimeApply)
        {
            OnOpenGUI(material, materialEditorIn);
            m_FirstTimeApply = false;
        }

        ShaderPropertiesGUI(material);
    }

    public virtual void OnOpenGUI(Material material, MaterialEditor materialEditorIn)
    {
        // Foldout states
        m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
        m_SurfaceOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceOptionsFoldout", true);
        m_SurfaceInputsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceInputsFoldout", true);
        m_AdvancedFoldout = new SavedBool($"{m_HeaderStateKey}.AdvancedFoldout", false);

        foreach (var obj in materialEditorIn.targets)
            MaterialChanged((Material) obj);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        if (material == null)
            throw new ArgumentNullException("material");

        EditorGUI.BeginChangeCheck();

        m_SurfaceOptionsFoldout.value =
            EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceOptionsFoldout.value, Styles.surfaceOptions);
        if (m_SurfaceOptionsFoldout.value)
        {
            DrawSurfaceOptions(material);
            EditorGUILayout.Space();
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

        m_SurfaceInputsFoldout.value = EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceInputsFoldout.value, Styles.surfaceInputs);
        if (m_SurfaceInputsFoldout.value)
        {
            DrawBaseProperties();
            EditorGUILayout.Space();
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

        m_AdvancedFoldout.value =
            EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout.value, Styles.advancedLabel);
        if (m_AdvancedFoldout.value)
        {
            DrawAdvancedOptions();
            EditorGUILayout.Space();
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

        if (EditorGUI.EndChangeCheck())
        {
            foreach (var obj in materialEditor.targets)
                MaterialChanged((Material) obj);
        }
    }

    public void DrawSurfaceOptions(Material material)
    {
        DoPopup(Styles.surfaceType, surfaceTypeProp, Enum.GetNames(typeof(SurfaceType)));
        if ((SurfaceType) surfaceTypeProp.floatValue == SurfaceType.Transparent)
            DoPopup(Styles.blendingMode, blendModeProp, Enum.GetNames(typeof(BlendMode)));

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = cullingProp.hasMixedValue;
        var culling = (RenderFace) cullingProp.floatValue;
        culling = (RenderFace) EditorGUILayout.EnumPopup(Styles.cullingText, culling);
        if (EditorGUI.EndChangeCheck())
        {
            materialEditor.RegisterPropertyChangeUndo(Styles.cullingText.text);
            cullingProp.floatValue = (float) culling;
            material.doubleSidedGI = (RenderFace) cullingProp.floatValue != RenderFace.Front;
        }

        EditorGUI.showMixedValue = false;

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = alphaClipProp.hasMixedValue;
        var alphaClipEnabled = EditorGUILayout.Toggle(Styles.alphaClipText, alphaClipProp.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
            alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
        EditorGUI.showMixedValue = false;

        if (alphaClipProp.floatValue == 1)
            materialEditor.ShaderProperty(alphaCutoffProp, Styles.alphaClipThresholdText, 1);

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = receiveShadowsProp.hasMixedValue;
        var receiveShadows = EditorGUILayout.Toggle(Styles.receiveShadowText, receiveShadowsProp.floatValue == 1.0f);
        if (EditorGUI.EndChangeCheck())
            receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
        EditorGUI.showMixedValue = false;
    }

    public void DrawBaseProperties()
    {
        materialEditor.ShaderProperty(baseMapProp, Styles.baseMap);
        materialEditor.ShaderProperty(baseColorProp, Styles.baseColor);
        EditorGUILayout.Space();
        materialEditor.TexturePropertySingleLine(Styles.normalMetalSmoothMap, normalMetalSmoothMapProp);
        if (normalMetalSmoothMapProp.textureValue != null)
        {
            materialEditor.ShaderProperty(normalScaleProp, Styles.normalScale);
        }

        materialEditor.ShaderProperty(metallicProp, Styles.metallic);
        materialEditor.ShaderProperty(smoothnessProp, Styles.smoothness);
        DoPopup(Styles.aoSource, aoSourceProp, Enum.GetNames(typeof(AoSource)));
        if (aoSourceProp.floatValue != 2.0f)
            materialEditor.ShaderProperty(occlusionStrengthProp, Styles.aoScale);
        
        EditorGUILayout.Space();
        materialEditor.ShaderProperty(emissionColorProp, Styles.emissionColor);
        
        materialEditor.TexturePropertySingleLine(Styles.emissionAOMap, emissionAOMapProp);

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = environmentReflectionsProp.hasMixedValue;
        var environmentReflections = EditorGUILayout.Toggle(Styles.environmentReflection, environmentReflectionsProp.floatValue == 1.0f);
        if (EditorGUI.EndChangeCheck())
            environmentReflectionsProp.floatValue = environmentReflections ? 1.0f : 0.0f;
        EditorGUI.showMixedValue = false;
    }

    public void DrawAdvancedOptions()
    {
        materialEditor.EnableInstancingField();
        DrawQueueOffsetField();
    }

    protected void DrawQueueOffsetField()
    {
        if (queueOffsetProp != null)
        {
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = queueOffsetProp.hasMixedValue;
            var queue = EditorGUILayout.IntSlider(Styles.queueSlider, (int) queueOffsetProp.floatValue, -50, 50);
            if (EditorGUI.EndChangeCheck())
                queueOffsetProp.floatValue = queue;
            EditorGUI.showMixedValue = false;
        }
    }

    public void MaterialChanged(Material material)
    {
        if (material == null)
            throw new ArgumentNullException("material");

        SetMaterialKeywords(material);
    }

    public static void SetMaterialKeywords(Material material)
    {
        // Clear all keywords for fresh start
        material.shaderKeywords = null;

        SetupMaterialBlendMode(material);

        // Receive Shadows
        CoreUtils.SetKeyword(material, "_RECEIVE_SHADOWS_OFF", material.GetFloat("_ReceiveShadows") == 0.0f);

        // Emission
        MaterialEditor.FixupEmissiveFlag(material);

        CoreUtils.SetKeyword(material, "_ENVIRONMENTREFLECTIONS_OFF", material.GetFloat("_EnvironmentReflections") == 0.0f);
        CoreUtils.SetKeyword(material, "_NORMAL_METAL_SMOOTH_MAP", material.GetTexture("_NormalMetalSmoothMap"));
        CoreUtils.SetKeyword(material, "_EMISSION_AO_MAP", material.GetTexture("_EmissionAOMap"));
        CoreUtils.SetKeyword(material, "_AO_ALBEDO_CHANGE_A", material.GetFloat("_AoSource") == 0.0f);
        CoreUtils.SetKeyword(material, "_AO_EMISSION_CHANGE_A", material.GetFloat("_AoSource")== 1.0f);
    }

    public static void SetupMaterialBlendMode(Material material)
    {
        bool alphaClip = material.GetFloat("_AlphaClip") >= 0.5;
        CoreUtils.SetKeyword(material, "_ALPHATEST_ON", alphaClip);

        SurfaceType surfaceType = (SurfaceType) material.GetFloat("_Surface");
        if (surfaceType == SurfaceType.Opaque)
        {
            if (alphaClip)
            {
                material.renderQueue = (int) RenderQueue.AlphaTest;
                material.SetOverrideTag("RenderType", "TransparentCutout");
            }
            else
            {
                material.renderQueue = (int) RenderQueue.Geometry;
                material.SetOverrideTag("RenderType", "Opaque");
            }

            material.renderQueue += (int) material.GetFloat("_QueueOffset");
            material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
            material.SetInt("_ZWrite", 1);
            material.SetShaderPassEnabled("ShadowCaster", true);
        }
        else
        {
            BlendMode blendMode = (BlendMode) material.GetFloat("_Blend");

            // Specific Transparent Mode Settings
            switch (blendMode)
            {
                case BlendMode.Alpha:
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    break;
                case BlendMode.Premultiply:
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    break;
                case BlendMode.Additive:
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    break;
                case BlendMode.Multiply:
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                    break;
            }

            // General Transparent Material Settings
            material.SetOverrideTag("RenderType", "Transparent");
            material.SetInt("_ZWrite", 0);
            material.renderQueue = (int) RenderQueue.Transparent;
            material.SetShaderPassEnabled("ShadowCaster", false);
        }
    }

    public void DoPopup(GUIContent label, MaterialProperty property, string[] options)
    {
        DoPopup(label, property, options, materialEditor);
    }

    public static void DoPopup(GUIContent label, MaterialProperty property, string[] options,
        MaterialEditor materialEditor)
    {
        if (property == null)
            throw new ArgumentNullException("property");

        EditorGUI.showMixedValue = property.hasMixedValue;

        var mode = property.floatValue;
        EditorGUI.BeginChangeCheck();
        mode = EditorGUILayout.Popup(label, (int) mode, options);
        if (EditorGUI.EndChangeCheck())
        {
            materialEditor.RegisterPropertyChangeUndo(label.text);
            property.floatValue = mode;
        }

        EditorGUI.showMixedValue = false;
    }
}