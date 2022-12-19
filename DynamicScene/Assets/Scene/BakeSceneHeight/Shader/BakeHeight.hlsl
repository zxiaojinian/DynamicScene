#ifndef BAKE_HEIGHT_INCLUDED
#define BAKE_HEIGHT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float3 _Offset;
float3 _Size;
float2 _EdgeNoiseTexScale;

TEXTURE2D(_SceneHeightTex);
SAMPLER(sampler_SceneHeightTex);
#define SCENEHEIGHT_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SCENEHEIGHT_SAMPLER);

TEXTURE2D(_EdgeNoiseTex);
SAMPLER(sampler_EdgeNoiseTex);

//value(0~1)
float4 PackFloatToColor(float value)
{
    uint a = (uint)(65535.0 * value);
    return float4((a >> 0) & 0xFF, (a >> 8) & 0xFF, 0, 0) / 255.0;
}

float UnpackColorToFloat(float4 value)
{
    return (value.r + value.g * 256.0) / 257.0; // (255.0 * value.r + 255.0 * 256.0 * value.g) / 65535.0
}

float4 PackHeightmapRG(float3 posW)
{
    float height = (posW.y - _Offset.y) / _Size.y;//0-1
    return PackFloatToColor(height);
}

float4 PackHeightmapR(float3 posW)
{
    float height = (posW.y - _Offset.y) / _Size.y;//0-1
    return height;
}

float UnpackHeightmapRG(float3 posW)
{
    float2 uv = (posW.xz - _Offset.xz) / _Size.xz;
    float4 height = SAMPLE_TEXTURE2D_LOD(_SceneHeightTex, sampler_SceneHeightTex, uv, 0);
    float unpackHeight = UnpackColorToFloat(height);
    return unpackHeight * _Size.y + _Offset.y;
}

float UnpackHeightmapR(float3 posW)
{
    float2 uv = (posW.xz - _Offset.xz) / _Size.xz;
    float unpackHeight = SAMPLE_TEXTURE2D_LOD(_SceneHeightTex, sampler_SceneHeightTex, uv, 0).r;
    return unpackHeight * _Size.y + _Offset.y;
}

float UnpackHeightmapPlusNoiseRG(float3 posW)
{
    float2 uv = (posW.xz - _Offset.xz) / _Size.xz;
    float noise = SAMPLE_TEXTURE2D(_EdgeNoiseTex, sampler_EdgeNoiseTex, posW.xz * _EdgeNoiseTexScale).r;
    noise = (noise * 2.0 - 1.0) * 0.002;
    uv += noise;
    float4 height = SAMPLE_TEXTURE2D_LOD(_SceneHeightTex, sampler_SceneHeightTex, uv, 0);
    float unpackHeight = UnpackColorToFloat(height);
    return unpackHeight * _Size.y + _Offset.y;
}

float HeightTest(float3 posW)
{
    posW.y += 1.0;
    float3 uv = (posW.xzy - _Offset.xzy) / _Size.xzy;
    half occlusion = SAMPLE_TEXTURE2D_SHADOW(_SceneHeightTex, SCENEHEIGHT_SAMPLER, uv);
    return occlusion;
}

float HeightTestPlusNoise(float3 posW)
{
    float noise = SAMPLE_TEXTURE2D(_EdgeNoiseTex, sampler_EdgeNoiseTex, posW.xz * _EdgeNoiseTexScale).r;
    noise = (noise * 2.0 - 1.0) * 0.002;
    posW.y += 1.0;
    float3 uv = (posW.xzy - _Offset.xzy) / _Size.xzy;
    uv.xy += noise;
    half occlusion = SAMPLE_TEXTURE2D_SHADOW(_SceneHeightTex, SCENEHEIGHT_SAMPLER, uv);
    return occlusion;
}
#endif
