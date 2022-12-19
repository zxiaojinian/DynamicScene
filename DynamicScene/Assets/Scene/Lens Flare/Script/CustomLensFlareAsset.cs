using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomLensFlare
{
    [Serializable]
    public class FlareData
    {
        public bool AutoRotation = true;
        [Range(0f, 360f)]
        public float Rotation = 0f;
        [Min(0)]
        public int AtlasIndex = 0;
        [Range(0f, 2f)]
        public float FlareScale = 0.5f;
        [Range(-1f, 2f)]
        public float FlareOffset = 0.2f;
        [Range(0f, 1f)]
        public float OcclusionScale = 1f;
        [ColorUsage(true, true)]
        public Color FlareColor = Color.white;
    }

    public enum FlareTexLayout
    {
        _1,
        _2x2,
        _3x3,
        _4x4,
        _1L4S,
        _1L2M8S
    }

    [CreateAssetMenu(fileName = "CustomLensFlareAsset", menuName = "Code Repository/Scene/CustomLensFlareAsset")]
    public class CustomLensFlareAsset : ScriptableObject
    {
        public Texture2D FlareAtlasTexture;
        public FlareTexLayout FlareTexLayout = FlareTexLayout._2x2;
        public List<FlareData> FlareDatas = new List<FlareData>();
    }
}
