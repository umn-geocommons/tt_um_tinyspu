module FocalMaxPoolRow(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [3:0] max_lft;
    wire [3:0] max_rgt;

    assign max_lft = (A > B) ? A : B;
    assign max_rgt = (C > D) ? C : D;
 
    assign M = max_lft;
    assign N = max_rgt;
endmodule