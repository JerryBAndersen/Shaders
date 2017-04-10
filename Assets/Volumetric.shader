// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Volumetric"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Position("Position", Vector) = (0,0,0)
		_SunDir("Sun Direction", Vector) = (0,-1,0)
		_Factor("Factor", Float) = 0.1
		_Steps("Steps", Int) = 30
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 screenPos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float3 _Position;
			float3 _SunDir;
			float _Factor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.screenPos = UnityObjectToClipPos(v.vertex);
				o.uv = v.vertex;
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
				return o;
			}
			
			float volumeSample(float3 pos) {
				return 1.0-clamp(length(_Position - pos),0.0, 1.0);
			}

			float march(float3 surfacePos, float3 dir, float3 sundir, float factor) {
				float4 res = float4(0,0,0,0);
				for (int i = 0; i < 30; i++) {
					float3 samplePoint = surfacePos + dir*(i*factor);
					float o = 1;
					for (int j = 0; j < 30; j++) {
						o += volumeSample(samplePoint - sundir * (j*factor));
					}
					res += float4(o,o,o,0);
					res.w = volumeSample(samplePoint);
				}
				return res;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				//float4 pos = float4(i.vertex.x,i.vertex.y,0,1);
				// screenposition
				//fixed4 col = float4(i.col.x/ _ScreenParams.x, i.col.y/ _ScreenParams.y,0,1);
				//float4 wpos = mul(unity_CameraInvProjection, col);
				// depth
				//fixed4 col = i.screenPos.zzzz*10;
				// depth too?
				//float l = length(i.viewDir);
				float3 surfacePos = mul(unity_ObjectToWorld, i.uv).xyz;
				float4 col = march(surfacePos, normalize(i.viewDir), normalize(_SunDir),_Factor);
				//fixed4 col = fixed4(1,1,1,l);
				return col;
			}
			ENDCG
		}
	}
}
