module DistDir(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    // Compute absolute differences.
    wire [3:0] deltaX = (A > C) ? (A - C) : (C - A); // |x1 - x2|
    wire [3:0] deltaY = (B > D) ? (B - D) : (D - B); // |y1 - y2|

    reg [2:0] aspect_code;
    always @(*) begin
        if ((deltaX == 0) && (deltaY == 0))
            aspect_code = 3'd0; // default: North
        else if (deltaX == 0) begin
            if (B < D)
                aspect_code = 3'd0; // North      = 0
            else
                aspect_code = 3'd4; // South      = 4
        end else if (deltaY == 0) begin
            if (A < C)
                aspect_code = 3'd2; // East       = 2
            else
                aspect_code = 3'd6; // West       = 6
        end else if ((A < C) && (B < D))
            aspect_code = 3'd1;     // Northeast  = 1
        else if ((A < C) && (B > D))
            aspect_code = 3'd3;     // Southeast  = 3
        else if ((A > C) && (B > D))
            aspect_code = 3'd5;     // Southwest  = 5
        else // (A > C && B < D)
            aspect_code = 3'd7;     // Northwest  = 7
    end

    assign M = deltaX + deltaY;     // Manhattan Distance = |x1 - x2| + |y1 - y2|
    assign N = aspect_code;         // N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7

endmodule