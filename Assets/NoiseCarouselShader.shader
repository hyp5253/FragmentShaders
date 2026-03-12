Shader "Custom/NoiseCarouselShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _ScrollSpeed("Scroll Speed", float) = 0.5
        _NoiseScale("Noise Scale", float) = 50.0
        _NoiseStrength("Noise Strength", float) = 0.3
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _ScrollSpeed;
                float _NoiseScale;
                float _NoiseStrength;
            CBUFFER_END

            // It is convention to put helper functions after constant buffers
            float randomNoise2(float2 seed)
            {
                return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Move the UV coordinates upward over time to create a scrolling effect
                float2 scrollingUV = IN.uv;
                scrollingUV.y -= _Time.y * _ScrollSpeed;

                // Wrap the UV coordinates using frac convention
                scrollingUV = frac(scrollingUV); 

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, scrollingUV) * _BaseColor;

                // Generate noise based on UV coordinates and time
                float noise = randomNoise2(IN.uv * _NoiseScale + _Time.y);

                half finalColor = lerp(color, half4(1,1,1,1), noise * _NoiseStrength);

                return finalColor;
            }
            ENDHLSL
        }
    }
}
