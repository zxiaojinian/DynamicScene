using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderSceneHeightPass : ScriptableRenderPass
{
    FilteringSettings m_FilteringSettings;
    ShaderTagId m_ShaderTagId = new ShaderTagId("DepthOnly");

    public RenderSceneHeightPass(RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask)
    {
        base.profilingSampler = new ProfilingSampler(nameof(RenderSceneHeightPass));
        m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
        renderPassEvent = evt;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        // NOTE: Do NOT mix ProfilingScope with named CommandBuffers i.e. CommandBufferPool.Get("name").
        // Currently there's an issue which results in mismatched markers.
        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, new ProfilingSampler("RenderSceneHeightPass")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
            drawSettings.perObjectData = PerObjectData.None;

            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);

        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
