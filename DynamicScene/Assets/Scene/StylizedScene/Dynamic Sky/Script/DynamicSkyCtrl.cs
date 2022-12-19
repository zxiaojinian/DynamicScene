using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(TimeCtrl))]
[ExecuteAlways]
public class DynamicSkyCtrl : MonoBehaviour
{
    [Header("Sky Color")]
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient TopColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient MiddleColor;

    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient BottomColor;

    [Header("OuterSpace")]
    [Range(-180f, 180f)]
    public float Longitude = 0.0f;
    [Range(-180f, 180f)]
    public float Latitude = 0.0f;

    public AnimationCurve SunIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve MoonIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunColor;
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient SunGlowColor;
    public AnimationCurve SunGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve MoonGlowRadius = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve StarIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);

    [Header("Cloud")]
    public AnimationCurve CloudFill = AnimationCurve.Linear(0f, 0.5f, 24f, 0.5f);
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudColor;
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudRimColor;
    [GradientUsage(true, ColorSpace.Linear)]
    public Gradient CloudLightColor;
    public AnimationCurve CloudLightIntensity = AnimationCurve.Linear(0f, 1f, 24f, 1f);
    public AnimationCurve CloudLightRadius = AnimationCurve.Linear(0f, 0.75f, 24f, 0.75f);
    public AnimationCurve CloudLightRadiusIntensity = AnimationCurve.Linear(0f, 1.5f, 24f, 1.5f);
    public AnimationCurve CloudSSSRadius = AnimationCurve.Linear(0f, 0.1f, 24f, 0.1f);
    public AnimationCurve CloudSSSIntensity = AnimationCurve.Linear(0f, 1.5f, 24f, 1.5f);

    [Header("Light")]
    public Gradient LightColor;
    public AnimationCurve LightIntensity = AnimationCurve.Linear(0f, 0f, 24f, 1f);

    [Header("Reference Node")]
    public Material SkyMat;
    public Material CloudMat;
    public Transform Light;

    TimeCtrl mTimeCtrl;
    WeatherCtrl mWeatherCtrl;
    Light mLightCom;

    readonly int mID_TopColor = Shader.PropertyToID("_TopColor");
    readonly int mID_MiddleColor = Shader.PropertyToID("_MiddleColor");
    readonly int mID_BottomColor = Shader.PropertyToID("_BottomColor");
    readonly int mID_SunStr = Shader.PropertyToID("_SunIntensity");
    readonly int mID_MoonStr = Shader.PropertyToID("_MoonIntensity");
    readonly int mID_SunColor = Shader.PropertyToID("_SunColor");
    readonly int mID_SunGlowColor = Shader.PropertyToID("_SunGlowColor");
    readonly int mID_SunGlowRadius = Shader.PropertyToID("_SunGlowRadius");
    readonly int mID_MoonGlowRadius = Shader.PropertyToID("_MoonGlowRadius");
    readonly int mID_StarIntensity = Shader.PropertyToID("_StarIntensity");
    readonly int mID_CloudFill = Shader.PropertyToID("_CloudFill");
    readonly int mID_CloudColor = Shader.PropertyToID("_CloudColor");
    readonly int mID_CloudRimColor = Shader.PropertyToID("_CloudRimColor");
    readonly int mID_CloudLightColor = Shader.PropertyToID("_CloudLightColor");
    readonly int mID_CloudLightIntensity = Shader.PropertyToID("_CloudLightIntensity");
    readonly int mID_CloudLightRadius = Shader.PropertyToID("_CloudLightRadius");
    readonly int mID_CloudLightRadiusIntensity = Shader.PropertyToID("_CloudLightRadiusIntensity");
    readonly int mID_CloudSSSRadius = Shader.PropertyToID("_CloudSSSRadius");
    readonly int mID_CloudSSSIntensity = Shader.PropertyToID("_CloudSSSIntensity");
    readonly int mID_IsNight = Shader.PropertyToID("_IsNight");
    readonly int mID_LightMatrix = Shader.PropertyToID("_LightMatrix");

    private void Start()
    {       
        mTimeCtrl = GetComponent<TimeCtrl>();
        mWeatherCtrl = GetComponent<WeatherCtrl>();
        if (Light != null)  mLightCom = Light.GetComponent<Light>(); 
    }

    private void LateUpdate()
    {
        UpdateLight();
        UpdateSkyBox();
        UpdateSkyCloud();
    }

    void UpdateSkyBox()
    {
        if(SkyMat != null)
        {
            RenderSettings.skybox = SkyMat;
            if (mWeatherCtrl != null && mWeatherCtrl.enabled && mWeatherCtrl.WeatherOutputData != null)
            {
                DynamicSkyOutput output = mWeatherCtrl.WeatherOutputData.DynamicSkyOutputData;
                SkyMat.SetVector(mID_BottomColor, output.BottomColor);
                SkyMat.SetVector(mID_MiddleColor, output.MiddleColor);
                SkyMat.SetVector(mID_TopColor, output.TopColor);
                SkyMat.SetFloat(mID_SunStr, output.SunIntensity);
                SkyMat.SetFloat(mID_MoonStr, output.MoonIntensity);
                SkyMat.SetVector(mID_SunColor, output.SunColor);
                SkyMat.SetVector(mID_SunGlowColor, output.SunGlowColor);
                SkyMat.SetFloat(mID_SunGlowRadius, output.SunGlowRadius);
                SkyMat.SetFloat(mID_MoonGlowRadius, output.MoonGlowRadius);
                SkyMat.SetFloat(mID_StarIntensity, output.StarIntensity);
            }
            else
            {
                float colorKey = 0f;
                float floatKey = 0f;
                if (mTimeCtrl != null)
                {
                    colorKey = mTimeCtrl.GradientTime;
                    floatKey = mTimeCtrl.CurveTime;
                }
                SkyMat.SetVector(mID_BottomColor, BottomColor.Evaluate(colorKey));
                SkyMat.SetVector(mID_MiddleColor, MiddleColor.Evaluate(colorKey));
                SkyMat.SetVector(mID_TopColor, TopColor.Evaluate(colorKey));
                SkyMat.SetFloat(mID_SunStr, SunIntensity.Evaluate(floatKey));
                SkyMat.SetFloat(mID_MoonStr, MoonIntensity.Evaluate(floatKey));
                SkyMat.SetVector(mID_SunColor, SunColor.Evaluate(colorKey));
                SkyMat.SetVector(mID_SunGlowColor, SunGlowColor.Evaluate(colorKey));
                SkyMat.SetFloat(mID_SunGlowRadius, SunGlowRadius.Evaluate(floatKey));
                SkyMat.SetFloat(mID_MoonGlowRadius, MoonGlowRadius.Evaluate(floatKey));
                SkyMat.SetFloat(mID_StarIntensity, StarIntensity.Evaluate(floatKey));
            }
        }
    }

    void UpdateSkyCloud()
    {
        if(CloudMat != null)
        {
            if (mWeatherCtrl != null && mWeatherCtrl.enabled && mWeatherCtrl.WeatherOutputData != null)
            {
                DynamicSkyOutput output = mWeatherCtrl.WeatherOutputData.DynamicSkyOutputData;
                CloudMat.SetVector(mID_CloudColor, output.CloudColor);
                CloudMat.SetVector(mID_CloudRimColor, output.CloudRimColor);
                CloudMat.SetVector(mID_CloudLightColor, output.CloudLightColor);
                CloudMat.SetFloat(mID_CloudFill, output.CloudFill);
                CloudMat.SetFloat(mID_CloudLightIntensity, output.CloudLightIntensity);
                CloudMat.SetFloat(mID_CloudLightRadius, output.CloudLightRadius);
                CloudMat.SetFloat(mID_CloudLightRadiusIntensity, output.CloudLightRadiusIntensity);
                CloudMat.SetFloat(mID_CloudSSSRadius, output.CloudSSSRadius);
                CloudMat.SetFloat(mID_CloudSSSIntensity, output.CloudSSSIntensity);
            }
            else
            {
                float colorKey = 0f;
                float floatKey = 0f;
                if (mTimeCtrl != null)
                {
                    colorKey = mTimeCtrl.GradientTime;
                    floatKey = mTimeCtrl.CurveTime;
                }
                CloudMat.SetVector(mID_CloudColor, CloudColor.Evaluate(colorKey));
                CloudMat.SetVector(mID_CloudRimColor, CloudRimColor.Evaluate(colorKey));
                CloudMat.SetVector(mID_CloudLightColor, CloudLightColor.Evaluate(colorKey));
                CloudMat.SetFloat(mID_CloudFill, CloudFill.Evaluate(floatKey));
                CloudMat.SetFloat(mID_CloudLightIntensity, CloudLightIntensity.Evaluate(floatKey));
                CloudMat.SetFloat(mID_CloudLightRadius, CloudLightRadius.Evaluate(floatKey));
                CloudMat.SetFloat(mID_CloudLightRadius, CloudLightRadiusIntensity.Evaluate(floatKey));
                CloudMat.SetFloat(mID_CloudSSSRadius, CloudSSSRadius.Evaluate(floatKey));
                CloudMat.SetFloat(mID_CloudSSSIntensity, CloudSSSIntensity.Evaluate(floatKey));
            }
        }
    }

    void UpdateLight()
    {
        if(Light != null)
        {
            float sunProgression = 0f;
            float moonProgression = 0f;
            bool isNight = false;
            if(mTimeCtrl != null)
            {
                sunProgression = mTimeCtrl.DayProgression;
                moonProgression = mTimeCtrl.NightProgression;
                isNight = !mTimeCtrl.IsDay;
            }

            if (!isNight)
            {
                Light.rotation = Quaternion.Euler(0.0f, Longitude, Latitude) * Quaternion.Euler(Mathf.Lerp(-15f, 195f, sunProgression), 180f, 0f);
                Shader.SetGlobalFloat(mID_IsNight, 0f);
                Shader.DisableKeyword("_NIGHT");
            }
            else
            {
                Light.rotation = Quaternion.Euler(0.0f, Longitude, Latitude) * Quaternion.Euler(Mathf.Lerp(-15f, 195f, moonProgression), 180f, 0f);
                Shader.SetGlobalFloat(mID_IsNight, 1f);
                Shader.EnableKeyword("_NIGHT");
            }
            Shader.SetGlobalMatrix(mID_LightMatrix, Light.worldToLocalMatrix);
        }
        
        if(mLightCom != null)
        {
            float colorKey = 0f;
            float floatKey = 0f;
            if (mTimeCtrl != null)
            {
                colorKey = mTimeCtrl.GradientTime;
                floatKey = mTimeCtrl.CurveTime;
            }
            if (mWeatherCtrl != null && mWeatherCtrl.enabled && mWeatherCtrl.WeatherOutputData != null)
            {
                DynamicSkyOutput output = mWeatherCtrl.WeatherOutputData.DynamicSkyOutputData;
                mLightCom.color = output.LightColor;
                mLightCom.intensity = output.LightIntensity;
                mLightCom.shadowStrength = mLightCom.intensity;
            }
            else
            {
                mLightCom.color = LightColor.Evaluate(colorKey);
                mLightCom.intensity = LightIntensity.Evaluate(floatKey);
                mLightCom.shadowStrength = mLightCom.intensity;
            }
            RenderSettings.ambientLight = mLightCom.color * mLightCom.intensity * 0.5f;
        }
    }
}
