Shader "Code Repository/Scene/Rain" 
{
	Properties 
	{

	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/Scene/BakeSceneHeight/Shader/BakeHeight.hlsl"
			#include "Assets/Scene/StylizedScene/Weather/Rain/Shader/RianInclude.hlsl"

			//half _RainIntensity;
			half _RainOpacityInAll;
			half3 _RainColor;
			float4 _RainScale_Layer12;
			float4 _RainScale_Layer34;
			float4 _RotateSpeed;
			float4 _RotateAmount;
			float4 _DropSpeed;
			float4 _RainDepthStart;
			float4 _RainDepthRange;
			float4 _RainOpacities;

			TEXTURE2D(_RainSplashTex);
			SAMPLER(sampler_RainSplashTex);
		
			TEXTURE2D(_RainShapeTex); //r：形状；g：偏移；b：消失阈值
			SAMPLER(sampler_RainShapeTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			TEXTURE2D(_RainMaskTexture);
			SAMPLER(sampler_RainMaskTexture);
		
			float CalcSceneDepth(float4 screenPosition)
			{
				float2 screenPos = screenPosition.xy / screenPosition.w;
				float depthTextureValue = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float eyeDepth = LinearEyeDepth(depthTextureValue, _ZBufferParams);
				return eyeDepth;
			}

		ENDHLSL

		Pass
		{
			Name "Rain Ripple"

			Cull Off
			ZWrite Off
			ZTest Always

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			struct Attributes 
			{
				//float4 positionOS   : POSITION;
				uint vertexID : SV_VertexID;
			};

			struct Varyings 
			{
				float4 positionCS    : SV_POSITION;
				float2 uv            : TEXCOORD0;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				//https://catlikecoding.com/unity/tutorials/scriptable-render-pipeline/post-processing/#3
				//OUT.positionCS = float4(IN.positionOS.xy, 0.0, 1.0);
				//OUT.uv = IN.positionOS.xy * 0.5 + 0.5;
				//https://catlikecoding.com/unity/tutorials/custom-srp/post-processing/#1.6
				OUT.positionCS = float4(IN.vertexID <= 1 ? -1.0 : 3.0, IN.vertexID == 1.0 ? 3.0 : -1.0, 0.0, 1.0);
				OUT.uv = float2(IN.vertexID <= 1 ? 0.0 : 2.0, IN.vertexID == 1 ? 2.0 : 0.0);
				#if UNITY_UV_STARTS_AT_TOP
					OUT.uv.y = 1.0 - OUT.uv.y;
				#endif
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				return RippleNormalTexture(IN.uv);
			}
			ENDHLSL
		}

		pass
		{
			Name "Rain Splash"
			Cull Off
			Blend SrcAlpha One
			ZWrite Off

			HLSLPROGRAM
			#pragma multi_compile_instancing

			#pragma vertex vertex
			#pragma fragment fragment

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SplashInfo_1)//pos.xz,scale,index
				UNITY_DEFINE_INSTANCED_PROP(half, _SplashInfo_2) //opacity
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			//splash col,1/splash col, 1/splash row
			float3 _GlobalSplashInfo;

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 UV				: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				float4 splashInfo_1 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SplashInfo_1);
				float yPos = UnpackHeightmapR(float3(splashInfo_1.x, 0.0, splashInfo_1.y));
				float3 centerPosWS = float3(splashInfo_1.x, yPos, splashInfo_1.y);

				//billboard
				float3 forward = -(_WorldSpaceCameraPos - centerPosWS);
				forward.y = 0.0;
				forward = SafeNormalize(forward);
                float3 up = float3(0, 1.0, 0);
                float3 right = normalize(cross(up, forward));
                up = normalize(cross(forward, right));
                float3x3 newWorldMatrix = float3x3(right, up, forward);
				newWorldMatrix = transpose(newWorldMatrix);

				float3 posOS = IN.positionOS.xyz * splashInfo_1.z;
				float3 posWS = centerPosWS + mul(newWorldMatrix, posOS);
				OUT.positionCS = TransformWorldToHClip(posWS);
				OUT.UV = IN.uv * _GlobalSplashInfo.yz + float2(splashInfo_1.w % _GlobalSplashInfo.x, floor(splashInfo_1.w / _GlobalSplashInfo.x)) * _GlobalSplashInfo.yz;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				half4 rainSplashColor = SAMPLE_TEXTURE2D(_RainSplashTex, sampler_RainSplashTex, IN.UV) * saturate(_MainLightColor.a + 0.3);
				half splashInfo_2 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SplashInfo_2);
				rainSplashColor.a *= splashInfo_2;
				return rainSplashColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Rain Mask"

			Cull Off
			ZWrite Off
			ZTest Always

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 UV				: TEXCOORD0;	
				float4 UVLayer12		: TEXCOORD1;
				float4 UVLayer34		: TEXCOORD2;
				float4 ScreenPosition	: TEXCOORD3;
				float4 ViewDirVS		: TEXCOORD4;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.UV = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;

				OUT.ScreenPosition = ComputeScreenPos(OUT.positionCS);
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 posVS = TransformWorldToView(posWS);
				OUT.ViewDirVS.xyz = posWS - _WorldSpaceCameraPos.xyz;
				OUT.ViewDirVS.w = -posVS.z;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				//view depth test
				float backDepthVS = CalcSceneDepth(IN.ScreenPosition);

				float4 virtualDepth = 0.0;
				virtualDepth.x = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.xy).g;
				virtualDepth.y = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.zw).g;
				virtualDepth.z = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.xy).g;
				virtualDepth.w = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.zw).g;
				virtualDepth = virtualDepth * _RainDepthRange + _RainDepthStart;

				float4 occlusionDistance = smoothstep(backDepthVS, backDepthVS - 3, virtualDepth);

				// Calc virtual position
				float4 depthRatio = virtualDepth / IN.ViewDirVS.w;
				float3 virtualPosition1WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.x;
				float3 virtualPosition2WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.y;
				float3 virtualPosition3WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.z;
				float3 virtualPosition4WS = _WorldSpaceCameraPos.xyz + IN.ViewDirVS.xyz * depthRatio.w;

				// heigth depth test
				float4 occlusionHeight = 0;
				occlusionHeight.x = saturate(virtualPosition1WS.y - UnpackHeightmapR(virtualPosition1WS));
				occlusionHeight.y = saturate(virtualPosition2WS.y - UnpackHeightmapR(virtualPosition2WS));
				occlusionHeight.z = saturate(virtualPosition3WS.y - UnpackHeightmapR(virtualPosition3WS));
				occlusionHeight.w = saturate(virtualPosition4WS.y - UnpackHeightmapR(virtualPosition4WS));

				half4 maskColor = occlusionDistance * occlusionHeight * _RainOpacities * _RainOpacityInAll;
				return maskColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Rain Merge"
			Cull Off
			ZWrite Off
			ZTest Always
			Blend SrcAlpha One

			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS		: POSITION;
				float2 uv				: TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 		: SV_POSITION;
				float2 uv				: TEXCOORD0;	
				float4 UVLayer12		: TEXCOORD1;
				float4 UVLayer34		: TEXCOORD2;
				float4 ScreenPosition	: TEXCOORD3;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;

				OUT.ScreenPosition = ComputeScreenPos(OUT.positionCS);
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				float4 maskLow =  SAMPLE_TEXTURE2D(_RainMaskTexture, sampler_RainMaskTexture, IN.ScreenPosition.xy / IN.ScreenPosition.w);

				half4 layer1 = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.xy);
				half4 layer2 = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.zw);
				half4 layer3 = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.xy);
				half4 layer4 = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.zw);

				half4 rainShape = 0;
				rainShape.x = layer1.x;
				rainShape.y = layer2.x;
				rainShape.z = layer3.x;
				rainShape.w = layer4.x;

				half4 rainIntensity = 1;
				rainIntensity.x = layer1.z;
				rainIntensity.y = layer2.z;
				rainIntensity.z = layer3.z;
				rainIntensity.w = layer4.z;
				rainIntensity = saturate((rainIntensity - 1.0 + _RainIntensity) * 1000);

				rainShape = rainShape * rainIntensity;
				half rainMask = dot(rainShape, maskLow);
				rainMask = saturate(rainMask);

				half3 finalColor = _RainColor * rainMask * saturate(_MainLightColor.a + 0.3);
				half gradientFactor = smoothstep(0.1, 0.3, IN.uv.y) * smoothstep(1.0, 0.9, IN.uv.y);
				finalColor *= gradientFactor;
				return half4(finalColor, 1.0);
			}
			ENDHLSL
		}
	}
}