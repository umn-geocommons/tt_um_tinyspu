module VectorBoxArea(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [3:0] deltaX = (C > A) ? (C - A) : (A - C); // Width
    wire [3:0] deltaY = (D > B) ? (D - B) : (B - D); // Height

    assign M = deltaX * deltaY;                      // A = H * W
    assign N = (deltaX << 1) + (deltaY << 1);        // P = 2*H + 2*W
endmodule