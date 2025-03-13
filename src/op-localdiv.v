module LocalDiv(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    assign M = (C == 4'b0000) ? 4'b0000 : A / C;
    assign N = (D == 4'b0000) ? 4'b0000 : B / D;

endmodule
