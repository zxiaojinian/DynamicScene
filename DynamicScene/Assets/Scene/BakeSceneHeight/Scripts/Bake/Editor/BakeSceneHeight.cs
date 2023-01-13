using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.SceneManagement;
using UnityEngine.Rendering.Universal;
public class BakeSceneHeight : EditorWindow
{
    [MenuItem("Tools/BakeSceneHeight")]
    static void Open()
    {
        BakeSceneHeight window = (BakeSceneHeight)GetWindow(typeof(BakeSceneHeight));
    }

    GameObject sceneRoot;
    Vector3 boundMin = Vector3.positiveInfinity;
    Vector3 boundMax = Vector3.negativeInfinity;
    Vector3 center = Vector3.zero;
    Vector3Int size = Vector3Int.one;
    int pixelPerUnit = 10;
    bool fixedResolution = false;
    int width = 1;
    int height = 1;

    GameObject bakeSceneHeightGO;
    BakeSceneHeightGizmos gizmos;
    Camera bakeHeightCam;
    RenderTexture heightTex;
    const string rainSceneDepthRenderStr = "SceneHeightRender";
    SceneHeightRenderData sceneHeightRender;
    int sceneHeightRenderIndex;

    private void OnEnable()
    {
        if (Selection.activeGameObject != null)
        {
            sceneRoot = Selection.activeGameObject;
        }

        if(sceneRoot != null)
        {
            GetSceneBound();
        }
    }
    private void OnGUI()
    {
        EditorGUILayout.BeginVertical();

        GameObject pre = sceneRoot;
        sceneRoot = EditorGUILayout.ObjectField("SceneRoot", sceneRoot, typeof(GameObject), true) as GameObject;
        if(sceneRoot != null)
        {
            if(bakeSceneHeightGO == null)
            {
                bakeSceneHeightGO = new GameObject("BakeSceneHeightGO");
                bakeSceneHeightGO.hideFlags = HideFlags.DontSave;
                gizmos = bakeSceneHeightGO.AddComponent<BakeSceneHeightGizmos>();

                bakeHeightCam = bakeSceneHeightGO.AddComponent<Camera>();
                bakeHeightCam.clearFlags = CameraClearFlags.SolidColor;
                bakeHeightCam.enabled = false;
                bakeHeightCam.transform.rotation = Quaternion.Euler(90.0f, 0.0f, 0.0f);
                bakeHeightCam.orthographic = true;
                bakeHeightCam.backgroundColor = Color.clear;
                sceneHeightRender = PipelineUtilities.GetRenderer<SceneHeightRenderData>(rainSceneDepthRenderStr, nameof(SceneHeightRenderData));
                PipelineUtilities.ValidatePipelineRenderers(sceneHeightRender, ref sceneHeightRenderIndex);
                UniversalAdditionalCameraData destAdditionalData = bakeHeightCam.GetUniversalAdditionalCameraData();
                if (destAdditionalData != null && sceneHeightRenderIndex >= 0)
                {
                    destAdditionalData.SetRenderer(sceneHeightRenderIndex);
                }
            }
            if (pre != sceneRoot)
            {
                GetSceneBound();
            }
            center = EditorGUILayout.Vector3Field("Center", center);
            size = EditorGUILayout.Vector3IntField("Size", size);
            pixelPerUnit = EditorGUILayout.IntField("PixelPerUnit", pixelPerUnit);
            EditorGUILayout.Space(5);
            fixedResolution = GUILayout.Toggle(fixedResolution, "fixedResolution");
            EditorGUILayout.Space(5);
            width = EditorGUILayout.IntField("fixed width", width);
            height = EditorGUILayout.IntField("fixed height", height);

            UpdateCam();
            gizmos.center = center;
            gizmos.size = size;

            EditorGUILayout.Space(20);
            Rect botton = EditorGUILayout.BeginHorizontal("Button");
            if (GUI.Button(botton, GUIContent.none))
            {
                if(bakeHeightCam)
                {
                    int w;
                    int h;
                    if (fixedResolution)
                    {
                        w = width;
                        h = height;
                    }
                    else
                    {
                        w = size.x * pixelPerUnit;
                        h = size.z * pixelPerUnit;
                    }
                    w = Mathf.Max(w, 1);
                    h = Mathf.Max(h, 1);
                    if (heightTex == null || heightTex.width != w || heightTex.height != h)
                    {
                        if (heightTex != null) RenderTexture.ReleaseTemporary(heightTex);
                        //heightTex = RenderTexture.GetTemporary(w, h, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                        heightTex = RenderTexture.GetTemporary(w, h, 24, RenderTextureFormat.R16, RenderTextureReadWrite.Linear);
                        heightTex.name = "heightTex";
                        heightTex.wrapMode = TextureWrapMode.Clamp;
                        heightTex.filterMode = FilterMode.Bilinear;
                    }
                    bakeHeightCam.targetTexture = heightTex;
                    Vector3 sizefloat = new Vector3(size.x, size.y, size.z);
                    Shader.SetGlobalVector("_Offset", center - sizefloat * 0.5f);
                    Shader.SetGlobalVector("_Size", sizefloat);
                    bakeHeightCam.Render();
                    Scene s = SceneManager.GetActiveScene();
                    string path = s.path;
                    int index = path.LastIndexOf("/");
                    path = path.Remove(index + 1) + s.name;
                    SaveAsset(heightTex, path);
                }
            }
            GUILayout.Label("Bake", new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter });
            EditorGUILayout.EndHorizontal();
        }
        else
        {
            boundMin = Vector3.positiveInfinity;
            boundMax = Vector3.negativeInfinity;
            center = Vector3.zero;
            size = Vector3Int.one;
            pixelPerUnit = 10;
            OnDestroy();
        }

