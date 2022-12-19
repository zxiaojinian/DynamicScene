using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeatherOutput
{
    DynamicSkyOutput dynamicSkyOutput = null;
    RainOutput rainOutput = null;
    WeatherSetting target;
    float translationInitTime;
    bool isSetTranslation = false;
    bool isSetSkyTranslation = false;
    bool isSetRainTranslation = false;
    bool isRaining = false;

    public DynamicSkyOutput DynamicSkyOutputData
    {
        get { return dynamicSkyOutput; }
    }

    public RainOutput RainOutputData
    {
        get { return rainOutput; }
    }

    public WeatherOutput(WeatherSetting cur, TimeCtrl timeCtrl)
    {
        dynamicSkyOutput = new DynamicSkyOutput(cur, timeCtrl);
        rainOutput = new RainOutput(cur, timeCtrl);
        target = cur;
    }

    public void SetTranslation(WeatherSetting targetWeatherSetting)
    {
        if (target == targetWeatherSetting) return;
        target = targetWeatherSetting;
        translationInitTime = Time.time;
        isSetTranslation = true;
        isSetSkyTranslation = false;
        isSetRainTranslation = false;
        isRaining = rainOutput.RainIntensity > 0f;
    }

    public void Update()
    {
        if(isSetTranslation)
        {
            bool isTargetRaining = target.RainIntensity > 0f;
            //no rain >> rain
            if (!isRaining && isTargetRaining)
            {
                if (!isSetSkyTranslation)
                {
                    dynamicSkyOutput.SetTranslation(target, Time.time);
                    isSetSkyTranslation = true;
                }
                float timeCount = Time.time - translationInitTime;
                if (timeCount >= target.RainTranslationOffset)
                {
                    rainOutput.SetTranslation(target, Time.time);
                    isSetTranslation = false;
                }
            }
            //rain >> no rain
            else if (isRaining && !isTargetRaining)
            {
                if(!isSetRainTranslation)
                {
                    rainOutput.SetTranslation(target, Time.time);
                    isSetRainTranslation = true;
                }
                float timeCount = Time.time - translationInitTime;
                if (timeCount >= target.SkyTranslationOffset)
                {
                    dynamicSkyOutput.SetTranslation(target, Time.time);
                    isSetTranslation = false;
                }
            }
            else
            {
                isSetTranslation = false;
                dynamicSkyOutput.SetTranslation(target, Time.time);
                rainOutput.SetTranslation(target, Time.time);
                isSetSkyTranslation = true;
                isSetRainTranslation = true;
            }
        }
        dynamicSkyOutput.Update();
        rainOutput.Update();
    }
}
