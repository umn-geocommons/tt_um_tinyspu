module BasicBuffer(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [3:0] buffer_distance = 4'd2;  // Explicit 4-bit representation

    wire dirx = C > A;  // Positive or 0 X
    wire diry = D > B;  // Positive or 0 Y

    wire [3:0] dx = (C > A) ? (C - A) : (A - C); // Width
    wire [3:0] dy = (D > B) ? (D - B) : (B - D); // Height

    // Determine X buffer value
    wire [3:0] buffer_x_pos = A + buffer_distance;
    wire [3:0] buffer_x_neg = A - buffer_distance;

    // Determine Y buffer value
    wire [3:0] buffer_y_pos = B + buffer_distance;
    wire [3:0] buffer_y_neg = B - buffer_distance;

    // Directly assign M and N based on conditions
    assign M = (dy == 4'd0) ? (dirx ? buffer_x_neg : buffer_x_pos) :
               (dx == 4'd0) ? (diry ? buffer_x_pos : buffer_x_neg) : A;

    assign N = (dy == 4'd0) ? (dirx ? buffer_y_neg : buffer_y_pos) :
               (dx == 4'd0) ? (diry ? buffer_y_neg : buffer_y_pos) : B;

endmodule
