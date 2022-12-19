using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomLensFlare
{
    [ExecuteInEditMode]
    public class CustomLensFlare : MonoBehaviour
    {
        public bool IsDirectional = false;
        public float OcclusionRadius = 1.0f;
        public CustomLensFlareAsset FlareAsset;
        public Material UsedMaterial;

        Mesh mMesh;
        public Mesh UsedMesh
        {
            get { return mMesh; }
        }

        private readonly List<Rect>[] mFlareLayoutUV = new[]
        {
            new List<Rect>()    //1
            {
                new Rect(0f, 0f, 1f, 1f),
            },
            new List<Rect>()    //2x2
            {
                new Rect(0, 0.5f, 0.5f, 0.5f),
                new Rect(0.5f, 0.5f, 0.5f, 0.5f),
                new Rect(0, 0, 0.5f, 0.5f),
                new Rect(0.5f, 0, 0.5f, 0.5f)
            },
            new List<Rect>()    //3x3
            {
                new Rect(0, 2f/3f, 1f/3f, 1f/3f),
                new Rect(1f/3f, 2f/3f, 1f/3f, 1f/3f),
                new Rect(2f/3f, 2f/3f, 1f/3f, 1f/3f),
                new Rect(0, 1f/3f, 1f/3f, 1f/3f),
                new Rect(1f/3f, 1f/3f, 1f/3f, 1f/3f),
                new Rect(2f/3f, 1f/3f, 1f/3f, 1f/3f),
                new Rect(0, 0f, 1f/3f, 1f/3f),
                new Rect(1f/3f, 0f, 1f/3f, 1f/3f),
                new Rect(2f/3f, 0f, 1f/3f, 1f/3f),
            },
            new List<Rect>()    //4x4
            {
                new Rect(0, 0.75f, 0.25f,  0.25f),
                new Rect(0.25f, 0.75f, 0.25f,  0.25f),
                new Rect(0.5f, 0.75f, 0.25f,  0.25f),
                new Rect(0.75f, 0.75f, 0.25f,  0.25f),
                new Rect(0, 0.5f, 0.25f,  0.25f),
                new Rect(0.25f, 0.5f, 0.25f,  0.25f),
                new Rect(0.5f, 0.5f, 0.25f,  0.25f),
                new Rect(0.75f, 0.5f, 0.25f,  0.25f),
                new Rect(0, 0.25f, 0.25f,  0.25f),
                new Rect(0.25f, 0.25f, 0.25f,  0.25f),
                new Rect(0.5f, 0.25f, 0.25f,  0.25f),
                new Rect(0.75f, 0.25f, 0.25f,  0.25f),
                new Rect(0, 0, 0.25f,  0.25f),
                new Rect(0.25f, 0, 0.25f,  0.25f),
                new Rect(0.5f, 0, 0.25f,  0.25f),
                new Rect(0.75f, 0, 0.25f,  0.25f)
            },
            new List<Rect>() //1L4S
            {
                new Rect(0, 0.5f, 1,  0.5f),
                new Rect(0, 0.25f, 0.5f,  0.25f),
                new Rect(0.5f, 0.25f, 0.5f,  0.25f),
                new Rect(0, 0, 0.5f,  0.25f),
                new Rect(0.5f, 0, 0.5f,  0.25f)
            },
            new List<Rect>() //1L2M8S
            {
                new Rect(0, 0.5f, 1,  0.5f),
                new Rect(0, 0.25f, 0.5f,  0.25f),
                new Rect(0.5f, 0.375f, 0.25f,  0.125f),
                new Rect(0.75f, 0.375f, 0.25f,  0.125f),
                new Rect(0.5f, 0.25f, 0.25f,  0.125f),
                new Rect(0.75f, 0.25f, 0.25f,  0.125f),
                new Rect(0, 0f, 0.5f,  0.25f),
                new Rect(0.5f, 0.125f, 0.25f,  0.125f),
                new Rect(0.75f, 0.125f, 0.25f,  0.125f),
                new Rect(0.5f, 0f, 0.25f,  0.125f),
                new Rect(0.75f, 0f, 0.25f,  0.125f)
            }
        };

        private void Awake()
        {
            UpdateGeometry();
        }

        private void OnEnable()
        {
            CustomLensFlareMgr.Instance.AddCustomLensFlare(this);
        }

        private void OnDisable()
        {
            CustomLensFlareMgr.Instance.RemoveCustomLensFlare(this);
        }

#if UNITY_EDITOR
        void Update()
        {
            UpdateGeometry();
        }
#endif

        private void OnDestroy()
        {
            if(mMesh != null)
            {
#if UNITY_EDITOR
                DestroyImmediate(mMesh);
#else
                Destroy(mMesh);
#endif
            }
        }

        void UpdateGeometry()
        {
            if (FlareAsset == null || FlareAsset.FlareDatas.Count <= 0) return;
            if (mMesh == null)
            {
                mMesh = new Mesh();
                mMesh.name = "LensFlare (" + gameObject.name + ")";
            }
            Mesh m = mMesh;
            m.Clear();

            List<Vector3> vertices = new List<Vector3>();
            List<Vector2> uvs = new List<Vector2>();
            List<int> tris = new List<int>();
            List<Color> vertColors = new List<Color>();

            for (int i = 0; i < FlareAsset.FlareDatas.Count; i++)
            {
                FlareData flareData = FlareAsset.FlareDatas[i];
                int index = Mathf.Clamp(flareData.AtlasIndex, 0, mFlareLayoutUV[(int)FlareAsset.FlareTexLayout].Count - 1);
                Rect rect = mFlareLayoutUV[(int)FlareAsset.FlareTexLayout][index];

                float w = FlareAsset.FlareAtlasTexture.width * rect.width;
                float h = FlareAsset.FlareAtlasTexture.height * rect.height;
                float ratio;
                Vector2 halfSize;
                if (w > h)
                {
                    ratio = w / 2;
                    halfSize = new Vector2(flareData.FlareScale * 1, flareData.FlareScale * FlareAsset.FlareAtlasTexture.height * rect.height / 2 / ratio);
                }
                else
                {
                    ratio = h / 2;
                    halfSize = new Vector2(flareData.FlareScale * FlareAsset.FlareAtlasTexture.width * rect.width / 2 / ratio, flareData.FlareScale * 1);
                }

                vertices.Add(new Vector3(-halfSize.x, -halfSize.y, 0));
                vertices.Add(new Vector3(halfSize.x, -halfSize.y, 0));
                vertices.Add(new Vector3(halfSize.x, halfSize.y, 0));
                vertices.Add(new Vector3(-halfSize.x, halfSize.y, 0));

                if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLCore || SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES2 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES3)
                {
                    uvs.Add(rect.position);
                    uvs.Add(rect.position + new Vector2(rect.width, 0));
                    uvs.Add(rect.position + rect.size);
                    uvs.Add(rect.position + new Vector2(0, rect.height));
                }
                else
                {
                    uvs.Add(rect.position + new Vector2(0, rect.height));
                    uvs.Add(rect.position + rect.size);
                    uvs.Add(rect.position + new Vector2(rect.width, 0));
                    uvs.Add(rect.position);
                }

                vertColors.Add(flareData.FlareColor);
                vertColors.Add(flareData.FlareColor);
                vertColors.Add(flareData.FlareColor);
                vertColors.Add(flareData.FlareColor);

                tris.Add(i * 4);
                tris.Add(i * 4 + 1);
                tris.Add(i * 4 + 2);
                tris.Add(i * 4 + 2);
                tris.Add(i * 4 + 3);
                tris.Add(i * 4);
            }

            m.SetVertices(vertices);
            m.SetTriangles(tris, 0);
            m.SetColors(vertColors);
            m.SetUVs(0, uvs);
            m.SetUVs(1, GetLensFlareData0());
            m.SetUVs(2, GetLensFlareData1());

        }

        List<Vector2> GetLensFlareData0()
        {
            List<Vector2> lfData = new List<Vector2>();
            for (int i = 0; i < FlareAsset.FlareDatas.Count; i++)
            {
                FlareData flareData = FlareAsset.FlareDatas[i];
                Vector2 data = new Vector2(flareData.FlareOffset, flareData.AutoRotation ? -1 : Mathf.Deg2Rad * flareData.Rotation);
                lfData.Add(data);
                lfData.Add(data);
                lfData.Add(data);
                lfData.Add(data);
            }
            return lfData;
        }

        List<Vector2> GetLensFlareData1()
        {
            List<Vector2> lfData = new List<Vector2>();
            for (int i = 0; i < FlareAsset.FlareDatas.Count; i++)
            {
                FlareData flareData = FlareAsset.FlareDatas[i];
                Vector2 data = new Vector2(OcclusionRadius, flareData.OcclusionScale);
                lfData.Add(data);
                lfData.Add(data);
                lfData.Add(data);
                lfData.Add(data);
            }
            return lfData;
        }


        void OnDrawGizmos()
        {
            if(!IsDirectional)
            {
                Gizmos.color = new Color(1, 0, 0, 0.3f);
                Gizmos.DrawSphere(transform.position, OcclusionRadius);
            }
        }
    }
}