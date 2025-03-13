module DotProduct(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit
    output wire [3:0] M,  // 4-bit
    output wire [3:0] N   // 4-bit
);

    wire [7:0] prod;  // 8-bit product of A and B
    wire [7:0] accum; // 8-bit accumulated sum (input)
    wire [7:0] sum;   // 8-bit final sum

    // Step 1: Compute the dot product (multiplication)
    assign prod = A * B; // 4-bit * 4-bit = 8-bit result

    // Step 2: Reconstruct the accumulated sum from C (high 4-bits) and D (low 4-bits)
    assign accum = {C, D}; // Concatenating C and D to form 8-bit value

    // Step 3: Compute the final sum
    assign sum = prod + accum;

    // Step 4: Extract high and low 4-bits and save into M (high) and N (low) 8-bit sum
    assign M = sum[7:4]; // High 4-bits
    assign N = sum[3:0]; // Low 4-bits
    
endmodule