        EditorGUILayout.EndVertical();
    }

    void GetSceneBound()
    {
        MeshRenderer[] mrs = sceneRoot.GetComponentsInChildren<MeshRenderer>();

        if (mrs != null)
        {
            foreach (var r in mrs)
            {
                Bounds b = r.bounds;
                Vector3 min = b.min;
                Vector3 max = b.max;
                boundMin = Vector3.Min(boundMin, min);
                boundMax = Vector3.Max(boundMax, max);
            }

            center = boundMin + boundMax;
            center *= 0.5f;
            Vector3 s = boundMax - boundMin;
            size = new Vector3Int(Mathf.CeilToInt(s.x), Mathf.CeilToInt(s.y), Mathf.CeilToInt(s.z));
        }
    }

    void UpdateCam()
    {
        bakeHeightCam.nearClipPlane = 1f;
        bakeHeightCam.farClipPlane = bakeHeightCam.nearClipPlane + size.y;
        float y = center.y - size.y * 0.5f + bakeHeightCam.farClipPlane;
        Vector3 pos = new Vector3(center.x, y, center.z);
        bakeHeightCam.transform.position = pos;
        float w = size.x * 0.5f;
        float h = size.z * 0.5f;
        Matrix4x4 p = Matrix4x4.Ortho(-w, w, -h, h, bakeHeightCam.nearClipPlane, bakeHeightCam.farClipPlane);
        bakeHeightCam.projectionMatrix = p;
    }

    public virtual void SaveAsset(RenderTexture rt, string path)
    {
        //Texture2D output = new Texture2D(rt.width, rt.height, TextureFormat.ARGB32, false, true);
        Texture2D output = new Texture2D(rt.width, rt.height, TextureFormat.R16, false, true);
        output.filterMode = FilterMode.Bilinear;
        output.wrapMode = TextureWrapMode.Clamp;
        RenderTexture.active = rt;
        output.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        output.Apply();
        HeightData heightData = CreateInstance<HeightData>();
        heightData.HeightMap = output;
        heightData.Size = size;
        heightData.Offset = center - new Vector3(size.x * 0.5f, size.y * 0.5f, size.z * 0.5f);
        //AssetDatabase.AddObjectToAsset(heightData.HeightMap, path + "_HeightData.asset");
        string texPath = path + "_HeightMap.asset";
        string dataPath = path + "_HeightData.asset";
        AssetDatabase.DeleteAsset(texPath);
        AssetDatabase.DeleteAsset(dataPath);
        AssetDatabase.CreateAsset(output, texPath);
        AssetDatabase.CreateAsset(heightData, dataPath);
        AssetDatabase.Refresh();
    }


    private void OnDestroy()
    {
        if (bakeSceneHeightGO) DestroyImmediate(bakeSceneHeightGO);
        if(heightTex != null)
        {
            RenderTexture.ReleaseTemporary(heightTex);
            heightTex = null;
        }

        PipelineUtilities.RemoveRendererFromPipeline(sceneHeightRender);
    }
}
