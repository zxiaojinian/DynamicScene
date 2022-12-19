
Shader "Code Repository/Scene/Cloud/StylizedCloud2D_Noise_Lighting"
{
	Properties 
	{
		[Header(xxxxxxxxxxxxxxxx Cloud Shape xxxxxxxxxxxxxxxx)]
		[Space]
		[NoScaleOffset]_CloudShapeTex ("CloudShapeTex", 2D) = "white" {}
		_CloudSpeedX ("CloudSpeedX", Float) = 1
		_CloudSpeedY ("CloudSpeedY", Float) = 1
		_CloudSize ("CloudSize", FLoat) = 1
		_CloudFill ("CloudFill", Range(0, 1)) = 0.5
		_CloudFillMax ("CloudFillMax", Float) = 1.0
		_CloudFillMin ("CloudFillMin", Float) = -1.0
		[NoScaleOffset]_CloudEdgeSoftUnevenTex ("CloudEdgeSoftUnevenTex", 2D) = "white" {}
		_CloudEdgeSoftUnevenTexSize ("CloudEdgeSoftUnevenTexSize", Float) = 4
		_CloudEdgeSoftMax ("CloudEdgeSoftMax", Float) = 0.1
		_CloudEdgeSoftMin ("CloudEdgeSoftMin", Float) = 0.01
		_CloudDetailSize ("CloudDetailSize", Float) = 2
		_CloudDetailIntensityFew("CloudDetailIntensityFew", Float) = 0.5
		_CloudDetailIntensity("CloudDetailIntensity", Float) = 0.5

		[Header(xxxxxxxxxxxxxxxx Cloud Color xxxxxxxxxxxxxxxx)]
		[Space]
		[HDR]_CloudColor ("CloudColor", Color) = (1, 1, 1, 1)
		[HDR]_CloudRimColor ("CloudRimColor", Color) = (1, 1, 1, 1)
		[HDR]_CloudLightColor ("CloudLightColor", Color) = (1, 1, 1, 1)
		_CloudRimEdgeSoft ("CloudRimEdgeSoft", Range(0, 1)) = 0.3
		_CloudLightRadius ("CloudLightRadius", Range(0, 1)) = 0.75
		_CloudLightRadiusIntensity ("CloudLightRadiusIntensity", Range(0, 1)) = 1.0
		_CloudLightIntensity ("CloudLightIntensity", Range(0, 1)) = 1.0
		_CloudLightUVOffset ("CloudLightUVOffset", Float) = 0.01
		_CloudHorizonSoft ("CloudHorizonSoft", Range(0, 1)) = 0.2
		_CloudSSSRadius ("CloudSSSRadius", Range(0, 1)) = 0.1
		_CloudSSSIntensity ("CloudSSSIntensity", Range(0, 1)) = 1.0
	}

	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Transparent"
		}

		Pass 
		{
			Name "StylizedCloud2D_Noise_Lighting"
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off

			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma vertex Vertex
			#pragma fragment Fragment

			CBUFFER_START(UnityPerMaterial)
				float _CloudSpeedX;
				float _CloudSpeedY;
				float _CloudSize;
				half _CloudFill;
				half _CloudFillMax;
				half _CloudFillMin;
				float _CloudEdgeSoftUnevenTexSize;
				half _CloudEdgeSoftMax;
				half _CloudEdgeSoftMin;
				float _CloudDetailSize;
				half _CloudDetailIntensityFew;
				half _CloudDetailIntensity;

				half3 _CloudColor;
				half3 _CloudRimColor;				
				half3 _CloudLightColor;
				half _CloudRimEdgeSoft;
				float _CloudLightRadius;
				half _CloudLightRadiusIntensity;
				half _CloudLightIntensity;
				float _CloudLightUVOffset;
				half _CloudHorizonSoft;
				float _CloudSSSRadius;
				half _CloudSSSIntensity;
			CBUFFER_END

			TEXTURE2D(_CloudShapeTex);
			SAMPLER(sampler_CloudShapeTex);
			
			TEXTURE2D(_CloudEdgeSoftUnevenTex);
			SAMPLER(sampler_CloudEdgeSoftUnevenTex);

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				half3 Color			: COLOR;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;				
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float4 uv			: TEXCOORD0;
				float3 viewDirWS	: TEXCOORD1;
				float3 WtoT0		: TEXCOORD2;
				float3 WtoT1		: TEXCOORD3;
				float3 WtoT2		: TEXCOORD4;				
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv.xy = IN.uv * _CloudSize * ((1 - IN.Color.r) * 0.5 + 1); //2层差异
				OUT.uv.zw = (IN.Color.r * 0.5 + 1) * _Time.x * float2(_CloudSpeedX, _CloudSpeedY);
				OUT.viewDirWS = _WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normal);
				float3 tangentWS = TransformObjectToWorldDir(IN.tangent.xyz);
				float3 binormalWS = normalize(cross(normalWS, tangentWS) * IN.tangent.w);
				OUT.WtoT0 = tangentWS;
				OUT.WtoT1 = binormalWS;
				OUT.WtoT2 = normalWS;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				//-------cloud shape
				float2 baseUV = IN.uv.xy;
				float2 cloudSpeed = IN.uv.zw;
				float2 uv_Main = baseUV + cloudSpeed;
				float2 uv_Detail =  baseUV * _CloudDetailSize + cloudSpeed;
				float2 uv_Edge = uv_Main  * _CloudEdgeSoftUnevenTexSize;

				half cloudEdgeSoftUneven = SAMPLE_TEXTURE2D(_CloudEdgeSoftUnevenTex, sampler_CloudEdgeSoftUnevenTex, uv_Edge).r; //边缘软硬程度有变化
				cloudEdgeSoftUneven = pow(cloudEdgeSoftUneven, 4);
				half edgeSmooth = lerp(_CloudEdgeSoftMin, _CloudEdgeSoftMax, cloudEdgeSoftUneven);
				half edgeSmoothMin = saturate(0.5 - edgeSmooth);
				half edgeSmoothMax = saturate(0.5 + edgeSmooth);
				half cloudFillValue = lerp(_CloudFillMin, _CloudFillMax, _CloudFill);

				half cloudMainShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Main).r;
				half cloudDetailShape = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_Detail).r; //边缘细节云
				half detailIntensity = lerp(_CloudDetailIntensityFew * _CloudDetailIntensity, _CloudDetailIntensity, _CloudFill);
				half detailLerp = (1 - abs(cloudMainShape - 0.5) * 2) * detailIntensity;
				detailLerp = saturate(detailLerp);
				half cloudShape = lerp(cloudMainShape, cloudDetailShape, detailLerp); //主体+细节
				cloudShape = saturate(cloudShape + cloudFillValue);
				half cloudFinalShape = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShape);


				//-------cloud color
				float3 viewDirWS = normalize(IN.viewDirWS);
				float3 sunDir = -_MainLightPosition.xyz;
				float VDotL = dot(viewDirWS, sunDir);

				//Rim Color
				half rimColorAera = smoothstep(saturate(0.5 - _CloudRimEdgeSoft), saturate(0.5 + _CloudRimEdgeSoft), 1 - cloudShape);
				half3 rimColor = lerp(_CloudColor, _CloudRimColor, rimColorAera);

				//Bright Color
				half3 brightColorColor = _CloudLightColor;
				//Bright Area
				float2 uvOffset = mul(float3x3(IN.WtoT0, IN.WtoT1, IN.WtoT2), normalize(viewDirWS - sunDir)).xy;
				uvOffset = uvOffset * (1.0 - smoothstep(0.55, 1.0, VDotL)) * _CloudLightUVOffset; //距sun越远，亮部越宽
				float2 uv_MainBright = uv_Main + uvOffset; //uv偏移
				half cloudMainShapeBright = SAMPLE_TEXTURE2D(_CloudShapeTex, sampler_CloudShapeTex, uv_MainBright).r;
				half detailLerpBright = (1 - abs(cloudMainShapeBright - 0.5) * 2) * detailIntensity;
				detailLerpBright = saturate(detailLerpBright);
				half cloudShapeBright = lerp(cloudMainShapeBright, cloudDetailShape, detailLerpBright);
				cloudShapeBright  = saturate(cloudShapeBright + cloudFillValue);
				half cloudFinalShapeBright = smoothstep(edgeSmoothMin, edgeSmoothMax, cloudShapeBright);
				half cloudBrightArea = saturate(cloudFinalShape - cloudFinalShapeBright);//亮部区域

				//Cloud LightedColor
				half3 cloudLightedColor = lerp(rimColor, brightColorColor, cloudBrightArea);

				//Cloud SSS
				float thickness = cloudFinalShape;
				thickness = saturate(Pow4(thickness) - 0.3);
				float sssArea = smoothstep(1.0 - _CloudSSSRadius, 1.0, VDotL) * (1.0 - step(_CloudSSSRadius, 0.0));
				sssArea = Pow4(sssArea);
				cloudLightedColor = lerp(cloudLightedColor, _CloudRimColor * 2.0, sssArea  * (1.0 - thickness) * saturate(_CloudSSSIntensity));

				//Cloud final Color
				float lightArea = smoothstep(1.0 - _CloudLightRadius, 1.0, VDotL) * (1.0 - step(_CloudLightRadius, 0.0));//受光区域
				lightArea = saturate((Pow4(lightArea) * _CloudLightRadiusIntensity + 0.2) * _CloudLightIntensity);
				half3 cloudColor = lerp(_CloudColor, cloudLightedColor, lightArea);

				//Horizon Fog
				half VDotDown = saturate(dot(viewDirWS, float3(0.0, -1.0, 0.0)));
				half cloudAlpha = smoothstep(0.0, _CloudHorizonSoft, VDotDown) * cloudFinalShape;

				return half4(cloudColor, cloudAlpha);
			}
			ENDHLSL
		}
	}
}
