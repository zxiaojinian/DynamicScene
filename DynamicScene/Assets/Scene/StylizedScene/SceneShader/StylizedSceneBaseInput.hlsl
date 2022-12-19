#ifndef STYLIZEDSCENEBASE_INPUT_INCLUDED
#define STYLIZEDSCENEBASE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half _Cutoff;
half _Metallic;
half _Smoothness;
half _BumpScale;
half _OcclusionStrength;
half _Parallax;
half4 _EmissionColor;
CBUFFER_END

// SurfaceInput.hlsl∂®“Â¡ÀBaseMap, BumpMap and EmissionMap)
TEXTURE2D(_MetallicGlossMap); 	SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_OcclusionMap); 			SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);


//Parallax

half4 SampleHeight(float2 uv)
{
#if defined(_PARALLAXMAP)
    half4 h = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, uv);
    return h;
#else
    return 1;
#endif
}

void ApplyPerPixelDisplacement(half3 viewDirTS, half h, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    float2 offset = ParallaxOffset1Step(h, _Parallax, viewDirTS);
    uv += offset;
#endif
}


half4 SampleMetallicGloss(float2 uv)
{
    half4 metallicGloss;

#ifdef _METALLICGLOSSMAP
    metallicGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
    metallicGloss.a *= _Smoothness;
#else
    metallicGloss.rgb = _Metallic.rrr;
    metallicGloss.a = _Smoothness;
#endif

    return metallicGloss;
}


half SampleOcclusion(float2 uv)
{
#ifdef _OCCLUSIONMAP
	half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
	return LerpWhiteTo(occ, _OcclusionStrength); //lerp(1, occ, _OcclusionStrength)
#else
    return 1.0;
#endif
}

//surface data
inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;
#if defined(_ALPHATEST_ON)
    clip(outSurfaceData.alpha - _Cutoff);
#endif

    half4 metallicGloss = SampleMetallicGloss(uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    outSurfaceData.metallic = metallicGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

    outSurfaceData.smoothness = metallicGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

    outSurfaceData.clearCoatMask       = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
}

#endif