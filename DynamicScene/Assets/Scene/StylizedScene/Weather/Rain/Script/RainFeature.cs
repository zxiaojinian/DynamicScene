using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RainFeature : ScriptableRendererFeature
{
    class RainRipplePass : ScriptableRenderPass
    {
        //https://catlikecoding.com/unity/tutorials/scriptable-render-pipeline/post-processing/#3
        static Mesh mesh;
        static Mesh fullScreenMesh
        {
            get
            {
                if (mesh != null) return mesh;
                mesh = new Mesh
                {
                    name = "Full-Screen Triangle",
                    vertices = new Vector3[] {
                        new Vector3(-1f, -1f, 0f),
                        new Vector3(-1f, 3f, 0f),
                        new Vector3(3f, -1f, 0f)
                    },
                    triangles = new int[] { 0, 1, 2 },
                };
                mesh.UploadMeshData(true);
                return mesh;
            }
        }

        const string CMDSTR = "RainRipple";
        RenderTargetHandle rainRippleNormal;

        public RainRipplePass()
        {
            rainRippleNormal.Init("_RainRippleNormal");
        }

        RenderTextureDescriptor GetDescriptor(int width, int height)
        {
            RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height);
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.colorFormat = RenderTextureFormat.ARGB32;
            desc.useMipMap = true;
            desc.autoGenerateMips = true;
            desc.sRGB = false;
            return desc;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor desc = GetDescriptor(512, 512);
            cmd.GetTemporaryRT(rainRippleNormal.id, desc, FilterMode.Bilinear);
            ConfigureClear(ClearFlag.All, new Color(0.0f, 0.0f, 1.0f));
            ConfigureTarget(rainRippleNormal.id);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                //cmd.DrawMesh(fullScreenMesh, Matrix4x4.identity, RainCtrl.Instance.RainMaterial, 0, 0);
                cmd.DrawProcedural(Matrix4x4.identity, RainCtrl.Instance.RainMaterial, 0, MeshTopology.Triangles, 3); //https://catlikecoding.com/unity/tutorials/custom-srp/post-processing/#1.6
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainMaskPass is error" + e);
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(rainRippleNormal.id);
        }
    }

    class RainSplashPass : ScriptableRenderPass
    {
        const string CMDSTR = "Rain Splash";
        Mesh rainSplashMesh;
        MaterialPropertyBlock mMPB;
        int id_SplashInfo_1;
        int id_SplashInfo_2;

        public RainSplashPass()
        {
            mMPB = new MaterialPropertyBlock();
            id_SplashInfo_1 = Shader.PropertyToID("_SplashInfo_1");
            id_SplashInfo_2 = Shader.PropertyToID("_SplashInfo_2");
        }

        public void Setup(Mesh rainSplashMeshPra)
        {
            rainSplashMesh = rainSplashMeshPra;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                mMPB.Clear();
                mMPB.SetVectorArray(id_SplashInfo_1, RainCtrl.Instance.SplashInfo_1);
                mMPB.SetFloatArray(id_SplashInfo_2, RainCtrl.Instance.SplashInfo_2);
                cmd.DrawMeshInstanced(rainSplashMesh, 0, RainCtrl.Instance.RainMaterial, 1, RainCtrl.Instance.SplashMatrix, RainCtrl.Instance.SplashCountMax, mMPB);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainSplashPass is error" + e);
            }
        }
    }

    class RainMaskPass : ScriptableRenderPass
    {
        const string CMDSTR = "RainMask";
        RenderTargetHandle rainMaskTexture;
        Mesh postProcessingMesh;

        public RainMaskPass()
        {
            rainMaskTexture.Init("_RainMaskTexture");
        }

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }

        RenderTextureDescriptor GetDescriptor(int width, int height)
        {
            RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height);
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.colorFormat = RenderTextureFormat.ARGB32;
            desc.useMipMap = false;
            desc.sRGB = false;
            return desc;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            RenderTextureDescriptor desc = GetDescriptor((int)(cameraTextureDescriptor.width * 0.25f), (int)(cameraTextureDescriptor.height * 0.25f));
            cmd.GetTemporaryRT(rainMaskTexture.id, desc, FilterMode.Bilinear);
            ConfigureClear(ClearFlag.All, Color.clear);
            ConfigureTarget(rainMaskTexture.id);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.identity, Vector3.one);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 2);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainMaskPass is error" + e);
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(rainMaskTexture.id);
        }
    }

    class RainMergePass : ScriptableRenderPass
    {
        const string CMDSTR = "RainMerge";
        Mesh postProcessingMesh;

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.identity, Vector3.one);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 3);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch(System.Exception e)
            {
                Debug.LogError("RainMergePass is error" + e);
            }
        }
    }

    public Mesh RainPostProcessingMesh;
    public Mesh RainSplashMesh;

    RainRipplePass rainRipplePass;
    RainSplashPass rainSplashPass;
    RainMaskPass rainMaskPass;
    RainMergePass mRainMergePass;

    public override void Create()
    {
        if (RainPostProcessingMesh == null) Debug.LogError("RainPostProcessingMesh Is Null!");
        if (RainSplashMesh == null) Debug.LogError("RainSplashMesh Is NUll!");

        rainRipplePass = new RainRipplePass()
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques
        };

        rainSplashPass = new RainSplashPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques
        };

        rainMaskPass = new RainMaskPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
        mRainMergePass = new RainMergePass
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (RainCtrl.Instance == null || !RainCtrl.Instance.enabled || !RainCtrl.Instance.EnableRaindrop || RainCtrl.Instance.RainMaterial == null) return;

        bool mainGameCam = renderingData.cameraData.camera.cameraType == CameraType.Game && renderingData.cameraData.camera == Camera.main;
        if (mainGameCam || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            renderer.EnqueuePass(rainRipplePass);

            if (RainCtrl.Instance.EnableRainSplash && RainCtrl.Instance.SplashInfo_1 != null && RainSplashMesh != null)
            {
                rainSplashPass.Setup(RainSplashMesh);
                renderer.EnqueuePass(rainSplashPass);
            }

            if (RainPostProcessingMesh != null)
            {
                rainMaskPass.Setup(RainPostProcessingMesh);
                renderer.EnqueuePass(rainMaskPass);
                mRainMergePass.Setup(RainPostProcessingMesh);
                renderer.EnqueuePass(mRainMergePass);
            }
        }
    }
}
