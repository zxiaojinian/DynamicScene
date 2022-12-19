#ifndef STYLIZEDSCENEBASE_FORWARDPASS_INCLUDED
#define STYLIZEDSCENEBASE_FORWARDPASS_INCLUDED

#include "CustomLighting.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    half4 vColor        : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
    float3 positionWS               : TEXCOORD2;
    float3 normalWS                 : TEXCOORD3;

//#if defined(_NORMALMAP)
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
//#endif

    float3 viewDirWS                : TEXCOORD5;
    half3 vertexLight				: TEXCOORD6;	//vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

#if defined(_PARALLAXMAP)
    float3 viewDirTS                : TEXCOORD8;
#endif

    half4 vColor                    : TEXCOORD9;
    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, float3 bitangent, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = input.positionWS;
    half3 viewDirWS = SafeNormalize(input.viewDirWS);
#if defined(_NORMALMAP)
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = normalize(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.vertexLighting = input.vertexLight;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

//有重复计算，可以精简
Varyings Vertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.normalWS = normalInput.normalWS;
    output.viewDirWS = viewDirWS;

//#if defined(_NORMALMAP) || defined(_PARALLAXMAP)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
//#endif
//#if defined(_NORMALMAP)
    output.tangentWS = tangentWS;
//#endif

#if defined(_PARALLAXMAP)
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.vertexLight = vertexLight;
    output.positionWS = vertexInput.positionWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.vColor = input.vColor;
    output.positionCS = vertexInput.positionCS;

    return output;
}

//normalTS, normalWS,tangentWS, bitangent在ps都没有归一化？
half4 Fragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    //return input.vColor;
    half4 height  = SampleHeight(input.uv);
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    
    WetData wetData;
    half3x3 tTOw = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    InitializeWetData(height.g, input.vColor, input.positionWS, tTOw, wetData);

#if defined(_PARALLAXMAP)
    half3 viewDirTS = input.viewDirTS;
    ApplyPerPixelDisplacement(viewDirTS, height.g, input.uv);
#endif

    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, bitangent, inputData);
    
    half4 color = FragmentCustomPBR(inputData, surfaceData, wetData);
    return color;
}
#endif