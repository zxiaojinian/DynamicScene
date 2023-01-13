using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SceneHeightRender : ScriptableRenderer
{
    RenderTargetHandle m_DepthTexture;
    RenderTargetHandle m_NormalsTexture;

    public SceneHeightRender(SceneHeightRenderData data) : base(data)
    {
        m_DepthTexture.Init("_CameraDepthTexture");
        m_NormalsTexture.Init("_CameraNormalsTexture");
    }

    public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        Camera camera = renderingData.cameraData.camera;
        ref CameraData cameraData = ref renderingData.cameraData;
        RenderTextureDescriptor cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

        ConfigureCameraTarget(BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget);
        AddRenderPasses(ref renderingData);
    }
}
