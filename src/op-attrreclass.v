module AttrReclass(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [3:0] attr_r3; // 3 classes C>A == 1, C<B == 3, C<=A and C>=B == 2
    wire [3:0] attr_r2; // 2 classes C>=D == 0, C<D == 5


    assign attr_r3 = (C > A) ? 4'd1 :
                       ((C <= A && C >= B) ? 4'd2 : 4'd3);

    assign attr_r2 = (C >= D) ? 4'd0 : 4'd5;

    assign M = attr_r3; // Set 3 class, reclassification to M
    assign N = attr_r2; // Set 2 class, reclassification to N

endmodule
