Shader "Custom/NewUnlitUniversalRenderPipelineShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _SecondMap("Second Map", 2D) = "white" {}
        _FadeAmount("Fade Amount", Range(0, 1)) = 0.5
        _FadeSpeed("Fade Speed", float) = 1.0
        _FadeRange("Fade Range", Range(0, 1)) = 0.7
        _SwirlStrength("Swirl Strength", Range(0, 25)) = 5.0
        _SwirlSpeed("Swirl Speed", float) = 1.0
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

            TEXTURE2D(_BaseMap);        //magikarp
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_SecondMap);      // gyrados
            SAMPLER(sampler_SecondMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _SecondMap_ST;
                float _FadeAmount;
                float _FadeSpeed;
                float _FadeRange;
                float _SwirlStrength;
                float _SwirlSpeed;
            CBUFFER_END

            // Transforms 3d positions to screen space & passes UV coordinates [(0,0) (0,1) (1,0) (1,1)] to frag shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }
            /*
            SAMPLE_TEXTURE2D    helper function that samples a texture using the provided sampler and UV coordinates
            _Time.y * speed     can be used to create an animation effect by modifying the UV coordinates over time, creating a scrolling texture effect
            frac(x)             get fractional part of x, useful for repeating textures
            sin(x), cos(x)      can be used to create oscillating effects
            lerp(a,b,t)         linear interpolation between a and b based on t (0 to 1), useful for blending colors or textures
            */

            // newer syntax for same function -> fixed frag(v2f i) : SV_Target
            // IN holds UV coordinates
            half4 frag(Varyings IN) : SV_Target
            {
                float2 uvCenter = 0.5;

                // center UV around (0,0) for rotation so botleft is (-0.5, -0.5) and topright is (0.5, 0.5)
                float2 centeredUV = IN.uv - uvCenter; 

                // distance from center
                float dist = length(centeredUV); 

                // angle in radians
                // aka what direction from center -> thinking of it like a compass
                float angle = atan2(centeredUV.y, centeredUV.x); 
                float rotation = 1.0 - dist;

                float swirlOscillation = sin(_Time.y * _SwirlSpeed);
                float fadeOscillation = cos(_Time.y * _SwirlSpeed);
                
                float fade = (fadeOscillation + 1.0) * 0.5;
                fade = smoothstep(0.5 - _FadeRange, 0.5 + _FadeRange, fade); 

                angle += rotation * _SwirlStrength * swirlOscillation;

                // convert back to cartesian coordinates
                float2 swirlUV = float2(cos(angle), sin(angle)) * dist + uvCenter;

                // sample both textures making sure to use the swirlUV coordinates
                half4 color1 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, swirlUV) * _BaseColor;
                half4 color2 = SAMPLE_TEXTURE2D(_SecondMap, sampler_SecondMap, swirlUV) * _BaseColor;

                // blend the two colors based on the fade amount
                half4 finalcolor = lerp(color1, color2, fade);

                return finalcolor;

            }
            ENDHLSL
        }
    }
}
