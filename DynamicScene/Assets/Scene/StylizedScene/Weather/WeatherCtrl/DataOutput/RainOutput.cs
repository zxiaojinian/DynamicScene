using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainOutput : BaseOutput
{
    public RainOutput(WeatherSetting cur, TimeCtrl timeCtrl) : base(cur, timeCtrl) { }

    #region Output
    //public Texture2D RainShapeTexture;

    public float RainIntensity;
    public float RainOpacityInAll;
    public Color RainColor;
    public Vector4 RainScale_Layer12;
    public Vector4 RainScale_Layer34;
    public Vector4 RotateSpeed;
    public Vector4 RotateAmount;
    public Vector4 DropSpeed;
    public Vector4 RainOpacity;
    //SplashInterval,SplashPlayTime
    public Vector3 SplashData_1;
    //SplashScale, SplashOpacity
    public Vector4 SplashData_2;
    //WetLevel,GapFloodLevel,PuddleFloodLevel
    public Vector3 WetData;
    #endregion

    float InitRainIntensity;
    float InitRainOpacityInAll;
    Color InitRainColor;
    Vector4 InitRainScale_Layer12;
    Vector4 InitRainScale_Layer34;
    Vector4 InitRotateSpeed;
    Vector4 InitRotateAmount;
    Vector4 InitDropSpeed;
    Vector4 InitRainOpacity;
    //SplashInterval,SplashPlayTime
    Vector3 InitSplashData_1;
    //SplashScale, SplashOpacity
    Vector4 InitSplashData_2;

    public float GetInitRainIntensity
    {
        get
        {
            return InitRainIntensity;
        }
    }

    protected override void UpdateProgression()
    {
        if (TargetWeatherSetting.RainTranslationDuration <= 0f)
        {
            TranslationProgression = 1f;
        }
        else
        {
            float timeCount = Time.time - translationInitTime;
            TranslationProgression = Mathf.Clamp01(timeCount / TargetWeatherSetting.RainTranslationDuration);
        }
    }

    protected override void UpdateTranslationOutput()
    {
        RainIntensity = Mathf.Lerp(InitRainIntensity, TargetWeatherSetting.RainIntensity, TranslationProgression);

        //都在下雨，混合；只有目标在下雨，取目标；否者，取当前
        if (InitRainIntensity > 0 && TargetWeatherSetting.RainIntensity > 0)
        {
            WeatherSetting setting = TargetWeatherSetting;
            RainOpacityInAll = Mathf.Lerp(InitRainOpacityInAll, TargetWeatherSetting.RainOpacityInAll, TranslationProgression);
            RainColor = Color.Lerp(InitRainColor, TargetWeatherSetting.RainColor, TranslationProgression);

            //RainScale_Layer12
            Vector2 layer1_Cur = setting.RainScale_One;
            Vector2 layer2_Cur = setting.RainScale_Two;
            RainScale_Layer12 = Vector4.Lerp(InitRainScale_Layer12, new Vector4(layer1_Cur.x, layer1_Cur.y, layer2_Cur.x, layer2_Cur.y), TranslationProgression);

            //RainScale_Layer34
            Vector2 layer3_Cur = setting.RainScale_Three;
            Vector2 layer4_Cur = setting.RainScale_Four;
            RainScale_Layer34 = Vector4.Lerp(InitRainScale_Layer34, new Vector4(layer3_Cur.x, layer3_Cur.y, layer4_Cur.x, layer4_Cur.y), TranslationProgression);

            //RotateSpeed
            RotateSpeed = Vector4.Lerp(InitRotateSpeed, new Vector4(setting.RotateSpeed_One, setting.RotateSpeed_Two, setting.RotateSpeed_Three, setting.RotateSpeed_Four), TranslationProgression);

            //RotateAmount
            RotateAmount = Vector4.Lerp(InitRotateAmount, new Vector4(setting.RotateAmount_One, setting.RotateAmount_Two, setting.RotateAmount_Three, setting.RotateAmount_Four), TranslationProgression);

            //DropSpeed
            DropSpeed = Vector4.Lerp(InitDropSpeed, new Vector4(setting.DropSpeed_One, setting.DropSpeed_Two, setting.DropSpeed_Three, setting.DropSpeed_Four), TranslationProgression);

            //RainOpacity
            RainOpacity = Vector4.Lerp(InitRainOpacity, new Vector4(setting.RainOpacity_One, setting.RainOpacity_Two, setting.RainOpacity_Three, setting.RainOpacity_Four), TranslationProgression);

            //SplashData_1
            SplashData_1 = Vector3.Lerp(InitSplashData_1, new Vector3(setting.SplashIntervalMin, setting.SplashIntervalMax, setting.SplashPlayTime), TranslationProgression);

            //SplashData_2
            SplashData_2 = Vector4.Lerp(InitSplashData_2, new Vector4(setting.SplashScaleMin, setting.SplashScaleMax, setting.SplashOpacityMin, setting.SplashOpacityMax), TranslationProgression);

            //WetData
            //WetData = Vector3.Lerp(InitWetData, new Vector3(setting.MaxWetLevel, setting.MaxGapFloodLevel, setting.MaxPuddleFloodLevel), mTranslationProgression);
            WetData.x = setting.MaxWetLevel;
            WetData.y = setting.MaxGapFloodLevel;
            WetData.z = setting.MaxPuddleFloodLevel;
        }
        else if (TargetWeatherSetting.RainIntensity > 0)
        {
            UpdateSingleOutput(TargetWeatherSetting);
        }
    }

    protected override void UpdateOutput()
    {
        RainIntensity = TargetWeatherSetting.RainIntensity;
        UpdateSingleOutput(TargetWeatherSetting);
    }

    void UpdateSingleOutput(WeatherSetting setting)
    {
        RainOpacityInAll = setting.RainOpacityInAll;
        RainColor = setting.RainColor;

        //RainScale_Layer12
        RainScale_Layer12.x = setting.RainScale_One.x;
        RainScale_Layer12.y = setting.RainScale_One.y;
        RainScale_Layer12.z = setting.RainScale_Two.x;
        RainScale_Layer12.w = setting.RainScale_Two.y;

        //RainScale_Layer34
        RainScale_Layer34.x = setting.RainScale_Three.x;
        RainScale_Layer34.y = setting.RainScale_Three.y;
        RainScale_Layer34.z = setting.RainScale_Four.x;
        RainScale_Layer34.w = setting.RainScale_Four.y;

        //RotateSpeed
        RotateSpeed.x = setting.RotateSpeed_One;
        RotateSpeed.y = setting.RotateSpeed_Two;
        RotateSpeed.z = setting.RotateSpeed_Three;
        RotateSpeed.w = setting.RotateSpeed_Four;

        //RotateAmount
        RotateAmount.x = setting.RotateAmount_One;
        RotateAmount.y = setting.RotateAmount_Two;
        RotateAmount.z = setting.RotateAmount_Three;
        RotateAmount.w = setting.RotateAmount_Four;

        //DropSpeed
        DropSpeed.x = setting.DropSpeed_One;
        DropSpeed.y = setting.DropSpeed_Two;
        DropSpeed.z = setting.DropSpeed_Three;
        DropSpeed.w = setting.DropSpeed_Four;

        //RainOpacity
        RainOpacity.x = setting.RainOpacity_One;
        RainOpacity.y = setting.RainOpacity_Two;
        RainOpacity.z = setting.RainOpacity_Three;
        RainOpacity.w = setting.RainOpacity_Four;

        //SplashData_1
        SplashData_1.x = setting.SplashIntervalMin;
        SplashData_1.y = setting.SplashIntervalMax;
        SplashData_1.z = setting.SplashPlayTime;

        //SplashData_2
        SplashData_2.x = setting.SplashScaleMin;
        SplashData_2.y = setting.SplashScaleMax;
        SplashData_2.z = setting.SplashOpacityMin;
        SplashData_2.w = setting.SplashOpacityMax;

        //WetData
        WetData.x = setting.MaxWetLevel;
        WetData.y = setting.MaxGapFloodLevel;
        WetData.z = setting.MaxPuddleFloodLevel;
    }

    protected override void EnterTranslation()
    {
        InitRainIntensity = RainIntensity;
        InitRainOpacityInAll = RainOpacityInAll;
        InitRainColor = RainColor;
        InitRainScale_Layer12 = RainScale_Layer12;
        InitRainScale_Layer34 = RainScale_Layer34;
        InitRotateSpeed = RotateSpeed;
        InitRotateAmount = RotateAmount;
        InitDropSpeed = DropSpeed;
        InitRainOpacity = RainOpacity;
        InitSplashData_1 = SplashData_1;
        InitSplashData_2 = SplashData_2;
    }
}
