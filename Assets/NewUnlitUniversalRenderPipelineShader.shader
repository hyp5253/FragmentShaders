Shader "Custom/NewUnlitUniversalRenderPipelineShader"
{
    // Create UI controls in Unity's material inspector
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
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
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
