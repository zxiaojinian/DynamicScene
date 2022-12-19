Shader "Code Repository/Scene/StylizedWater"
{
	Properties 
	{
		[Header(NormalMap)]
		[NoScaleOffset]_NormalMap ("Normal Map", 2D) = "white" {}
		_NormalMapScale ("NormalMapScale", Float) = 10
		_BumpScale ("Bump Scale", Range(0, 2)) = 1
		_FlowSpeed ("Flow Speed", Float) = 2

		[Header(Water Color)]
		_ShallowColor ("Shallow Color", Color) = (1, 1, 1, 0.1)
		_DepthColor ("DepthColor", Color) = (1, 1, 1, 1)
		_DepthRange ("DepthRange", Float) = 5
		_EdgeFade("EdgeFade", Range(0.0001, 0.5)) = 0.1
		_ShadowStrength ("ShadowStrength", Range(0, 1)) = 0.5

		[Header(Specular)]
		_SpecularScale ("SpecularScale", Range(0, 1)) = 1
		_SpecularIntensity ("SpecularIntensity", Float) = 1
		_SpecularPerturbation ("SpecularPerturbation", Range(0.0, 1.0)) = 1.0

		[Header(Reflection)]
		_ReflectionDistortion ("ReflectionDistortion", Range(0, 1)) = 0.2
		_ReflectionBlur ("ReflectionBlur", Range(0, 0.5)) = 0.0
		_ReflectionIntensity ("ReflectionIntensity", Range(0, 1)) = 0.5
		_FresnelPower ("ReflectionIntensityBaseView", Float) = 5

		[Header(Refraction)]
		_RefractionDistortion ("RefractionDistortion", Range(0, 1)) = 0.2

		[Header(Caustics)]
		[NoScaleOffset]_CausticsTex ("CausticsTex", 2D) = "white" {}
		_CausticsScale ("CausticsScale", Float) = 1
		_CausticsFlowSpeed ("CausticsFlowSpeed", Float) = 1
		_CausticsIntensity ("CausticsIntensity", Float) = 1
		_CausticsThresholdDepth ("CausticsThresholdDepth", Float) = 2
		_CausticsSoftDepth ("CausticsSoftDepth", Float) = 0.5
		_CausticsThresholdShallow ("CausticsThresholdShallow", Float) = 0.1
		_CausticsSoftShallow ("CausticsSoftShallow", Float) = 0.1

		[Header(Shore)]
		_ShoreEdgeWidth ("ShoreEdgeWidth", Float) = 5
		_ShoreEdgeIntensity ("ShoreEdgeIntensity", Range(0, 1)) = 0.3

		[Header(Foam)]
		_FoamColor ("FomaColor", Color) = (1, 1, 1, 1)
		_FoamRange ("FoamRange", Float) = 1
		_FoamRangeSmooth ("_FoamRangeSmooth", Float) = 0
		_FoamSoft ("FoamSoft", Range(0, 1)) = 0.1
		_FoamWavelength ("FoamWavelength", Float) = 1
		_FoamWaveSpeed ("FoamWaveSpeed", Float) = 1
		[NoScaleOffset]_FoamNoiseTex ("FoamNoiseTex", 2D) = "white" {}
		_FoamNoiseTexScale("FoamNoiseTexScale", Vector) = (10, 5, 0, 0)
		_FoamDissolve ("FoamDissolve", Float) = 1.2
		_FoamShoreWidth ("FoamShoreWidth", Range(0, 1)) = 0.5

		[Header(Wave(xy dir z steepness w wavelength))]
		[Space(10)]
		_WaveA ("Wave A", Vector) = (1,0,0.5,10)
		_WaveB ("Wave B", Vector) = (0,1,0.25,20)
		_WaveC ("Wave C", Vector) = (1,1,0.15,10)
		_AttenuationDistance ("AttenuationDistance", Float) = 100
		_AttenuationSmooth ("AttenuationSmooth", Float) = 10
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/Scene/StylizedScene/Weather/Rain/Shader/RianInclude.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float _NormalMapScale;
			half _BumpScale;
			half _FlowSpeed;
			half4 _ShallowColor;
			half4 _DepthColor;
			float _DepthRange;
			float _EdgeFade;
			float _FresnelPower;
			half _ShadowStrength;
			half _SpecularScale;
			half _SpecularIntensity;
			half _SpecularPerturbation;
			float _ReflectionDistortion;
			half _ReflectionBlur;
			half _ReflectionIntensity;
			float _RefractionDistortion;
			float _CausticsScale;
			float _CausticsFlowSpeed;
			float _CausticsIntensity;
			float _CausticsThresholdDepth;
			float _CausticsSoftDepth;
			float _CausticsThresholdShallow;
			float _CausticsSoftShallow;
			float _ShoreEdgeWidth;
			float _ShoreEdgeIntensity;
			half4 _FoamColor;
			float _FoamRange;
			float _FoamRangeSmooth;
			float _FoamSoft;
			float _FoamWavelength;
			float _FoamWaveSpeed;
			float2 _FoamNoiseTexScale;
			float _FoamDissolve;
			float _FoamShoreWidth;
			float4 _WaveA, _WaveB, _WaveC;
			float _AttenuationDistance;
			float _AttenuationSmooth;
			CBUFFER_END

			//https://catlikecoding.com/unity/tutorials/flow/waves/
			//https://zhuanlan.zhihu.com/p/404778222
			float3 GerstnerWave (float4 wave, float3 p, inout float3 tangent, inout float3 bitangent) 
			{
				float steepness = wave.z;
				float wavelength = wave.w;
				float k = TWO_PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, p.xz) - c * _Time.y);
				float a = steepness / k;
				
				tangent += float3(
					-d.x * d.x * (steepness * sin(f)),
					d.x * (steepness * cos(f)),
					-d.x * d.y * (steepness * sin(f))
				);
				bitangent += float3(
					-d.x * d.y * (steepness * sin(f)),
					d.y * (steepness * cos(f)),
					-d.y * d.y * (steepness * sin(f))
				);
				return float3(
					d.x * (a * cos(f)),
					a * sin(f),
					d.y * (a * cos(f))
				);
			}
		ENDHLSL

		Pass 
		{
			Name "StylizedWater"

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			//Unity global keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

			#pragma multi_compile _ RAIN

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float3 normal		: NORMAL;
				float4 tangent		: TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float4 TtoW0			: TEXCOORD0;
				float4 TtoW1			: TEXCOORD1;
				float4 TtoW2			: TEXCOORD2;
				float4 normalMapUv		: TEXCOORD3;
				float4 posWSFromDepth	: TEXCOORD4; //xyz:viewDirWS,w:viewPosZ

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) //No shadow cascades
				float4 shadowCoord 		: TEXCOORD5;
				#endif
				float4 positionSS		: TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID

			};

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);

			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);
			//SAMPLER(sampler_point_clamp);

			TEXTURE2D(_CausticsTex);
			SAMPLER(sampler_CausticsTex);

			TEXTURE2D(_FoamNoiseTex);
			SAMPLER(sampler_FoamNoiseTex);

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal, IN.tangent);
				float3 normalWSVertex = normalInput.normalWS;
				float3 tangentWSVertex = normalInput.tangentWS;
				float3 bitangentWSVertex = normalInput.bitangentWS;

				float3 tangentWS = tangentWSVertex;
				float3 bitangentWS = bitangentWSVertex;
				float3 offset = 0.0;
				float d = distance(posWS, _WorldSpaceCameraPos);
				float attenuation = smoothstep(_AttenuationDistance + _AttenuationSmooth, _AttenuationDistance - 1, d);
				_WaveA.z *= attenuation;
				_WaveB.z *= attenuation;
				_WaveC.z *= attenuation;
				offset += GerstnerWave(_WaveA, posWS, tangentWS, bitangentWS);
				offset += GerstnerWave(_WaveB, posWS, tangentWS, bitangentWS);
				offset += GerstnerWave(_WaveC, posWS, tangentWS, bitangentWS);

				posWS += offset;
				OUT.positionCS = TransformWorldToHClip(posWS);

				tangentWS = normalize(tangentWS);
				bitangentWS = normalize(bitangentWS);
				float3 normalWS = normalize(cross(bitangentWS, tangentWS));

				OUT.TtoW0 = float4(tangentWS.x, bitangentWS.x, normalWS.x, posWS.x);
				OUT.TtoW1 = float4(tangentWS.y, bitangentWS.y, normalWS.y, posWS.y);
				OUT.TtoW2 = float4(tangentWS.z, bitangentWS.z, normalWS.z, posWS.z);

				float2 normalUV0 = posWS.xz / max(0.0001, _NormalMapScale) + _Time.x * _FlowSpeed;
				float2 normalUV1 = 2 * posWS.xz / max(0.0001, _NormalMapScale) - _Time.x * _FlowSpeed * 0.5;
				OUT.normalMapUv.xy = normalUV0;
				OUT.normalMapUv.zw = normalUV1;

				OUT.posWSFromDepth.xyz = posWS - _WorldSpaceCameraPos;
				OUT.posWSFromDepth.w = -TransformWorldToView(posWS).z;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					OUT.shadowCoord = TransformWorldToShadowCoord(posWS);
				#endif
				OUT.positionSS = ComputeScreenPos(OUT.positionCS);
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				float2 screenUV = IN.positionSS.xy / IN.positionSS.w;
				float3 posWS = float3(IN.TtoW0.w, IN.TtoW1.w, IN.TtoW2.w);
				half3 waveNormal = normalize(half3(IN.TtoW0.z, IN.TtoW1.z, IN.TtoW2.z)); //采样法线贴图前的法线
				half3 viewDirWS = SafeNormalize(-IN.posWSFromDepth.xyz);
				float viewDis = distance(posWS, _WorldSpaceCameraPos.xyz);
				half3 upNormal = half3(0.0, 1.0, 0.0);

				//normal map
				float2 normalUV0 = IN.normalMapUv.xy;
				half4 packNormal0 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV0);
				half3 unpackNormal0 = UnpackNormalScale(packNormal0, _BumpScale);
				float2 normalUV1 = IN.normalMapUv.zw;
				half4 packNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV1);
				half3 unpackNormal1 = UnpackNormalScale(packNormal, _BumpScale);
				half3 normalTS = float3(unpackNormal0.xy + unpackNormal1.xy, unpackNormal0.z * unpackNormal1.z); //http://wiki.amplify.pt/index.php?title=Unity_Products:Amplify_Shader_Editor/Blend_Normals
				//ripple
				half3 rippleNormalTS = SampleRippleNormalTexture(posWS.xz * 0.05);
				normalTS = float3(rippleNormalTS.xy + normalTS.xy, rippleNormalTS.z * normalTS.z);
				half3 normalWS = SafeNormalize(float3(dot(IN.TtoW0.xyz, normalTS), dot(IN.TtoW1.xyz, normalTS), dot(IN.TtoW2.xyz, normalTS)));

				//scene pos
				float sceneDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
				sceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);				
				float3 sceneViewDirWS = sceneDepth / IN.posWSFromDepth.w * IN.posWSFromDepth.xyz; //sceneViewDirWS/viewDirWS = sceneDepth / viewPosZ,相似三角形
				float3 scenePosWS = _WorldSpaceCameraPos + sceneViewDirWS;
				//water depth difference
				float depthDifference = posWS.y - scenePosWS.y;
		
				//water base color
				float waterFog = saturate(exp(-depthDifference * _DepthRange * 0.1));
				half4 baseColor = lerp(_DepthColor, _ShallowColor, waterFog);
				half3 albedoColor = baseColor.rgb;

				//shore
				half shoreEdge = smoothstep(_ShoreEdgeWidth * 0.01, 0, depthDifference) * _ShoreEdgeIntensity;
				albedoColor = lerp(albedoColor, 1.0, shoreEdge);

				//foam
				float foamRange = 1 - saturate(depthDifference / max(0.0001, _FoamRange));
				float foamMask = smoothstep(0, _FoamRangeSmooth, foamRange);
				float foamWave = sin(TWO_PI / max(_FoamWavelength * 0.1, 0.0001) * (depthDifference + _Time.x * _FoamWaveSpeed));
				half foamNoise = SAMPLE_TEXTURE2D(_FoamNoiseTex, sampler_FoamNoiseTex, posWS.xz / _FoamNoiseTexScale).r;
				float foamThreshold = max(foamRange - _FoamShoreWidth, 0);
				foamWave = smoothstep(foamThreshold, foamThreshold + _FoamSoft, foamWave + foamNoise - _FoamDissolve);
				foamMask *= foamWave;
				albedoColor = lerp(albedoColor, _FoamColor.rgb, foamMask);

				//water diffuse color
				float fomaArea = saturate(foamMask + shoreEdge);
				half3 diffuseNormal = lerp(normalWS, waveNormal, fomaArea);//泡沫处不采用法线贴图
				float4 shadowCoords = 0.0;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					shadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					shadowCoords = TransformWorldToShadowCoord(posWS);
				#endif
				Light mainLight = GetMainLight(shadowCoords, posWS, 1.0);
				mainLight.shadowAttenuation = lerp(1.0, mainLight.shadowAttenuation, _ShadowStrength);
				half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
				half NdotL = dot(diffuseNormal, mainLight.direction) * 0.5 + 0.5;
				half3 diffuseColor = albedoColor * attenuatedLightColor * NdotL;

				//water specular color
				half3 halfDir = SafeNormalize(_MainLightPosition.xyz + viewDirWS);
				half NdotH = max(0, dot(lerp(upNormal, normalWS, _SpecularPerturbation), halfDir));
				half3 specularColor = attenuatedLightColor * pow(NdotH, lerp(8196, 64, _SpecularScale)) * _SpecularIntensity * (1.0 - fomaArea);

				//water gi
				// diffuse
				half3 indirectLight = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
				half3 indirectDiffuse = albedoColor *  indirectLight;

				//indirectSpecular(reflection)
				half3 reflectionNormal = lerp(waveNormal, normalize(waveNormal + normalWS), _ReflectionDistortion);
				half3 reflectionVector = reflect(-viewDirWS, reflectionNormal);
				half3 reflectionColor = GlossyEnvironmentReflection(reflectionVector, _ReflectionBlur, 1.0).rgb;
				//float fresnel = pow(1 - saturate(dot(reflectionNormal, viewDirWS)), _FresnelPower);
				float fresnel = pow(1 - saturate(dot(upNormal, viewDirWS)), _FresnelPower);
				fresnel = pow(1 - saturate(dot(lerp(reflectionNormal, upNormal, fresnel), viewDirWS)), _FresnelPower);//使远处反射平缓
				half reflectionIntensity = _ReflectionIntensity * fresnel * (1.0 - fomaArea);
				half3 indirectSpecular = reflectionIntensity * reflectionColor;

				//refraction
				float2 distortionOffset = normalTS.xy * _RefractionDistortion * 0.1;
				float2 refractionUV = screenUV + distortionOffset;
				float distortionDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, refractionUV).r;
				distortionDepth = LinearEyeDepth(distortionDepth, _ZBufferParams);
				float waterDepth = IN.positionSS.w;
				float distortionDepthDifference = saturate(distortionDepth - waterDepth);
				refractionUV = screenUV + distortionOffset * distortionDepthDifference; //水面及以上的物体不会被扭曲
				half3 refractionColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, refractionUV).rgb;

				//caustics
				float2 causticsUVOffset = _Time.x * _CausticsFlowSpeed;
				float2 causticsUV0 = scenePosWS.xz / max(0.0001, _CausticsScale) + causticsUVOffset;
				float2 causticsUV1 = -scenePosWS.xz / max(0.0001, _CausticsScale) + causticsUVOffset;
				half3 causticsColor0 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, causticsUV0).rgb;
				half3 causticsColor1 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, causticsUV1).rgb;
				half3 causticsColor = min(causticsColor0, causticsColor1) * max(0, _CausticsIntensity);

				half causticsDepthMask = smoothstep(_CausticsThresholdDepth, _CausticsThresholdDepth - _CausticsSoftDepth - 0.1, depthDifference);
				half causticsShalloowMask = smoothstep(_CausticsThresholdShallow, _CausticsThresholdShallow + _CausticsSoftShallow, depthDifference);
				half causticsMask =  causticsDepthMask + causticsShalloowMask - 1;
				half causticsAttentuation = saturate((_MainLightColor.a * mainLight.distanceAttenuation * mainLight.shadowAttenuation - 0.5) * 2.0);
				causticsColor *= causticsMask * causticsAttentuation;

				//final color
				half3 waterSurfaceColor = (1.0 - reflectionIntensity) * (diffuseColor + indirectDiffuse) + indirectSpecular;
				half3 underWaterColor = refractionColor + causticsColor;
				half3 finalColor = lerp(underWaterColor, waterSurfaceColor, saturate(lerp(1.0 - waterFog, 1.0, fresnel) + fomaArea)) + specularColor;
				half edgeArea = saturate(depthDifference / _EdgeFade);
				finalColor = lerp(underWaterColor, finalColor, edgeArea);
				return half4(finalColor, 1.0);
			}
			ENDHLSL
		}

		Pass 
		{
			Name "BakeHeight"
			Tags{"LightMode" = "BakeHeight"}

			HLSLPROGRAM
			#pragma vertex BakeHeightVertex
			#pragma fragment BakeHeightFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

			#include "Assets/Scene/BakeSceneHeight/Shader/BakeHeight.hlsl"

			struct Attributes
			{
				float4 position     : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float3 positionWS   : TEXCOORD0;
				float4 positionCS   : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings BakeHeightVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);

				output.positionWS = TransformObjectToWorld(input.position.xyz);
				output.positionCS = TransformWorldToHClip(output.positionWS);
				return output;
			}

			half4 BakeHeightFragment(Varyings input) : SV_TARGET
			{
				return PackHeightmapR(input.positionWS);
			}

			ENDHLSL
		}
	}
}
