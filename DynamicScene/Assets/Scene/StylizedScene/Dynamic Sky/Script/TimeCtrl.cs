using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TimeCtrl : MonoBehaviour
{
    public bool UpdateTime = true;
    [Range(0f, 24f)]
    public float TimeofDay = 6f;
    public float AllDayInMinutes = 10f;
    [Range(0f, 24f)]
    public float DayStartTime = 5f;
    [Range(1f, 24f)]
    public float DayDuration = 14f;

    float mTimeProgression;
    float mNightStartTime;
    float mNightDuration;

    float mCurveTime;
    float mGradientTime;
    float mDayProgression;
    float mNightProgression;

    public float CurveTime
    {
        get { return mCurveTime; }
    }

    public float GradientTime
    {
        get { return mGradientTime; }
    }

    public float DayProgression
    {
        get { return mDayProgression; }
    }

    public float NightProgression
    {
        get { return mNightProgression; }
    }

    public bool IsDay
    {
        get
        {
            return TimeofDay <= DayStartTime + DayDuration && TimeofDay >= DayStartTime;
        }
    }

    private void Start()
    {
        if(AllDayInMinutes > 0)
        {
            mTimeProgression = 24f / 60f / AllDayInMinutes;
        }
        else
        {
            mTimeProgression = 0;
        }

        mNightStartTime = Mathf.Min(DayStartTime + DayDuration, 24f);
        mNightDuration = 24f - mNightStartTime + DayStartTime;
        CalculationProgression();
    }

    private void Update()
    {
        if(Application.isPlaying && UpdateTime)
        {
            TimeofDay += Time.deltaTime * mTimeProgression;
            if(TimeofDay >= 24f)
            {
                TimeofDay %= 24f;
            }
        }
        CalculationProgression();
    }

    void CalculationProgression()
    {
        mCurveTime = TimeofDay;
        mGradientTime = TimeofDay / 24f;
        mDayProgression = Mathf.Clamp01((TimeofDay - DayStartTime) / DayDuration);
        if(mNightDuration > 0)
        {
            if (TimeofDay >= mNightStartTime)
            {
                mNightProgression = Mathf.Clamp01((TimeofDay - mNightStartTime) / mNightDuration);
            }
            else
            {
                mNightProgression = Mathf.Clamp01((TimeofDay + 24f - mNightStartTime) / mNightDuration);
            }
        }
    }
}
