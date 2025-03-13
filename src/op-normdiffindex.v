module NormDiffIndex(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);
    
    /*
    NDVI (Normalized Difference Vegetation Index)
    NDVI Example: NIR[0] = A, NIR[1] = B, RED[0] = C, RED[1] = D
                  (A-C) / (A+C) == (NIR - RED) / (NIR + RED) @ 0
                  (B-D) / (B+D) == (NIR - RED) / (NIR + RED) @ 1
    NDWI (Normalized Difference Water Index)
    NDWI Example: GREEN[0] = A, GREEN[1] = B, NIR[0] = C, NIR[1] = D
                  (A-C) / (A+C) == (GREEN - NIR) / (GREEN + NIR) @ 0
                  (B-D) / (B+D) == (GREEN - NIR) / (GREEN + NIR) @ 1
    NBR (Normalized Burn Ratio)
    NBR Example: NIR[0] = A, NIR[1] = B, SWIR[0] = C, SWIR[1] = D
                  (A-C) / (A+C) == (NIR - SWIR) / (NIR + SWIR) @ 0
                  (B-D) / (B+D) == (NIR - SWIR) / (NIR + SWIR) @ 1
    */
    
    // Cast inputs to a larger signed type
    wire signed [4:0] sA = $signed({1'b0, A});
    wire signed [4:0] sB = $signed({1'b0, B});
    wire signed [4:0] sC = $signed({1'b0, C});
    wire signed [4:0] sD = $signed({1'b0, D});
    
    wire signed [9:0] num_ndiAC, tdn_ndiAC;
    wire signed [9:0] num_ndiBD, tdn_ndiBD;

    wire signed [9:0] scaled_ndiAC, scaled_ndiBD;
    wire [3:0] ndiAC, ndiBD;

    // TEST MORE :)    

    assign num_ndiAC = (sA - sC) * 16; // Equivalent to (NIR - Red) * 16 for NDVI (A-C) * 16
    assign tdn_ndiAC = (sA + sC) * 16; // Equivalent to (NIR + Red) * 16 for NDVI (A+C) * 16

    assign num_ndiBD = (sB - sD) * 16; // Equivalent to (NIR - Red) * 16 for NDVI
    assign tdn_ndiBD = (sB + sD) * 16; // Equivalent to (NIR + Red) * 16 for NDVI
    
    // Watch for division by 0 error: if (A+C)==0 or (B+D)==0, output 0
    // Compute scaled NDVI, NDWI, and NBR in range [-16, 16]
    assign scaled_ndiAC = (tdn_ndiAC == 0) ? 0 : (((num_ndiAC * 8) / tdn_ndiAC) + 8);
    assign scaled_ndiBD = (tdn_ndiBD == 0) ? 0 : (((num_ndiBD * 8) / tdn_ndiBD) + 8);

    // Map result to 4-bit output (0-15)
    assign ndiAC = (scaled_ndiAC > 15) ? 15 : scaled_ndiAC[3:0];
    assign ndiBD = (scaled_ndiBD > 15) ? 15 : scaled_ndiBD[3:0];

    assign M = ndiAC;
    assign N = ndiBD;
    
endmodule
