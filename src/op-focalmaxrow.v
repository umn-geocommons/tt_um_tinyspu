module FocalMaxRow(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [3:0] max_cntr;
    wire [3:0] max_lft;
    wire [3:0] max_rgt;

    assign max_cntr = (B > C) ? B : C;
    assign max_lft = (A > max_cntr) ? A : max_cntr;
    assign max_rgt = (D > max_cntr) ? D : max_cntr;
 
    assign M = max_lft;
    assign N = max_rgt;
endmodule