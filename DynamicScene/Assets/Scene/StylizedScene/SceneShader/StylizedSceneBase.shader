Shader "Code Repository/Scene/StylizedSceneBase"
{
	Properties 
	{
		_BaseMap("Base Map(RGB)", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)

		[Space(20)]
		[Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Float) = 0.5

		[Space(20)]
		[Toggle(_METALLICGLOSSMAP)] _MetallicGlossMapToggle ("Use Metallic Smoothness Map", Float) = 1
        _MetallicGlossMap("Metallic Map", 2D) = "black" {}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

		[Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 1
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 1
		[NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "bump" {}
		_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[Space(20)]
		[Toggle(_PARALLAXMAP)] _ParallaxToggle ("Enable Parallax", Float) = 1
        [NoScaleOffset]_ParallaxMap("Height Map", 2D) = "black" {}
        _Parallax("Height", Range(0.005, 0.08)) = 0.005

		[Space(20)]
		[Toggle(_EMISSION)] _Emission ("Enable Emission", Float) = 0
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0)

		[Space(20)]
		[Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Close Specular Highlights", Float) = 0
		[Toggle(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentalReflections("Close Environmental Reflections", Float) = 0
		[Toggle(_RECEIVE_SHADOWS_OFF)] _ReceiveShadowsOff("Close Shadows", Float) = 0

		[Space(20)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", Float) = 0.0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1.0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("CullMode", Float) = 2.0
	}
	SubShader 
	{
		Tags{"RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

		//UniversalForward
		Pass 
		{
			Tags { "LightMode"="UniversalForward" }
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
			ZTest[_ZTest]
            Cull[_Cull]

			HLSLPROGRAM
			// Material Keywords
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local _METALLICGLOSSMAP
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _OCCLUSIONMAP
			#pragma shader_feature_local _PARALLAXMAP
			#pragma shader_feature_local _EMISSION
			#pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

			#pragma multi_compile _ RAIN

			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "StylizedSceneBaseInput.hlsl"
			#include "StylizedSceneBaseForwardPass.hlsl"
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

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "StylizedSceneBaseInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

		//DepthOnly
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            //#pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "StylizedSceneBaseInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

		////Meta
		//Pass 
		//{
		//	Name "Meta"
		//	Tags{"LightMode" = "Meta"}

		//	Cull Off

		//	HLSLPROGRAM
		//	#pragma vertex UniversalVertexMeta
		//	#pragma fragment UniversalFragmentMeta

		//	#pragma shader_feature_local_fragment _SPECULAR_SETUP
		//	#pragma shader_feature_local_fragment _EMISSION
		//	#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
		//	#pragma shader_feature_local_fragment _ALPHATEST_ON
		//	#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
		//	//#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

		//	#pragma shader_feature_local_fragment _SPECGLOSSMAP

		//	struct Attributes 
		//	{
		//		float4 positionOS   : POSITION;
		//		float3 normalOS     : NORMAL;
		//		float2 uv0          : TEXCOORD0;
		//		float2 uv1          : TEXCOORD1;
		//		float2 uv2          : TEXCOORD2;
		//		#ifdef _TANGENT_TO_WORLD
		//		float4 tangentOS     : TANGENT;
		//		#endif
		//		float4 color		: COLOR;
		//	};

		//	struct Varyings 
		//	{
		//		float4 positionCS   : SV_POSITION;
		//		float2 uv           : TEXCOORD0;
		//		float4 color		: COLOR;
		//	};

		//	#include "StylizedSceneBaseSurface.hlsl"
		//	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

		//	Varyings UniversalVertexMeta(Attributes input) 
		//	{
		//		Varyings output;
		//		output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2, unity_LightmapST, unity_DynamicLightmapST);
		//		output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
		//		output.color = input.color;
		//		return output;
		//	}

		//	half4 UniversalFragmentMeta(Varyings input) : SV_Target 
		//	{
		//		SurfaceData surfaceData;
		//		InitializeSurfaceData(input, surfaceData);

		//		BRDFData brdfData;
		//		InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

		//		MetaInput metaInput;
		//		metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
		//		metaInput.SpecularColor = surfaceData.specular;
		//		metaInput.Emission = surfaceData.emission;

		//		return MetaFragment(metaInput);
		//	}

		//	ENDHLSL
		//}
	}
}
