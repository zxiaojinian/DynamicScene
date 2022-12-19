Shader "Code Repository/Scene/Stylized Dynamic Sky" 
{
	Properties 
	{
    	[HDR]_TopColor ("TopColor", Color) = (0, 0.2, 0.7, 1)		
		[HDR]_MiddleColor ("MiddleColor", Color) = (0.15, 0.45, 0.9, 1)
		[HDR]_BottomColor ("BottomColor", Color) = (0.65, 0.85, 0.9, 1)
		_MiddleHeight ("MiddleHeight", Range(0, 1)) = 0.2
		_HorizonHeight ("HorizonHeight", Range(0, 1)) = 0.1

		[NoScaleOffset]_SunTex ("SunTex", 2D) = "white" {}
		[Toggle(_SIMULATIONSUNSHAPE)] _SimulationSunShape ("SimulationSunShape", Float) = 1
		[HDR]_SunColor ("SunColor", Color) = (1, 1, 1, 1)
		_SunSize ("SunSize", Float) = 5		
		[HDR]_SunGlowColor ("SunGlowColor", Color) = (1, 1, 1, 1)
		_SunGlowRadius ("SunGlowRadius", Range(0, 1)) = 0.5
		_SunIntensity ("SunIntensity", Range(0, 1)) = 1

		[NoScaleOffset]_MoonTex ("MoonTex", 2D) = "white" {}
		[HDR]_MoonColor ("MoonColor", Color) = (1, 1, 1, 1)
		_MoonSize ("MoonSize", Float) = 5
		[HDR]_MoonGlowColor ("MoonGlowColor", Color) = (1, 1, 1, 1)
		_MoonGlowRadius ("MoonGlowRadius", Range(0, 1)) = 0.5
		_MoonIntensity ("MoonIntensity", Range(0, 1)) = 1

		_StarTex ("StarTex", 2D) = "white" {}
		_StarIntensity ("StarIntensity", Float) = 3
		_StarReduceValue ("StarReduceValue", Range(0, 1)) = 0.1
	}
	SubShader 
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "PreviewType" = "Skybox" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			half3 _TopColor;	
			half3 _MiddleColor;
			half3 _BottomColor;
			half _MiddleHeight;
			half _HorizonHeight;

			half3 _SunColor;
			float _SunSize;
			half3 _SunGlowColor;
			float _SunGlowRadius;
			half _SunIntensity;

			half3 _MoonColor;
			float _MoonSize;
			half3 _MoonGlowColor;
			float _MoonGlowRadius;
			half _MoonIntensity;
			half _StarIntensity;
			float4 _StarTex_ST;
			half _StarReduceValue;
			CBUFFER_END

			half _IsNight;
			float4x4 _LightMatrix;

			// TEXTURE2D(_SkyColorTex);
			// SAMPLER(sampler_SkyColorTex);

			TEXTURE2D(_SunTex);	
			SAMPLER(sampler_SunTex);

			TEXTURE2D(_MoonTex);
			SAMPLER(sampler_MoonTex);

			TEXTURE2D(_StarTex);
			SAMPLER(sampler_StarTex);	
			
			half pow2(half v)
			{
				return v * v;
			}
		ENDHLSL

		Pass 
		{
			ZWrite Off 
			Cull Off
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			#pragma shader_feature_local _SIMULATIONSUNSHAPE
			#pragma multi_compile _ _NIGHT

			struct Attributes 
			{
				float4 positionOS : POSITION;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 viewDirWS : TEXCOORD0;
				float4 sunAndMoonUV : TEXCOORD1;
				float3 positionOS : TEXCOORD3;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);		
				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);		
				OUT.viewDirWS = positionWS - _WorldSpaceCameraPos.xyz;
				float3 posInLight = mul((float3x3)_LightMatrix, normalize(OUT.viewDirWS));
				OUT.sunAndMoonUV.xy = (posInLight * _SunSize).xy;
				OUT.sunAndMoonUV.zw = (posInLight * _MoonSize).xy;
				OUT.positionOS = IN.positionOS.xyz;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float3 viewDirWS = normalize(IN.viewDirWS);
				float skyHeight = saturate(viewDirWS.y);
				half middleHeight = _MiddleHeight + 0.0001;
				half3 skyColor = lerp(_BottomColor, _MiddleColor, pow(saturate(skyHeight / middleHeight), _HorizonHeight + 0.0001));
				skyColor = lerp(skyColor, _TopColor, pow2(saturate(saturate(skyHeight - middleHeight) / (1 - middleHeight))));

				#if !defined(_NIGHT)
					//sun				
					float glowRadius = 1.0 + dot(viewDirWS, -_MainLightPosition.xyz); //[0, 2]
					float lightRange = saturate(dot(viewDirWS, _MainLightPosition.xyz));  //消除另一面
					float sunGlow = 1.0 / (1 + glowRadius * lerp(150, 10, _SunGlowRadius));
					sunGlow *= pow(_SunGlowRadius, 0.5);

					#if !defined(_SIMULATIONSUNSHAPE)
						float2 sunUV = IN.sunAndMoonUV.xy + 0.5;
						half4 sunTex = SAMPLE_TEXTURE2D(_SunTex, sampler_SunTex, sunUV);
						half3 sunColor = sunTex.rgb * _SunColor;
						half sunShape = sunTex.a * lightRange;
					#else
						half3 sunColor =  _SunColor;
						half sunShape = smoothstep(0.3, 0.25, distance(IN.sunAndMoonUV.xy, float2(0, 0))) * lightRange;
					#endif								
					skyColor = lerp(skyColor, _SunGlowColor, saturate(sunGlow * _SunIntensity));
					skyColor = lerp(skyColor, sunColor, saturate(sunShape * _SunIntensity));
				#else
					//moon
					float glowRadius = 1.0 + dot(viewDirWS, -_MainLightPosition.xyz); //[0, 2]
					float lightRange = saturate(dot(viewDirWS, _MainLightPosition.xyz));
					float moonGlow = 1.0 / (1 + glowRadius * lerp(150, 10, _MoonGlowRadius));
					moonGlow *= pow(_MoonGlowRadius, 0.5);

					float2 moonUV = IN.sunAndMoonUV.zw + 0.5;
					half4 moonTex = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, moonUV);
					half3 moonColor = moonTex.r  * _MoonColor * _MoonIntensity;
					half moonShape = moonTex.a * lightRange;
					moonColor *= moonShape;

					half3 moonGlowColor = _MoonGlowColor * moonGlow * _MoonIntensity;
					//star
					//经纬映射
					float3 posDir = normalize(IN.positionOS);
					float2 starUV = float2(atan2(posDir.z, posDir.x), -acos(posDir.y)) / float2(TWO_PI, PI); //atan2(x,y)=(-pi,pi);acos(x) = (0, pi)
					starUV.x += 0.5;//转到0-1
					starUV = starUV * _StarTex_ST.xy + _StarTex_ST.zw;
					half3 starTex = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, starUV).rgb;
					half3 starColor = saturate(starTex - _StarReduceValue) * _StarIntensity * (1 - moonTex.a);
					skyColor += starColor + moonColor + moonGlowColor;		
				#endif

				return half4(skyColor, 1);
			}
			ENDHLSL
		}
	}
}