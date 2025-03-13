module MinGate(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    // M is A if B < D, otherwise C
    assign M = (B < D) ? A : C;

    // N is minimum of B and D
    assign N = (B < D) ? B : D;

endmodule
