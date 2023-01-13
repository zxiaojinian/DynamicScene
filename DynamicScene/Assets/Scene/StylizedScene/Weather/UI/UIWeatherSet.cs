using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIWeatherSet : MonoBehaviour
{
    public Text CurWeatherTxt;
    public Dropdown ChooseWeatherBtn;
    public WeatherCtrl WeatherCtrlCom;

    void Start()
    {
        if (CurWeatherTxt != null && WeatherCtrlCom != null && WeatherCtrlCom.enabled)
        {
            CurWeatherTxt.text = WeatherCtrlCom.CurWeather.ToString();
        }

        if (ChooseWeatherBtn != null)
        {
            ChooseWeatherBtn.onValueChanged.AddListener((type) =>
            {
                if(WeatherCtrlCom != null && WeatherCtrlCom.enabled)
                {
                    WeatherCtrlCom.SetWeather((EWeatherType)type);
                    if(CurWeatherTxt != null) CurWeatherTxt.text = WeatherCtrlCom.CurWeather.ToString();
                }
            });
        }
    }
}
