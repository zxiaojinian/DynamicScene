using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class BaseOutput
{
    public WeatherSetting TargetWeatherSetting;
    protected TimeCtrl mTimeCtrlCom;
    public float TranslationProgression;
    protected float translationInitTime;
    protected bool isTranslation = false;

    protected BaseOutput(WeatherSetting cur, TimeCtrl timeCtrl)
    {
        TargetWeatherSetting = cur;
        mTimeCtrlCom = timeCtrl;
    }

    public void SetTranslation(WeatherSetting targetWeatherSetting, float translationInitTime)
    {
        this.translationInitTime = translationInitTime;
        TargetWeatherSetting = targetWeatherSetting;
        TranslationProgression = 0f;
        isTranslation = true;
        EnterTranslation();
    }


    public void Update()
    {
        if (isTranslation)
        {
            UpdateProgression();
            UpdateTranslationOutput();
            if (TranslationProgression >= 1f)
            {
                TranslationProgression = 0f;
                isTranslation = false;
            }
        }
        else
        {
            UpdateOutput();
        }
    }

    protected abstract void EnterTranslation();
    protected abstract void UpdateProgression();
    protected abstract void UpdateTranslationOutput();
    protected abstract void UpdateOutput();
}
