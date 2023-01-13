Shader "Code Repository/Scene/BakeHeight_Debug"
{
	Properties 
	{
	}

	SubShader 
	{
		Tags {"RenderPipeline"="UniversalPipeline" "RenderType" = "Opaque"}

		Pass 
		{
			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "BakeHeight.hlsl"

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
			};

			Varyings Vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;
				return OUT;
			}

			half4 Fragment(Varyings IN) : SV_Target 
			{
				float4 height = SAMPLE_TEXTURE2D(_SceneHeightTex, sampler_SceneHeightTex, IN.uv);
				return height;
			}
			ENDHLSL
		}
	}
}
