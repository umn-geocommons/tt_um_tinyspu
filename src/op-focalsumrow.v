module FocalSumRow(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    // wire [3:0] outM, outN; // Output wires to M/N

    wire [3:0] Lft_sum = A + B + C;
    wire [3:0] Rgt_sum = B + C + D;
    
    assign M = Lft_sum;
    assign N = Rgt_sum;
endmodule