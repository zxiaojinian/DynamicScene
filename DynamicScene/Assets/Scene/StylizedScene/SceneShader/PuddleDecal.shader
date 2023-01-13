Shader "Code Repository/Scene/PuddleDecal" 
{
	Properties 
	{
        _BaseColor("Base Color", Color) = (0, 0, 0, 1)
		_FresnelPower ("ReflectionIntensityBaseView", Float) = 5
		_Smoothness ("Edge Smoothness", Range(0, 1)) = 0.5
		_PuddleDepth ("PuddleDepth", 2D) = "black" {}
		_PuddleEdgeWidth ("PuddleEdgeWidth", Range(0.01, 1)) = 0.4
		_PuddleClear ("PuddleClear", Range(0.01, 1)) = 0.5
		_PuddleLevel ("PuddleLevel", Range(0, 1)) = 1
		[Toggle(GLOBALLEVEL)] _GlobalLevel ("GlobalLevel", Float) = 1

		[Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", Float) = 0.0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("CullMode", Float) = 2.0
	}
	SubShader 
	{
		Tags{"Queue" = "Geometry+100"  "IgnoreProjector" = "True"}

		Pass 
		{
			Tags { "LightMode"="UniversalForward" }
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
			ZTest[_ZTest]
            Cull[_Cull]

			HLSLPROGRAM
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _  _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _SHADOWS_SOFT

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

			#pragma multi_compile _ RAIN
			#pragma shader_feature_local GLOBALLEVEL

			#define _SPECULAR_SETUP

			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/Scene/StylizedScene/Weather/Rain/Shader/RianInclude.hlsl"

			struct Attributes
			{
				float4 positionOS   : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 screenPos				: TEXCOORD0;
				float4 positionCS               : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _BaseColor;
			float _FresnelPower;
			half _Smoothness;
			half _PuddleEdgeWidth;
			half _PuddleClear;
			half _PuddleLevel;
			CBUFFER_END

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_PuddleDepth);
			SAMPLER(sampler_PuddleDepth);

			Varyings Vertex(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);

				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				output.screenPos = ComputeScreenPos(output.positionCS);
				return output;
			}


			half4 Fragment(Varyings input) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);

				float2 screenPos = input.screenPos.xy / input.screenPos.w;
				float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				#if defined(UNITY_REVERSED_Z)
					depth = 1 - depth;
				#endif
				float4 clipPos = float4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, depth * 2 - 1, 1);
				float4 cameraSpacePos = mul(unity_CameraInvProjection, clipPos);
				float4 worldSpacePos = mul(unity_MatrixInvV, cameraSpacePos);
				worldSpacePos /= worldSpacePos.w;

				float3 posOS = mul(unity_WorldToObject, worldSpacePos).xyz;
				float2 uv = posOS.xz + 0.5;
				half puddleDepth = SAMPLE_TEXTURE2D(_PuddleDepth, sampler_PuddleDepth, uv).r;
				#if !defined(GLOBALLEVEL)
					half accumulatedWater_puddle = PuddleWaterSingle(puddleDepth, _PuddleEdgeWidth, _PuddleLevel);
				#else
					half accumulatedWater_puddle = PuddleWaterGlobal(puddleDepth, _PuddleEdgeWidth);
				#endif
				half3 rippleNormal = SampleRippleNormalTextureNor(worldSpacePos.xz * 0.12);
				half3 waterNormal = half3(rippleNormal.x, rippleNormal.z, rippleNormal.y);
				//water surfaceData 
				SurfaceData surfaceData = (SurfaceData)0.0;
				surfaceData.alpha = _BaseColor.a;
				surfaceData.albedo = _BaseColor.rgb;
				surfaceData.metallic = 0.0;
				surfaceData.specular = 0.02;
				surfaceData.smoothness = lerp(_Smoothness, 1, accumulatedWater_puddle);
				surfaceData.occlusion = 1.0;

				InputData inputData = (InputData)0;
				inputData.positionWS = worldSpacePos;
				inputData.normalWS = waterNormal;
				inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - worldSpacePos);
				inputData.bakedGI = SampleSH(inputData.normalWS);
				inputData.normalizedScreenSpaceUV = screenPos;

				half4 color = UniversalFragmentPBR(inputData, surfaceData);
				float fresnel = 1 - saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
				half3 fianlColor = color.rgb * accumulatedWater_puddle;
				half noPuddle = 1 - accumulatedWater_puddle;
				half underWaterIntensity = clamp(1.0 - fresnel + _PuddleClear + noPuddle, 0.0, lerp(0.6, 1, noPuddle)) ;
				return half4(fianlColor,  underWaterIntensity);
			}

			ENDHLSL
		}
	}
}