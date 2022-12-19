Shader "Code Repository/Scene/CustomLensFlare"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent"}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
		
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				//x = offset,y = rotation (< 0 = Auto)
				float2 lensFlareData : TEXCOORD1;
				//x = radius,y = occlusionScale (< 0 = Auto)
				float2 lensFlareData1 : TEXCOORD2;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;				
				float2 screenPos : TEXCOORD1;
			};

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);

			half _IsNight;
			half _RainIntensity;

			//https://github.com/Unity-Technologies/FontainebleauDemo/tree/master/Assets/Scripts/LensFlare
			static const uint DEPTH_SAMPLE_COUNT = 32;
			static const float2 samples[DEPTH_SAMPLE_COUNT] = {
				float2(0.658752441406,-0.0977704077959),
				float2(0.505380451679,-0.862896621227),
				float2(-0.678673446178,0.120453640819),
				float2(-0.429447203875,-0.501827657223),
				float2(-0.239791020751,0.577527523041),
				float2(-0.666824519634,-0.745214760303),
				float2(0.147858589888,-0.304675519466),
				float2(0.0334240831435,0.263438135386),
				float2(-0.164710089564,-0.17076793313),
				float2(0.289210408926,0.0226817727089),
				float2(0.109557107091,-0.993980526924),
				float2(-0.999996423721,-0.00266989553347),
				float2(0.804284930229,0.594243884087),
				float2(0.240315377712,-0.653567194939),
				float2(-0.313934922218,0.94944447279),
				float2(0.386928111315,0.480902403593),
				float2(0.979771316051,-0.200120285153),
				float2(0.505873680115,-0.407543361187),
				float2(0.617167234421,0.247610524297),
				float2(-0.672138273716,0.740425646305),
				float2(-0.305256098509,-0.952270269394),
				float2(0.493631094694,0.869671344757),
				float2(0.0982239097357,0.995164275169),
				float2(0.976404249668,0.21595069766),
				float2(-0.308868765831,0.150203511119),
				float2(-0.586166858673,-0.19671548903),
				float2(-0.912466347218,-0.409151613712),
				float2(0.0959918648005,0.666364192963),
				float2(0.813257217407,-0.581904232502),
				float2(-0.914829492569,0.403840065002),
				float2(-0.542099535465,0.432246923447),
				float2(-0.106764614582,-0.618209302425)
			};

			float GetOcclusion(float2 screenPos, float depth, float2 radius)
			{
				float contrib = 0.0f;
				float sample_Contrib = 1.0 / DEPTH_SAMPLE_COUNT;
				for (uint i = 0; i < DEPTH_SAMPLE_COUNT; i++)
				{
					float2 pos = screenPos + samples[i] * radius;
					pos.y *= _ProjectionParams.x;
					pos = pos  * 0.5 + 0.5;
					float sampledDepth = Linear01Depth(SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, pos, 0).r, _ZBufferParams);	
					contrib += sample_Contrib * step(depth, sampledDepth);
				}
				return contrib;
			}

            half4 frag(v2f i):SV_Target
            {
				float fade = 1 - saturate(distance(i.screenPos, float2(0, 0)) / 1.4); //sqart(1+1) = 1.4,耀斑靠近屏幕边缘降低亮度
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				return col * i.color * fade * _MainLightColor  * (1 - _IsNight) * (1.0 - _RainIntensity);
            }

		ENDHLSL

		//point
        Pass
        {   
            Blend One One
            ColorMask RGB
            ZWrite Off
            Cull Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			v2f vert(appdata v)
			{
				v2f o;
				float2 sunScreenPos;
				float sunDepth;
				float clipRadius;

				float3 sunPosW = TransformObjectToWorld(float3(0, 0, 0));
				float3 sunPosVS = TransformWorldToView(sunPosW);
				float4 sunClip = TransformWViewToHClip(sunPosVS);
				sunDepth = sunClip.w * _ProjectionParams.w;//0-1
				sunScreenPos = sunClip.xy / sunClip.w;  //-1 to 1
				float4 sunRadiusClip = TransformWorldToHClip(sunPosW +  float3(0, 1, 0) * v.lensFlareData1.x);
				float2 sunRadiusScreenPos = sunRadiusClip.xy / sunRadiusClip.w;
				clipRadius = distance(sunScreenPos, sunRadiusScreenPos);

				float ratio = _ScreenParams.x / _ScreenParams.y; // screenWidth/screenHeight
				float occlusion = GetOcclusion(sunScreenPos, sunDepth - v.lensFlareData1.x * _ProjectionParams.w, clipRadius * float2(1/ratio, 1)); //深度遮挡
				float maxSunScreenPos = saturate(max(abs(sunScreenPos.x), abs(sunScreenPos.y)));
				occlusion *= (1 - saturate(maxSunScreenPos - 0.85) / 0.15); //(1 - 0.85)= 0.15
				occlusion *= step(sunPosVS.z, 0); //sun位于背面要剔除

				float angle = v.lensFlareData.y;
				if (angle < 0) // 自动旋转， 根据dir向量
				{
					float2 dir = normalize(sunScreenPos);
# if UNITY_UV_STARTS_AT_TOP
					angle = atan2(dir.y, dir.x) + HALF_PI; //dx 加half pi
#else
					angle = atan2(dir.y, dir.x) - HALF_PI; //opengl 减half pi，保证贴图v指向sun， atan2返回[-PI, PI]
#endif
				}

				//flare面片大小
				float quadSize = lerp(v.lensFlareData1.y, 1.0f, occlusion);
				quadSize  *= (1 - step(occlusion, 0)); // clip
				float2 localPos = v.vertex.xy * quadSize;
				localPos = float2(localPos.x * cos(angle) + localPos.y * (-sin(angle)), localPos.x * sin(angle) + localPos.y * cos(angle)); //旋转
				localPos.x /= ratio; // 面片局部坐标在(-1, 1)范围，需映射到屏幕的比例，需应用对应屏幕比例的缩放，否则结果会被拉伸

				float2 rayOffset = -sunScreenPos * v.lensFlareData.x;
				o.vertex.xy = localPos + rayOffset;
				o.vertex.z = 1;
				o.vertex.w = 1;
				o.uv = v.uv;
				o.color = v.color * occlusion;
				o.screenPos = o.vertex.xy;
				return o;
			}
            ENDHLSL
        }

		//directional
        Pass
        {   
            Blend One One
            ColorMask RGB
            ZWrite Off
            Cull Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			v2f vert(appdata v)
			{
				v2f o;
				float2 sunScreenPos;
				float sunDepth;
				float clipRadius;

				float3 sunPosVS = mul((float3x3)UNITY_MATRIX_V, _MainLightPosition.xyz);
				float4 sunClip = mul(UNITY_MATRIX_P, float4(sunPosVS, 1));
				sunDepth = 0.999;
				sunScreenPos = sunClip.xy / sunClip.w;  //-1 to 1
				clipRadius = v.lensFlareData1.x;

				float ratio = _ScreenParams.x / _ScreenParams.y; // screenWidth/screenHeight
				float occlusion = GetOcclusion(sunScreenPos, sunDepth - v.lensFlareData1.x, clipRadius * float2(1/ratio, 1)); //深度遮挡
				float maxSunScreenPos = saturate(max(abs(sunScreenPos.x), abs(sunScreenPos.y)));
				occlusion *= (1 - saturate(maxSunScreenPos - 0.85) / 0.15); //(1 - 0.85)= 0.15
				occlusion *= step(sunPosVS.z, 0); //sun位于背面要剔除
				
				float angle = v.lensFlareData.y;
				if (angle < 0) // 自动旋转， 根据dir向量
				{
					float2 dir = normalize(sunScreenPos);
# if UNITY_UV_STARTS_AT_TOP
					angle = atan2(dir.y, dir.x) + HALF_PI; //dx 加half pi
#else
					angle = atan2(dir.y, dir.x) - HALF_PI; //opengl 减half pi，保证贴图v指向sun， atan2返回[-PI, PI]
#endif
				}

				//flare面片大小
				float quadSize = lerp(v.lensFlareData1.y, 1.0f, occlusion);
				quadSize  *= (1 - step(occlusion, 0)); // clip
				float2 localPos = v.vertex.xy * quadSize;
				localPos = float2(localPos.x * cos(angle) + localPos.y * (-sin(angle)), localPos.x * sin(angle) + localPos.y * cos(angle)); //旋转
				localPos.x /= ratio; // 面片局部坐标在(-1, 1)范围，需映射到屏幕的比例，需应用对应屏幕比例的缩放，否则结果会被拉伸

				float2 rayOffset = -sunScreenPos * v.lensFlareData.x;
				o.vertex.xy = localPos + rayOffset;
				o.vertex.z = 1;
				o.vertex.w = 1;
				o.uv = v.uv;
				o.color = v.color * occlusion;
				o.screenPos = o.vertex.xy;				
				return o;
			}
            ENDHLSL
        }		
    }
}
