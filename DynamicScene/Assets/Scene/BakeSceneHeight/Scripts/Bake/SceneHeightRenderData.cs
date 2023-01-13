using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class SceneHeightRenderData : ScriptableRendererData
{

#if UNITY_EDITOR
    internal class CreateSceneHeightRenderAsset : EndNameEditAction
    {
        public override void Action(int instanceId, string pathName, string resourceFile)
        {
            var instance = CreateInstance<SceneHeightRenderData>();
            AssetDatabase.CreateAsset(instance, pathName);
            Selection.activeObject = instance;
        }
    }

    [MenuItem("Assets/Create/Code Repository/Scene/SceneHeightRenderData")]
    static void CreateForwardRendererData()
    {
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateSceneHeightRenderAsset>(), "SceneHeightRender.asset", null, null);
    }
#endif

    [SerializeField] LayerMask m_OpaqueLayerMask = -1;

    /// <summary>
    /// Use this to configure how to filter opaque objects.
    /// </summary>
    public LayerMask opaqueLayerMask
    {
        get => m_OpaqueLayerMask;
        set
        {
            SetDirty();
            m_OpaqueLayerMask = value;
        }
    }

    protected override ScriptableRenderer Create()
    {
        return new SceneHeightRender(this);
    }
}
