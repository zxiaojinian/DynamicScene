using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public enum EWeatherType
{
    Sunny,
    Cloudy,
    Rainy,
    thunderstorm
}

[Serializable]
public class Weather
{
    public EWeatherType WeatherType = EWeatherType.Sunny;
    public WeatherSetting WeatherSettingData;
}

[RequireComponent(typeof(TimeCtrl))]
[ExecuteAlways]
public class WeatherCtrl : MonoBehaviour
{
    public EWeatherType InitWeather;
    public Weather [] Weathers;

    WeatherOutput weatherOutput;
    public WeatherOutput WeatherOutputData
    {
        get { return weatherOutput; }
    }

    EWeatherType curWeather;
    public EWeatherType CurWeather
    {
        get
        {
            return curWeather;
        }
    }

    private void OnValidate()
    {
        Awake();
    }

    private void Awake()
    {
        TimeCtrl timeCtrl = GetComponent<TimeCtrl>();

        for (int i = 0; i < Weathers.Length; i++)
        {
            if (Weathers[i].WeatherType == InitWeather)
            {
                curWeather = InitWeather;
                weatherOutput = new WeatherOutput(Weathers[i].WeatherSettingData, timeCtrl);
                break;
            }
        }
    }

    private void Update()
    {
        weatherOutput.Update();
    }

    public void SetWeather(EWeatherType weatherType)
    {
        for(int i = 0; i < Weathers.Length; i++)
        {
            if(Weathers[i].WeatherType == weatherType)
            {
                curWeather = weatherType;
                weatherOutput.SetTranslation(Weathers[i].WeatherSettingData);
                break;
            }
        }
    }
}
