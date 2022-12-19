using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Weather Setting", menuName = "Code Repository/Scene/WeatherSetting")]
public class WeatherSetting : ScriptableObject
{
    public float SkyTranslationOffset = 0f;
    public float SkyTranslationDuration = 10f;

    [Header("Sky Color Setting")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient TopColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MiddleColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient BottomColor;

    [Header("OuterSpace Setting")]
    public AnimationCurve SunIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve MoonIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunGlowColor;

    public AnimationCurve SunGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve MoonGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    public AnimationCurve StarIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    [Header("Cloud Setting")]
    public AnimationCurve CloudFill = AnimationCurve.Linear(0f, 0.5f, 24f, 0.5f);
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudColor;
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudRimColor;
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudLightColor;
    public AnimationCurve CloudLightIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve CloudLightRadius = AnimationCurve.Linear(0f, 0.75f, 24f, 0.75f);
    public AnimationCurve CloudLightRadiusIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve CloudSSSRadius = AnimationCurve.Linear(0f, 0.1f, 24f, 0.1f);
    public AnimationCurve CloudSSSIntensity = AnimationCurve.Linear(0f, 2f, 24f, 2f);

    [Header("Light Setting")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);


    [Header("Rain Setting")]
    public float RainTranslationOffset = 5f;
    public float RainTranslationDuration = 10f;

    //public Texture2D RainShapeTexture;

    [Range(0f, 1f)]
    public float RainIntensity = 1f;
    [Range(0f, 1f)]
    public float RainOpacityInAll = 1f;
    public Color RainColor = Color.white;
    [Header("Raindrop Layer One")]
    public Vector2 RainScale_One = Vector2.one;
    public float RotateSpeed_One = 1f;
    public float RotateAmount_One = 0.5f;
    public float DropSpeed_One = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_One = 1f;

    [Header("Raindrop Layer Two")]
    public Vector2 RainScale_Two = Vector2.one * 1.5f;
    public float RotateSpeed_Two = 1f;
    public float RotateAmount_Two = 0.5f;
    public float DropSpeed_Two = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Two = 1f;

    [Header("Raindrop Layer Three")]
    public Vector2 RainScale_Three = Vector2.one * 1.7f;
    public float RotateSpeed_Three = 1f;
    public float RotateAmount_Three = 0.5f;
    public float DropSpeed_Three = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Three = 1f;

    [Header("Raindrop Layer Four")]
    public Vector2 RainScale_Four = Vector2.one * 2f;
    public float RotateSpeed_Four = 1f;
    public float RotateAmount_Four = 0.5f;
    public float DropSpeed_Four = 1f;
    [Range(0f, 1f)]
    public float RainOpacity_Four = 1f;

    [Header("RainSplash")]
    //public int SplashCountMax = 50;
    public float SplashPlayTime = 0.2f;
    public float SplashIntervalMin = 0.3f;
    public float SplashIntervalMax = 0.5f;
    public float SplashScaleMin = 0.5f;
    public float SplashScaleMax = 1f;
    public float SplashOpacityMin = 0.5f;
    public float SplashOpacityMax = 1f;

    [Header("Wet&AccumulatedWater")]
    [Range(0f, 1f)]
    public float MaxWetLevel = 1f;
    [Range(0f, 1f)]
    public float MaxGapFloodLevel = 1f;
    [Range(0f, 1f)]
    public float MaxPuddleFloodLevel = 1f;
}
