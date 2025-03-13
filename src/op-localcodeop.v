module LocalCodeOp(
    input  wire [3:0] A,  // 4-bit
    input  wire [3:0] B,  // 4-bit
    input  wire [3:0] C,  // 4-bit
    input  wire [3:0] D,  // 4-bit: upper 2 bits = op1, lower 2 bits = op2
    output reg  [3:0] M,  // 4-bit result of (A op1 B)
    output reg  [3:0] N   // 4-bit result of ((A op1 B) op2 C)
);

    reg [7:0] op1_result; // intermediate result for op1 (A op1 B)
    reg [7:0] op2_result;  // intermediate result for op2 ((A op1 B) op2 C)

    always @(*) begin
        // Determine op1: perform A op1 B based on D[3:2]
        case (D[3:2])
            2'b00: op1_result = A & B;  // 00 = bitwise AND
            2'b01: op1_result = A | B;  // 01 = bitwise OR
            2'b10: op1_result = A + B;  // 10 = addition
            2'b11: op1_result = A * B;  // 11 = multiplication
            default: op1_result = 0;
        endcase
        
        // Lower 4 bits of op1_result to M
        M = op1_result[3:0];

        // Determine op2: perform (A op1 B) op2 C based on D[1:0]
        case (D[1:0])
            2'b00: op2_result = op1_result & C;  // 00 = bitwise AND
            2'b01: op2_result = op1_result | C;  // 01 = bitwise OR
            2'b10: op2_result = op1_result + C;  // 10 = addition
            2'b11: op2_result = op1_result * C;  // 11 = multiplication
            default: op2_result = 0;
        endcase

        // Assign lower 4 bits of res to N
        N = op2_result[3:0];
    end

endmodule
