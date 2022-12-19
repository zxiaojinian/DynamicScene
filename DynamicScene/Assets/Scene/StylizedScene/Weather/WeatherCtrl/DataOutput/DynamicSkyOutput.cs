using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DynamicSkyOutput : BaseOutput
{
    public DynamicSkyOutput(WeatherSetting cur, TimeCtrl timeCtrl): base(cur, timeCtrl) { }

    #region Output
    //skybox
    public Color TopColor;
    public Color MiddleColor;
    public Color BottomColor;
    public float SunIntensity;
    public float MoonIntensity;
    public Color SunColor;
    public Color SunGlowColor;
    public float SunGlowRadius;
    public float MoonGlowRadius;
    public float StarIntensity;
    //cloud
    public float CloudFill;
    public Color CloudColor;
    public Color CloudRimColor;
    public Color CloudLightColor;
    public float CloudLightIntensity;
    public float CloudLightRadius;
    public float CloudLightRadiusIntensity;
    public float CloudSSSRadius;
    public float CloudSSSIntensity;
    //light
    public Color LightColor;
    public float LightIntensity;
    #endregion

    Color InitTopColor;
    Color InitMiddleColor;
    Color InitBottomColor;
    float InitSunIntensity;
    float InitMoonIntensity;
    Color InitSunColor;
    Color InitSunGlowColor;
    float InitSunGlowRadius;
    float InitMoonGlowRadius;
    float InitStarIntensity;
    //cloud
    float InitCloudFill;
    Color InitCloudColor;
    Color InitCloudRimColor;
    Color InitCloudLightColor;
    float InitCloudLightIntensity;
    float InitCloudLightRadius;
    float InitCloudLightRadiusIntensity;
    float InitCloudSSSRadius;
    float InitCloudSSSIntensity;
    //light
    Color InitLightColor;
    float InitLightIntensity;

    protected override void UpdateProgression()
    {
        if (TargetWeatherSetting.SkyTranslationDuration <= 0f)
        {
            TranslationProgression = 1f;
        }
        else
        {
            float timeCount = Time.time - translationInitTime;
            TranslationProgression = Mathf.Clamp01(timeCount / TargetWeatherSetting.SkyTranslationDuration);
        }
    }

    protected override void UpdateTranslationOutput()
    {
        //sky
        Color target = TargetWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
        TopColor = Color.Lerp(InitTopColor, target, TranslationProgression);

        target = TargetWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
        MiddleColor = Color.Lerp(InitMiddleColor, target, TranslationProgression);

        target = TargetWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
        BottomColor = Color.Lerp(InitBottomColor, target, TranslationProgression);

        target = TargetWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
        SunColor = Color.Lerp(InitSunColor, target, TranslationProgression);

        target = TargetWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
        SunGlowColor = Color.Lerp(InitSunGlowColor, target, TranslationProgression);

        float target_f = TargetWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
        SunGlowRadius = Mathf.Lerp(InitSunGlowRadius, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
        MoonGlowRadius = Mathf.Lerp(InitMoonGlowRadius, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        StarIntensity = Mathf.Lerp(InitStarIntensity, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.SunIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        SunIntensity = Mathf.Lerp(InitSunIntensity, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.MoonIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        MoonIntensity = Mathf.Lerp(InitMoonIntensity, target_f, TranslationProgression);

        //cloud
        target_f = TargetWeatherSetting.CloudFill.Evaluate(mTimeCtrlCom.CurveTime);
        CloudFill = Mathf.Lerp(InitCloudFill, target_f, TranslationProgression);

        target = TargetWeatherSetting.CloudColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudColor = Color.Lerp(InitCloudColor, target, TranslationProgression);

        target = TargetWeatherSetting.CloudRimColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudRimColor = Color.Lerp(InitCloudRimColor, target, TranslationProgression);

        target = TargetWeatherSetting.CloudLightColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudLightColor = Color.Lerp(InitCloudLightColor, target, TranslationProgression);

        target_f = TargetWeatherSetting.CloudLightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        CloudLightIntensity = Mathf.Lerp(InitCloudLightIntensity, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.CloudLightRadius.Evaluate(mTimeCtrlCom.CurveTime);
        CloudLightRadius = Mathf.Lerp(InitCloudLightRadius, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.CloudLightRadiusIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        CloudLightRadiusIntensity = Mathf.Lerp(InitCloudLightRadiusIntensity, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.CloudSSSRadius.Evaluate(mTimeCtrlCom.CurveTime);
        CloudSSSRadius = Mathf.Lerp(InitCloudSSSRadius, target_f, TranslationProgression);

        target_f = TargetWeatherSetting.CloudSSSIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        CloudSSSIntensity = Mathf.Lerp(InitCloudSSSIntensity, target_f, TranslationProgression);

        //light
        target = TargetWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
        LightColor = Color.Lerp(InitLightColor, target, TranslationProgression);

        target_f = TargetWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        LightIntensity = Mathf.Lerp(InitLightIntensity, target_f, TranslationProgression);
    }

    protected override void UpdateOutput()
    {
        TopColor = TargetWeatherSetting.TopColor.Evaluate(mTimeCtrlCom.GradientTime);
        MiddleColor = TargetWeatherSetting.MiddleColor.Evaluate(mTimeCtrlCom.GradientTime);
        BottomColor = TargetWeatherSetting.BottomColor.Evaluate(mTimeCtrlCom.GradientTime);
        SunIntensity = TargetWeatherSetting.SunIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        MoonIntensity = TargetWeatherSetting.MoonIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        SunColor = TargetWeatherSetting.SunColor.Evaluate(mTimeCtrlCom.GradientTime);
        SunGlowColor = TargetWeatherSetting.SunGlowColor.Evaluate(mTimeCtrlCom.GradientTime);
        SunGlowRadius = TargetWeatherSetting.SunGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
        MoonGlowRadius = TargetWeatherSetting.MoonGlowRadius.Evaluate(mTimeCtrlCom.CurveTime);
        StarIntensity = TargetWeatherSetting.StarIntensity.Evaluate(mTimeCtrlCom.CurveTime);

        CloudFill = TargetWeatherSetting.CloudFill.Evaluate(mTimeCtrlCom.CurveTime);
        CloudColor = TargetWeatherSetting.CloudColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudRimColor = TargetWeatherSetting.CloudRimColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudLightColor = TargetWeatherSetting.CloudLightColor.Evaluate(mTimeCtrlCom.GradientTime);
        CloudLightIntensity = TargetWeatherSetting.CloudLightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        CloudLightRadius = TargetWeatherSetting.CloudLightRadius.Evaluate(mTimeCtrlCom.CurveTime);
        CloudLightRadiusIntensity = TargetWeatherSetting.CloudLightRadiusIntensity.Evaluate(mTimeCtrlCom.CurveTime);
        CloudSSSRadius = TargetWeatherSetting.CloudSSSRadius.Evaluate(mTimeCtrlCom.CurveTime);
        CloudSSSIntensity = TargetWeatherSetting.CloudSSSIntensity.Evaluate(mTimeCtrlCom.CurveTime);

        LightColor = TargetWeatherSetting.LightColor.Evaluate(mTimeCtrlCom.GradientTime);
        LightIntensity = TargetWeatherSetting.LightIntensity.Evaluate(mTimeCtrlCom.CurveTime);
    }

    protected override void EnterTranslation()
    {
        InitTopColor = TopColor;
        InitMiddleColor = MiddleColor;
        InitBottomColor = BottomColor;
        InitSunIntensity = SunIntensity;
        InitMoonIntensity = MoonIntensity;
        InitSunColor = SunColor;
        InitSunGlowColor = SunGlowColor;
        InitSunGlowRadius = SunGlowRadius;
        InitMoonGlowRadius = MoonGlowRadius;
        InitStarIntensity = StarIntensity;
        //cloud
        InitCloudFill = CloudFill;
        InitCloudColor = CloudColor;
        InitCloudRimColor = CloudRimColor;
        InitCloudLightColor = CloudLightColor;
        InitCloudLightIntensity = CloudLightIntensity;
        InitCloudLightRadius = CloudLightRadius;
        InitCloudLightRadiusIntensity = CloudLightRadiusIntensity;
        InitCloudSSSRadius = CloudSSSRadius;
        InitCloudSSSIntensity = CloudSSSIntensity;
        //light
        InitLightColor = LightColor;
        InitLightIntensity = LightIntensity;
    }
}
