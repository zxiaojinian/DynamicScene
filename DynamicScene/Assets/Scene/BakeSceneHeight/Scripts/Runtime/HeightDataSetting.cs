using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class HeightDataSetting : MonoBehaviour
{
    public HeightData heightData;
    public Texture2D NoiseTex;
    public Vector2 NoiseScale = Vector2.one;

    void OnEnable()
    {
        if (heightData == null) return;
        Shader.SetGlobalVector("_Offset", heightData.Offset);
        Shader.SetGlobalVector("_Size", heightData.Size);
        Shader.SetGlobalTexture("_SceneHeightTex", heightData.HeightMap);
        Shader.SetGlobalTexture("_EdgeNoiseTex", NoiseTex);
        Shader.SetGlobalVector("_EdgeNoiseTexScale", NoiseScale);
    }
}
