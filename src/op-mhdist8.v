module MHDist8(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [7:0] distance; // 8-bit Manhattan Distance

    // Compute absolute differences.
    wire [3:0] deltaX = (A > C) ? (A - C) : (C - A); // |x1 - x2|
    wire [3:0] deltaY = (B > D) ? (B - D) : (D - B); // |y1 - y2|

    assign distance = deltaX + deltaY;

    assign M = distance[7:4]; // M = High 4-bits
    assign N = distance[3:0]; // N = Low 4-bits

endmodule