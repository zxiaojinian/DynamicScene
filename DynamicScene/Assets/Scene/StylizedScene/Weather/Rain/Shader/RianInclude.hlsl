#ifndef RIAN_INCLUDE
#define RIAN_INCLUDE
#include "Assets/Scene/BakeSceneHeight/Shader/BakeHeight.hlsl"

half _WetLevel;
half2 _FloodLevel;
half _RainIntensity;
TEXTURE2D(_RippleTexture); //r距离衰减，sin波参数,gb法线在t,b方向的扰动；a,时间偏移
SAMPLER(sampler_RippleTexture);

TEXTURE2D(_RainRippleNormal);
//SAMPLER(sampler_RainRippleNormal);
SAMPLER(sampler_linear_repeat);

struct WetData
{
    half height;
    half4 mask;//g,puddlemMask;b,occlusion
    float3 posWS;
    half3x3 tTOw;
};

void InitializeWetData(half h, half4 mask, float3 posWS, half3x3 tTOw, out WetData wetData)
{
    wetData.height = h;;
    wetData.mask = mask;
    wetData.posWS = posWS;
    wetData.tTOw = tTOw;
}

//可以优化，提前生成序列帧
half2 SingleRipple(float2 uv, half time, half weight)
{
   half4 ripple = SAMPLE_TEXTURE2D(_RippleTexture, sampler_RippleTexture, uv);
   ripple.gb = ripple.gb * 2 - 1; //0-1>>-1-1
   half dropFrac = frac(ripple.a + time); //0-1循环
   half timeFrac = dropFrac - 1.0 + ripple.r; //0-1循环,sin参数
   half dropFactor = saturate(0.2 + weight * 0.8 - dropFrac); //最低0.2,随时间衰减
   half finalFactor = dropFactor * ripple.r * sin( clamp(timeFrac * 9.0, 0.0f, 3.0) * PI);
   return ripple.gb * finalFactor * 0.35;    
}

//世界空间法线
half3 RainRippleWS(float2 uv)
{
    //可放到cpu上
    half4 timeMul = half4(1, 0.85, 0.93, 1.13); 
    half4 timeAdd = half4(0, 0.f, 0.45, 0.7);
    half4 times = (_Time.y * timeMul + timeAdd) * 1.6;
    times = frac(times);

    half4 weights = _RainIntensity - half4(0, 0.25, 0.5, 0.75);
    weights = saturate(weights * 4);
    half2 ripple1 = SingleRipple(uv + float2( 0.25f,0.0f), times.x, weights.x);
    half2 ripple2 = SingleRipple(uv + float2(-0.55f,0.3f), times.y, weights.y);
    half2 ripple3 = SingleRipple(uv + float2(0.6f, 0.85f), times.z, weights.z);
    half2 ripple4 = SingleRipple(uv + float2(0.5f,-0.75f), times.w, weights.w);

    half3 rippleNormal;
    rippleNormal.xz = ripple1 * weights.x + ripple2 * weights.y + ripple3 * weights.z + ripple4 * weights.w;
    rippleNormal.y = max(1.0e-16, sqrt(1.0 - saturate(dot(rippleNormal.xz, rippleNormal.xz))));
    return rippleNormal;
}

//切线空间法线
half3 RainRippleTS(float2 uv)
{
    //可放到cpu上
    half4 timeMul = half4(1, 0.85, 0.93, 1.13); 
    half4 timeAdd = half4(0, 0.f, 0.45, 0.7);
    half4 times = (_Time.y * timeMul + timeAdd) * 1.6;
    times = frac(times);

    half4 weights = _RainIntensity - half4(0, 0.25, 0.5, 0.75);
    weights = saturate(weights * 4);
    half2 ripple1 = SingleRipple(uv + float2( 0.25f,0.0f), times.x, weights.x);
    half2 ripple2 = SingleRipple(uv + float2(-0.55f,0.3f), times.y, weights.y);
    half2 ripple3 = SingleRipple(uv + float2(0.6f, 0.85f), times.z, weights.z);
    half2 ripple4 = SingleRipple(uv + float2(0.5f,-0.75f), times.w, weights.w);

    half3 rippleNormal;
    rippleNormal.xy = ripple1 * weights.x + ripple2 * weights.y + ripple3 * weights.z + ripple4 * weights.w;
    rippleNormal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(rippleNormal.xy, rippleNormal.xy))));
    return rippleNormal;
}

half4 RippleNormalTexture(float2 uv)
{
    half3 normalTS = RainRippleTS(uv);
    return half4(normalTS * 0.5 + 0.5, 1.0);
}

half3 SampleRippleNormalTextureNor(float2 uv)
{
#if defined(RAIN)
    half3 rippleNormal = SAMPLE_TEXTURE2D(_RainRippleNormal, sampler_linear_repeat, uv).rgb * 2.0 - 1.0;
    return normalize(rippleNormal);
#else
     return half3(0.0, 0.0, 1.0);
#endif
}

half3 SampleRippleNormalTexture(float2 uv)
{
#if defined(RAIN)
    half3 rippleNormal = SAMPLE_TEXTURE2D(_RainRippleNormal, sampler_linear_repeat, uv).rgb * 2.0 - 1.0;
    return rippleNormal;
#else
     return half3(0.0, 0.0, 1.0);
#endif
}

void DoWetProcess(inout half3 diffuse, inout half gloss, half wetLevel)
{
   //diffuse *= lerp(1.0, 0.3, wetLevel);
   diffuse *= lerp(1.0, 0.5, wetLevel);
   gloss = min(gloss * lerp(1.0, 2.5, wetLevel), 1.0);
}

half PuddleWater(half mask)
{
    return saturate((_FloodLevel.y - mask) / 0.4);
}

void GroundWet(inout half3 diffuse, inout half3 specular, inout half gloss, inout float3 normalWS, WetData wetdata)
{
    //half3 rippleNormal = RainRippleWS(wetdata.posWS.xz * 0.12);//可以放到低分辨率的全屏处理上计算切线空间法线
    //half3 waterNormal = rippleNormal;

    half3 rippleNormal = SampleRippleNormalTextureNor(wetdata.posWS.xz * 0.12);
    half3 waterNormal = half3(rippleNormal.x, rippleNormal.z, rippleNormal.y);
    
    //float sceneHeight = UnpackHeightmapPlusNoise(wetdata.posWS);
    //half heightOcclusion = saturate(wetdata.posWS.y + 1.0 - sceneHeight);
    half heightOcclusion = HeightTestPlusNoise(wetdata.posWS);

    half height = wetdata.height;
    half4 mask = wetdata.mask;
    half occlusion = mask.b * heightOcclusion;
    half accumulatedWater = 0;
    half3 upNormal= half3(0.0, 1.0, 0.0);
    half NdotUP = saturate(dot(normalWS, upNormal));
    half accumulatedWater_hole = min(_FloodLevel.x, 1.0 - height) * occlusion * smoothstep(0.95, 1.0, NdotUP); //缝隙内积水
    half accumulatedWater_puddle = PuddleWater(mask.g);//水坑内积水
    accumulatedWater  = max(accumulatedWater_hole, accumulatedWater_puddle);
    DoWetProcess(diffuse, gloss, saturate(_WetLevel * occlusion + accumulatedWater));
    gloss = lerp(gloss, 1.0, accumulatedWater);
    specular = lerp(specular, 0.02, accumulatedWater);
    normalWS = lerp(normalWS, waterNormal, accumulatedWater);
}
#endif