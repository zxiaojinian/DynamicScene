#ifndef CUSTOMLIGHTING_INCLUDED
#define CUSTOMLIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Scene/StylizedScene/Weather/Rain/Shader/RianInclude.hlsl"

struct TempBRDFData
{
    half reflectivity;
    half oneMinusReflectivity;
    half3 brdfDiffuse;
    half3 brdfSpecular;
};

inline void InitializeTempBRDFData(half3 albedo, half metallic, half3 specular, out TempBRDFData tempBRDFData)
{
#ifdef _SPECULAR_SETUP
    half reflectivity = ReflectivitySpecular(specular);
    half oneMinusReflectivity = 1.0 - reflectivity;
    half3 brdfDiffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
    half3 brdfSpecular = specular;
#else
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;
    half3 brdfDiffuse = albedo * oneMinusReflectivity;
    half3 brdfSpecular = lerp(kDieletricSpec.rgb, albedo, metallic);
#endif

    tempBRDFData.reflectivity = reflectivity;
    tempBRDFData.oneMinusReflectivity = oneMinusReflectivity;
    tempBRDFData.brdfDiffuse = brdfDiffuse;
    tempBRDFData.brdfSpecular = brdfSpecular;
}

half4 FragmentCustomPBR(InputData inputData, SurfaceData surfaceData, WetData wetdata)
{
#ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif

    BRDFData brdfData;
    TempBRDFData tempBRDFData;
    InitializeTempBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, tempBRDFData);
    GroundWet(tempBRDFData.brdfDiffuse, tempBRDFData.brdfSpecular, surfaceData.smoothness, inputData.normalWS, wetdata); //wet
    InitializeBRDFDataDirect(tempBRDFData.brdfDiffuse, tempBRDFData.brdfSpecular, tempBRDFData.reflectivity, tempBRDFData.oneMinusReflectivity, surfaceData.smoothness, surfaceData.alpha, brdfData);

    BRDFData brdfDataClearCoat = (BRDFData)0;
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    // base brdfData is modified here, rely on the compiler to eliminate dead computation by InitializeBRDFData()
    InitializeBRDFDataClearCoat(surfaceData.clearCoatMask, surfaceData.clearCoatSmoothness, brdfData, brdfDataClearCoat);
#endif

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 color = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                     inputData.bakedGI, surfaceData.occlusion,
                                     inputData.normalWS, inputData.viewDirectionWS);
    color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                     mainLight,
                                     inputData.normalWS, inputData.viewDirectionWS,
                                     surfaceData.clearCoatMask, specularHighlightsOff);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        #if defined(_SCREEN_SPACE_OCCLUSION)
            light.color *= aoFactor.directAmbientOcclusion;
        #endif
        color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                         light,
                                         inputData.normalWS, inputData.viewDirectionWS,
                                         surfaceData.clearCoatMask, specularHighlightsOff);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

half4 FragmentCustomPBR(InputData inputData, WetData wetdata, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha)
{
    SurfaceData s;
    s.albedo              = albedo;
    s.metallic            = metallic;
    s.specular            = specular;
    s.smoothness          = smoothness;
    s.occlusion           = occlusion;
    s.emission            = emission;
    s.alpha               = alpha;
    s.clearCoatMask       = 0.0;
    s.clearCoatSmoothness = 1.0;
    return FragmentCustomPBR(inputData, s, wetdata);
}
#endif