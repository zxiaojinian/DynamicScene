using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace CustomLensFlare
{
    public class CustomLensFlareFeature : ScriptableRendererFeature
    {
        class CustomLensFlarePass : ScriptableRenderPass
        {
            const string CMDSTR = "CustomLensFlare";

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                foreach (var lf in CustomLensFlareMgr.Instance.LensFlares)
                {
                    if(renderingData.cameraData.cameraType == CameraType.SceneView)
                    {
                        DrawLensFlare(lf, cmd);
                    }
                    else
                    {
                        if( ( (1 << lf.gameObject.layer) & renderingData.cameraData.camera.cullingMask) != 0)
                        {
                            DrawLensFlare(lf, cmd);
                        }
                    }
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            void DrawLensFlare(CustomLensFlare lensFlare, CommandBuffer cmd)
            {
                if(lensFlare != null && cmd != null)
                {
                    Matrix4x4 m = Matrix4x4.identity;
                    if(!lensFlare.IsDirectional)
                    {
                        m = lensFlare.transform.localToWorldMatrix;   
                    }
                    if(lensFlare.UsedMesh != null && lensFlare.UsedMaterial != null)
                    {
                        cmd.DrawMesh(lensFlare.UsedMesh, m, lensFlare.UsedMaterial, 0, lensFlare.IsDirectional ? 1 : 0);
                    }
                }
            }
        }

        CustomLensFlarePass mCustomLensFlarePass;

        public override void Create()
        {
            mCustomLensFlarePass = new CustomLensFlarePass();
            mCustomLensFlarePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.cameraType == CameraType.Game || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
            {
                renderer.EnqueuePass(mCustomLensFlarePass);
            }
        }
    }
}
