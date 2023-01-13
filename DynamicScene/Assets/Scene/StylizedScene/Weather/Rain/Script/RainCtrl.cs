using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class RainCtrl : MonoBehaviour
{
    #region Data
    [Header("Asset")]
    public Shader RainShader;
    public Texture2D RainShapeTexture;
    public Texture2D RainSplashTex;
    public Texture2D RippleTexture;

    [Space]
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
    public float RainDepthStart_One = 0f;
    public float RainDepthRange_One = 5f;
    [Range(0f, 1f)]
    public float RainOpacity_One = 1f;

    [Header("Raindrop Layer Two")]
    public Vector2 RainScale_Two = Vector2.one * 1.5f;
    public float RotateSpeed_Two = 1f;
    public float RotateAmount_Two = 0.5f;
    public float DropSpeed_Two = 1f;
    public float RainDepthStart_Two = 5f;
    public float RainDepthRange_Two = 10f;
    [Range(0f, 1f)]
    public float RainOpacity_Two = 1f;

    [Header("Raindrop Layer Three")]
    public Vector2 RainScale_Three = Vector2.one * 1.7f;
    public float RotateSpeed_Three = 1f;
    public float RotateAmount_Three = 0.5f;
    public float DropSpeed_Three = 1f;
    public float RainDepthStart_Three = 15f;
    public float RainDepthRange_Three = 20f;
    [Range(0f, 1f)]
    public float RainOpacity_Three = 1f;

    [Header("Raindrop Layer Four")]
    public Vector2 RainScale_Four = Vector2.one * 2f;
    public float RotateSpeed_Four = 1f;
    public float RotateAmount_Four = 0.5f;
    public float DropSpeed_Four = 1f;
    public float RainDepthStart_Four = 35f;
    public float RainDepthRange_Four = 50f;
    [Range(0f, 1f)]
    public float RainOpacity_Four = 1f;

    [Header("RainSplash")]
    public bool EnableRainSplash = true;
    public int SplashTexRow = 1;
    public int SplashTexCol = 1;
    public int SplashCountMax = 50;
    public float RainSplashRadius = 50f;
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
    public float WetTime = 5f;
    public float DryTime = 10f;

    [Range(0f, 1f)]
    public float MaxGapFloodLevel = 1f;
    public float GapAccumulatedWaterTime = 10f;
    public float GapWaterRemainTime = 5f;
    public float GapWaterRemoveTime = 15f;

    [Range(0f, 1f)]
    public float MaxPuddleFloodLevel = 1f;
    public float PuddleAccumulatedWaterTime = 10f;
    public float PuddleWaterRemainTime = 20f;
    public float PuddleWaterRemoveTime = 40f;
    #endregion

    Material mRainMat;
    Vector4[] splashInfo_1;//pos.xz,scale,index
    float[] splashInfo_2;  //opacity
    Vector3[] splashLifeData; //lifeTime, timecounter, maxScale
    Matrix4x4[] splashMatrix;

    //Wet&AccumulatedWater
    enum RainState
    {
        raining,
        stop
    }
    RainState rainState = RainState.stop;
    float rainStopTime;
    float wetLevel = 0f;
    Vector2 floodLevel = Vector2.zero;

    //component
    WeatherCtrl weatherCtrl;

    //public Data
    public bool EnableRaindrop 
    {
        get 
        {
            if(weatherCtrl != null && weatherCtrl.WeatherOutputData != null)
            {
                return weatherCtrl.WeatherOutputData.RainOutputData.RainIntensity > 0;
            }
            return RainIntensity > 0; 
        } 
    }

    public Material RainMaterial { get { return mRainMat; } }
    public Vector4[] SplashInfo_1 { get { return splashInfo_1; } }
    public float[] SplashInfo_2 { get { return splashInfo_2; } }
    public Matrix4x4[] SplashMatrix { get { return splashMatrix; } }

    #region shader property
    static readonly int id_RainIntensity = Shader.PropertyToID("_RainIntensity");
    static readonly int id_RainOpacityInAll = Shader.PropertyToID("_RainOpacityInAll");
    static readonly int id_RainColor = Shader.PropertyToID("_RainColor");
    static readonly int id_RainShapeTex = Shader.PropertyToID("_RainShapeTex");
    static readonly int id_RainScale_Layer12 = Shader.PropertyToID("_RainScale_Layer12");
    static readonly int id_RainScale_Layer34 = Shader.PropertyToID("_RainScale_Layer34");
    static readonly int id_RotateSpeed = Shader.PropertyToID("_RotateSpeed");
    static readonly int id_RotateAmount = Shader.PropertyToID("_RotateAmount");
    static readonly int id_DropSpeed = Shader.PropertyToID("_DropSpeed");
    static readonly int id_RainDepthStart = Shader.PropertyToID("_RainDepthStart");
    static readonly int id_RainDepthRange = Shader.PropertyToID("_RainDepthRange");
    static readonly int id_RainOpacities = Shader.PropertyToID("_RainOpacities");
    static readonly int id_RainSplashTex = Shader.PropertyToID("_RainSplashTex");
    static readonly int id_GlobalSplashInfo = Shader.PropertyToID("_GlobalSplashInfo");
    static readonly int id_WetLevel = Shader.PropertyToID("_WetLevel");
    static readonly int id_FloodLevel = Shader.PropertyToID("_FloodLevel");
    static readonly int id_RippleTexture = Shader.PropertyToID("_RippleTexture");

    #endregion

    static RainCtrl instance;
    public static RainCtrl Instance
    {
        get { return instance; }
    }

    private void Awake()
    {
        instance = this;
        weatherCtrl = GetComponent<WeatherCtrl>();
    }

    private void LateUpdate()
    {
        UpdateGlobalData();
        if (EnableRaindrop)
        {
            InitMat();
            UpdateRainDrop();
            UpdateRainSplash();
        }
        UpdateRainRipple();
        UpdateWetAndAccumulatedWater();
    }

    private void OnDestroy()
    {
        DisposeCreatedRes();
    }

    void InitMat()
    {
        if (mRainMat == null && RainShader != null)
        {
            mRainMat = new Material(RainShader);
            mRainMat.enableInstancing = true;
        }
    }

    void UpdateGlobalData()
    {
        if (weatherCtrl != null && weatherCtrl.WeatherOutputData != null)
        {
            RainOutput rainOutput = weatherCtrl.WeatherOutputData.RainOutputData;
            Shader.SetGlobalFloat(id_RainIntensity, rainOutput.RainIntensity);
        }
        else
        {
            Shader.SetGlobalFloat(id_RainIntensity, RainIntensity);
        }
    }

    void UpdateRainDrop()
    {
        if (mRainMat != null)
        {
            mRainMat.SetTexture(id_RainShapeTex, RainShapeTexture);
            mRainMat.SetVector(id_RainDepthStart, new Vector4(RainDepthStart_One, RainDepthStart_Two, RainDepthStart_Three, RainDepthStart_Four));
            mRainMat.SetVector(id_RainDepthRange, new Vector4(RainDepthRange_One, RainDepthRange_Two, RainDepthRange_Three, RainDepthRange_Four));
            mRainMat.SetTexture(id_RippleTexture, RippleTexture);

            if (weatherCtrl != null && weatherCtrl.WeatherOutputData != null)
            {
                RainOutput rainOutput = weatherCtrl.WeatherOutputData.RainOutputData;
                mRainMat.SetFloat(id_RainOpacityInAll, rainOutput.RainOpacityInAll);
                mRainMat.SetColor(id_RainColor, rainOutput.RainColor);
                mRainMat.SetVector(id_RainScale_Layer12, rainOutput.RainScale_Layer12);
                mRainMat.SetVector(id_RainScale_Layer34, rainOutput.RainScale_Layer34);
                mRainMat.SetVector(id_RotateSpeed, rainOutput.RotateSpeed);
                mRainMat.SetVector(id_RotateAmount, rainOutput.RotateAmount);
                mRainMat.SetVector(id_DropSpeed, rainOutput.DropSpeed);
                mRainMat.SetVector(id_RainOpacities, rainOutput.RainOpacity);
            }
            else
            {
                mRainMat.SetFloat(id_RainIntensity, RainIntensity);
                mRainMat.SetFloat(id_RainOpacityInAll, RainOpacityInAll);
                mRainMat.SetColor(id_RainColor, RainColor);
                mRainMat.SetVector(id_RainScale_Layer12, new Vector4(RainScale_One.x, RainScale_One.y, RainScale_Two.x, RainScale_Two.y));
                mRainMat.SetVector(id_RainScale_Layer34, new Vector4(RainScale_Three.x, RainScale_Three.y, RainScale_Four.x, RainScale_Four.y));
                mRainMat.SetVector(id_RotateSpeed, new Vector4(RotateSpeed_One, RotateSpeed_Two, RotateSpeed_Three, RotateSpeed_Four));
                mRainMat.SetVector(id_RotateAmount, new Vector4(RotateAmount_One, RotateAmount_Two, RotateAmount_Three, RotateAmount_Four));
                mRainMat.SetVector(id_DropSpeed, new Vector4(DropSpeed_One, DropSpeed_Two, DropSpeed_Three, DropSpeed_Four));
                mRainMat.SetVector(id_RainOpacities, new Vector4(RainOpacity_One, RainOpacity_Two, RainOpacity_Three, RainOpacity_Four));
            }
        }
    }

    void UpdateRainSplash()
    {
        if(EnableRainSplash)
        {
            if (mRainMat != null)
            {
                mRainMat.SetTexture(id_RainSplashTex, RainSplashTex);
                mRainMat.SetVector(id_GlobalSplashInfo, new Vector4(SplashTexCol, 1.0f / SplashTexCol, 1.0f / SplashTexRow, 0.0f));
            }

            if (splashInfo_1 == null || splashInfo_1.Length != SplashCountMax)
            {     
                if(splashInfo_1 == null)
                {
                    splashInfo_1 = new Vector4[SplashCountMax];
                    splashInfo_2 = new float[SplashCountMax];
                    splashLifeData = new Vector3[SplashCountMax];
                }
                else
                {
                    System.Array.Resize(ref splashInfo_1, SplashCountMax);
                    System.Array.Resize(ref splashInfo_2, SplashCountMax);
                    System.Array.Resize(ref splashLifeData, SplashCountMax);
                }

                splashMatrix = new Matrix4x4[SplashCountMax];
                for (int i = 0; i < SplashCountMax; i++)
                {
                    splashMatrix[i] = Matrix4x4.identity;
                }
            }

            Vector3 splashData_1;
            Vector4 splashData_2;
            int actualSplashCount;

            if (weatherCtrl != null && weatherCtrl.WeatherOutputData != null)
            {
                RainOutput rainOutput = weatherCtrl.WeatherOutputData.RainOutputData;
                splashData_1 = rainOutput.SplashData_1;
                splashData_2 = rainOutput.SplashData_2;

                actualSplashCount = Mathf.RoundToInt(SplashCountMax * rainOutput.RainIntensity);
            }
            else
            {
                splashData_1.x = SplashIntervalMin;
                splashData_1.y = SplashIntervalMax;
                splashData_1.z = SplashPlayTime;

                splashData_2.x = SplashScaleMin;
                splashData_2.y = SplashScaleMax;
                splashData_2.z = SplashOpacityMin;
                splashData_2.w = SplashOpacityMax;

                actualSplashCount = Mathf.RoundToInt(SplashCountMax * RainIntensity);
            }

            Vector3 campos = Camera.main.transform.position;
            int frameCount = SplashTexRow * SplashTexCol;
            for (int i = 0; i < SplashCountMax; i++)
            {
                if (splashLifeData[i].y >= splashLifeData[i].x)
                {
                    if(i < actualSplashCount)
                    {
                        splashLifeData[i].x = Random.Range(splashData_1.x, splashData_1.y) + splashData_1.z;
                        splashLifeData[i].y = 0f;
                        splashLifeData[i].z = Random.Range(splashData_2.x, splashData_2.y);

                        Vector2 pos = Random.insideUnitCircle * RainSplashRadius;
                        splashInfo_1[i].x = pos.x + campos.x;
                        splashInfo_1[i].y = pos.y + campos.z;
                        splashInfo_1[i].w = 0f;
                        splashInfo_2[i] = Random.Range(splashData_2.z, splashData_2.w);
                    }
                    else
                    {
                        splashInfo_2[i] = 0f;
                    }
                }
                else
                {
                    if(splashLifeData[i].y > splashData_1.z)
                    {
                        splashInfo_2[i] = 0f;
                    }
                    else
                    {
                        float p = splashLifeData[i].y / splashData_1.z;
                        splashInfo_1[i].z = p * splashLifeData[i].z;
                        splashInfo_1[i].w = (int)(p * frameCount);
                    }
                    splashLifeData[i].y += Time.deltaTime;
                }
            }
        }
    }

    void UpdateRainRipple()
    {
        if(EnableRaindrop)
        {
            Shader.EnableKeyword("RAIN");
        }
        else
        {
            Shader.DisableKeyword("RAIN");
        }
    }

    void UpdateWetAndAccumulatedWater()
    {
        float rainIntensity;
        float maxWetLevel;
        float maxGapFloodLevel;
        float maxPuddleFloodLevel;

        if (weatherCtrl != null && weatherCtrl.WeatherOutputData != null)
        {
            RainOutput rainOutput = weatherCtrl.WeatherOutputData.RainOutputData;
            rainIntensity = rainOutput.RainIntensity;
            maxWetLevel = rainOutput.WetData.x;
            maxGapFloodLevel = rainOutput.WetData.y;
            maxPuddleFloodLevel = rainOutput.WetData.z;
        }
        else
        {
            rainIntensity = RainIntensity;
            maxWetLevel = MaxWetLevel;
            maxGapFloodLevel = MaxGapFloodLevel;
            maxPuddleFloodLevel = MaxPuddleFloodLevel;
        }

        if (rainIntensity == 0f)
        {
            if(rainState == RainState.raining)
            {
                rainStopTime = Time.time;
                rainState = RainState.stop;
            }
        }
        else
        {
            if(rainState == RainState.stop)
            {
                rainState = RainState.raining;
            }
        }

        //maxWetLevel = Mathf.Max(wetLevel, maxWetLevel);
        //maxGapFloodLevel = Mathf.Max(floodLevel.x, maxGapFloodLevel);
        //maxPuddleFloodLevel = Mathf.Max(floodLevel.y, maxPuddleFloodLevel);

        if (rainState == RainState.raining)
        {
            if (wetLevel < maxWetLevel)
            {
                wetLevel += WetTime <= 0f ? 1f : rainIntensity * Time.deltaTime / WetTime;
            }
            else if (wetLevel > maxWetLevel)
            {
                wetLevel -= DryTime <= 0f ? 1f : Time.deltaTime / DryTime;
            }

            if (floodLevel.x < maxGapFloodLevel)
            {
                floodLevel.x += GapAccumulatedWaterTime <= 0f ? 1f : rainIntensity * Time.deltaTime / GapAccumulatedWaterTime;
            }
            else if (floodLevel.x > maxGapFloodLevel)
            {
                floodLevel.x -= GapWaterRemoveTime <= 0f ? 1 : Time.deltaTime / GapWaterRemoveTime;
            }

            if (floodLevel.y < maxPuddleFloodLevel)
            {
                floodLevel.y += PuddleAccumulatedWaterTime <= 0f ? 1f : rainIntensity * Time.deltaTime / PuddleAccumulatedWaterTime;
            }
            else if (floodLevel.y > maxPuddleFloodLevel)
            {
                floodLevel.y -= PuddleWaterRemoveTime <= 0f ? 1 : Time.deltaTime / PuddleWaterRemoveTime;
            }
        }
        else
        {
            if(wetLevel > 0) wetLevel -= DryTime <= 0f ? 1f : Time.deltaTime / DryTime;
            float timeDuartion = Time.time - rainStopTime;
            if (timeDuartion > GapWaterRemainTime && floodLevel.x > 0)
            {
                floodLevel.x -= GapWaterRemoveTime <= 0f ? 1 : Time.deltaTime / GapWaterRemoveTime;
            }
            if(timeDuartion > PuddleWaterRemainTime && floodLevel.y > 0)
            {
                floodLevel.y -= PuddleWaterRemoveTime <= 0f ? 1 : Time.deltaTime / PuddleWaterRemoveTime;
            }
        }

        wetLevel = Mathf.Clamp01(wetLevel);
        floodLevel.x = Mathf.Clamp01(floodLevel.x);
        floodLevel.y = Mathf.Clamp01(floodLevel.y);

        Shader.SetGlobalFloat(id_WetLevel, wetLevel);
        Shader.SetGlobalVector(id_FloodLevel, floodLevel);
    }

    void DisposeCreatedRes()
    {
        if (mRainMat != null)
        {
            SafeDestory(mRainMat);
        }
    }

    void SafeDestory(Object obj)
    {
#if UNITY_EDITOR
        Object.DestroyImmediate(obj);
#else
        Object.Destroy(obj);
#endif
    }
}
