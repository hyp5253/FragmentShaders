Shader "Custom/GridSlidShader"
{
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

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // the grid has 16 titles total 
                float2 gridTileCount = float2(4.0, 4.0);

                float phaseCycleSpeed = 0.25;
                float tileShiftAmount = 0.5;

                // U means horizontal and V means vertical both are in range [0,1]
                // scale up UVs to match the number of tiles in the grid
                // instead its now [0, 4] 
                float2 gridUV = IN.uv * gridTileCount; 

                // which tile we are on (0,0) (0,1) (1,0) (1,1) ... (3,3)
                float2 tileIndex = floor(gridUV); 

                // the UVs within each tile (0,0) to (1,1)
                float2 tileUV = frac(gridUV); 

                float phasePos = frac(_Time.y * phaseCycleSpeed) * 4.0;
                float phase = floor(phasePos);
                
                // shift the tile UVs in a cycle to create a sliding effect
                float2 A = float2(0.0, 0.0);
                float2 B = float2(tileShiftAmount, 0.0);
                float2 C = float2(tileShiftAmount, tileShiftAmount);
                float2 D = float2(0.0, tileShiftAmount);


                float2 offsetTile;
                if (phase < 1.0)
                {
                    offsetTile = lerp(A, B, frac(phasePos));
                }
                else if (phase < 2.0)
                {
                    offsetTile = lerp(B, C, frac(phasePos));
                }
                else if (phase < 3.0)
                {
                    offsetTile = lerp(C, D, frac(phasePos));
                }
                else
                {
                    offsetTile = lerp(D, A, frac(phasePos));
                }

                // 0 for even tiles, 1 for odd tiles
                float parity = frac((tileIndex.x + tileIndex.y) * 0.5) * 2.0; 

                // +1 for even tiles, -1 for odd tiles
                float signV = parity * 2.0 - 1.0; 

                float2 shiftedUV = frac((tileIndex + tileUV + offsetTile * signV) / gridTileCount);


                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, shiftedUV) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
