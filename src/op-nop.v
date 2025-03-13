module NOP(
    input  wire [3:0] current_M,  // Current value of M to hold
    input  wire [3:0] current_N,  // Current value of N to hold
    input  wire [3:0] A,          // Unused, kept for compatibility
    input  wire [3:0] B,          // Unused, kept for compatibility
    input  wire [3:0] C,          // Unused, kept for compatibility
    input  wire [3:0] D,          // Unused, kept for compatibility
    output wire [3:0] M,          // 4-bit output M (held value)
    output wire [3:0] N           // 4-bit output N (held value)
);

    // Simply pass through the stored values
    assign M = current_M;
    assign N = current_N;
    
endmodule