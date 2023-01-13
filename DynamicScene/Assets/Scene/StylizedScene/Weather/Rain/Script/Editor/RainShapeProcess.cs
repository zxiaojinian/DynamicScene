using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class RainShapeProcess : EditorWindow
{
    [MenuItem("Tools/RainShapeProcess")]
    static void Open()
    {
        RainShapeProcess window = (RainShapeProcess)GetWindow(typeof(RainShapeProcess));
    }

    Texture2D rainShapeTex;
    Texture2D rainShapeTexBlur;

    private void OnGUI()
    {
        EditorGUILayout.BeginVertical();
        rainShapeTex = EditorGUILayout.ObjectField("RainShapeTex", rainShapeTex, typeof(Texture2D), true) as Texture2D;
        rainShapeTexBlur = EditorGUILayout.ObjectField("RainShapeTexBlur", rainShapeTexBlur, typeof(Texture2D), true) as Texture2D;

        if (rainShapeTex != null && rainShapeTexBlur)
        {
            if (rainShapeTex.width != rainShapeTexBlur.width || rainShapeTex.height != rainShapeTexBlur.height) return;
            Rect botton = EditorGUILayout.BeginHorizontal("Button");
            if (GUI.Button(botton, GUIContent.none))
            {
                int col = rainShapeTex.width;
                int row = rainShapeTex.height;
                var colors = rainShapeTexBlur.GetPixels();
                var newColors = rainShapeTex.GetPixels();
                for (int i = 0; i < newColors.Length; i++)
                {
                    newColors[i].g = 0f;
                    newColors[i].b = 0f;
                    newColors[i].a = 0f;
                }
                List<List<int>> rains = BFS(colors, col, row);//通过模糊外扩增大各个雨滴大小，因为遮挡处理是降分辨率的全屏处理，增大雨滴大小以保证升采样时能完全覆盖未增大的初始雨滴。
                foreach (var rain in rains)
                {
                    float offset = Random.Range(0f, 10f) / 10f;
                    float intensity = Random.Range(0f, 1f);
                    foreach (var index in rain)
                    {
                        newColors[index].g = offset;
                        newColors[index].b = intensity;
                    }
                }
                Texture2D output = new Texture2D(col, row, TextureFormat.RGB24, false, false);
                output.SetPixels(newColors, 0);
                output.Apply();
                string path = AssetDatabase.GetAssetPath(rainShapeTex);
                int _index = path.LastIndexOf("/");
                path = path.Remove(_index) + "/_" + rainShapeTex.name + ".png";
                File.WriteAllBytes(path, output.EncodeToPNG());
                AssetDatabase.Refresh();
                DestroyImmediate(output);
            }
            GUILayout.Label("Process", new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter });
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndVertical();
    }

    public List<List<int>> BFS(Color[] colors, int nc, int nr)
    {
        List<List<int>> list = new List<List<int>>();
        if (colors == null || colors.Length == 0)
        {
            return list;
        }

        for (int r = 0; r < nr; ++r)
        {
            for (int c = 0; c < nc; ++c)
            {
                int index = r * nc + c;
                if (colors[index].r > 0f)
                {
                    List<int> list2 = new List<int>();
                    list2.Add(index);
                    list.Add(list2);

                    colors[index].r = 0f;
                    Queue<int> neighbors = new Queue<int>();
                    neighbors.Enqueue(index);
                    while (neighbors.Count > 0)
                    {
                        int id = neighbors.Dequeue();
                        int row = id / nc;
                        int col = id % nc;

                        int b = (row - 1) * nc + col;
                        int t = (row + 1) * nc + col;
                        int l = row * nc + col - 1;
                        int right = row * nc + col + 1;
                        if (row - 1 >= 0 && colors[b].r > 0f)
                        {
                            neighbors.Enqueue(b);
                            colors[b].r = 0f;
                            list2.Add(b);
                        }
                        if (row + 1 < nr && colors[t].r > 0f)
                        {
                            neighbors.Enqueue(t);
                            colors[t].r = 0f;
                            list2.Add(t);
                        }
                        if (col - 1 >= 0 && colors[l].r > 0f)
                        {
                            neighbors.Enqueue(l);
                            colors[l].r = 0f;
                            list2.Add(l);
                        }
                        if (col + 1 < nc && colors[right].r > 0f)
                        {
                            neighbors.Enqueue(right);
                            colors[right].r = 0f;
                            list2.Add(right);
                        }
                    }
                }
            }
        }

        return list;
    }
}
