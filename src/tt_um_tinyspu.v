module tt_um_tinyspu (
    input  wire [7:0] ui_in,   // [7:4] = Op, [3:0] = Q
    output wire [7:0] uo_out,  // [7:4] = M,  [3:0] = N
    input  wire [7:0] uio_in,  // [7:4] = A/C, [3:0] = B/D, based on Q command
    output wire [7:0] uio_out, // Tied to zero
    output wire [7:0] uio_oe,  // Tied to zero
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n    // Active low reset
);

    // Generate active-high internal reset.
    wire reset = ~rst_n;

    // Data registers for operations, inputs, and outputs
    reg [3:0] Op_reg, Q_reg; // Operations
    reg [3:0] A_reg, B_reg, C_reg, D_reg; // Inputs
    reg [3:0] M_reg, N_reg;  // Outputs


    /* Q MUX Operation Section */
    /*
	Design explanation - why the ISA was designed in a certain way...
	0000 NOP - Special case, just pass through
	00xx all others it means zero out CD, AB, or ABCD

	01xx - that means select UIO as the Input (this will be most cases)

	10xx - that means select MN as the Input (this will not be as common)

	11xx - reserved/open (no current use case at the moment...)
		Note: If there are no use cases, then I might make it 1s to CD, AB, or ABCD 
		      This would follow the 00xx design, but be 1's instead of 0's

	xx01 - take input and select CD as Output
	xx10 - take input and select AB as Output
	xx11 - take input and duplicate A/C=high, B/D=low
	xx00 - take input and duplicate, but this time A/B=high, B/D=low (rare?)
    */
    // Always block to capture Op and Q, and execute
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Op_reg <= 4'd0;
            Q_reg  <= 4'd0;
            A_reg  <= 4'd0;
            B_reg  <= 4'd0;
            C_reg  <= 4'd0;
            D_reg  <= 4'd0;
        end else if (ena) begin
            // Latch the command from ui_in.
            Op_reg <= ui_in[7:4];
            Q_reg  <= ui_in[3:0];
            
            // Use the incoming Q command to decide which data to capture.
            case (ui_in[3:0])
              4'b0000: begin 
                        {A_reg, B_reg} <= {A_reg, B_reg};  // NOP: hold A and B  
                        {C_reg, D_reg} <= {C_reg, D_reg};    // NOP: hold C and D  
                      end
              4'b0001: begin 
                        {A_reg, B_reg} <= {A_reg, B_reg};         // ZeroCD: hold A and B  
                        {C_reg, D_reg} <= {4'b0000, 4'b0000};       // ZeroCD: zero out C and D  
                      end
              4'b0010: begin 
                        {A_reg, B_reg} <= {4'b0000, 4'b0000};       // ZeroAB: zero out A and B  
                        {C_reg, D_reg} <= {C_reg, D_reg};           // ZeroAB: hold C and D  
                      end
              4'b0011: begin 
                        {A_reg, B_reg} <= {4'b0000, 4'b0000};       // ZeroABCD: zero out A and B  
                        {C_reg, D_reg} <= {4'b0000, 4'b0000};       // ZeroABCD: zero out C and D  
                      end
              4'b0100: begin 
                        {A_reg, B_reg} <= {uio_in[7:4], uio_in[7:4]}; // UIOACBD: load A/B from UIOh  
                        {C_reg, D_reg} <= {uio_in[3:0], uio_in[3:0]}; // UIOACBD: load C/D from UIOl  
                      end
              4'b0101: begin 
                        {A_reg, B_reg} <= {A_reg, B_reg};           // UIOCD: hold A and B  
                        {C_reg, D_reg} <= {uio_in[7:4], uio_in[3:0]}; // UIOCD: load C (UIOh) and D (UIOl)  
                      end
              4'b0110: begin 
                        {A_reg, B_reg} <= {uio_in[7:4], uio_in[3:0]}; // UIOAB: load A (UIOh) and B (UIOl)  
                        {C_reg, D_reg} <= {C_reg, D_reg};           // UIOAB: hold C and D  
                      end
              4'b0111: begin 
                        {A_reg, B_reg} <= {uio_in[7:4], uio_in[3:0]}; // UIOABCD: load A/B from UIO  
                        {C_reg, D_reg} <= {uio_in[7:4], uio_in[3:0]}; // UIOABCD: load C/D from UIO  
                      end
              4'b1000: begin 
                        {A_reg, B_reg} <= {M_reg, M_reg};           // MNACBD: load A/B from M  
                        {C_reg, D_reg} <= {N_reg, N_reg};           // MNACBD: load C/D from N  
                      end
              4'b1001: begin 
                        {A_reg, B_reg} <= {A_reg, B_reg};           // MNCD: hold A and B  
                        {C_reg, D_reg} <= {M_reg, N_reg};           // MNCD: load C (M) and D (N)  
                      end
              4'b1010: begin 
                        {A_reg, B_reg} <= {M_reg, N_reg};           // MNAB: load A (M) and B (N)  
                        {C_reg, D_reg} <= {C_reg, D_reg};           // MNAB: hold C and D  
                      end
              4'b1011: begin 
                        {A_reg, B_reg} <= {M_reg, N_reg};           // MNABCD: load A/B from M/N  
                        {C_reg, D_reg} <= {M_reg, N_reg};           // MNABCD: load C/D from M/N  
                      end
              4'b1100: {C_reg, D_reg} <= {4'b1111, 4'b1111}; // Reserved: OneCD - set C and D to ones  
              4'b1101: {A_reg, B_reg} <= {4'b1111, 4'b1111}; // Reserved: OneAB - set A and B to ones  
              4'b1110: {A_reg, B_reg, C_reg, D_reg} <= {4'b1111, 4'b1111, 4'b1111, 4'b1111}; // Reserved: All ones - set all registers to ones  
              4'b1111: {A_reg, B_reg, C_reg, D_reg} <= {4'b1111, 4'b1111, 4'b1111, 4'b1111}; // Reserved: All ones - set all registers to ones  
              
              default: begin 
                         {A_reg, B_reg} <= {A_reg, B_reg};     // Default: hold A and B  
                         {C_reg, D_reg} <= {C_reg, D_reg};     // Default: hold C and D  
                       end
            endcase
        end
    end

    // Local wires to drive the operation modules.
    wire [3:0] A = A_reg;
    wire [3:0] B = B_reg;
    wire [3:0] C = C_reg;
    wire [3:0] D = D_reg;
    wire [3:0] Op = Op_reg;

    /* Tiny SPU Section */

    // Declare wires for the outputs from each operation module.
    wire [3:0] M0, N0;
    wire [3:0] M1, N1;
    wire [3:0] M2, N2;
    wire [3:0] M3, N3;
    wire [3:0] M4, N4;
    wire [3:0] M5, N5;
    wire [3:0] M6, N6;
    wire [3:0] M7, N7;
    wire [3:0] M8, N8;
    wire [3:0] M9, N9;
    wire [3:0] M10, N10;
    wire [3:0] M11, N11;
    wire [3:0] M12, N12;
    wire [3:0] M13, N13;
    wire [3:0] M14, N14;
    wire [3:0] M15, N15;

    // Instantiate operation modules:
    // Control SPU Ops
    NOP op0000 (.current_M(M_reg), .current_N(N_reg), .A(A), .B(B), .C(C), .D(D), .M(M0), .N(N0));
    MinGate       op0001 (.A(A), .B(B), .C(C), .D(D), .M(M1),  .N(N1));
    EqGate        op0010 (.A(A), .B(B), .C(C), .D(D), .M(M2),  .N(N2));
    ZeroMN        op0011 (.A(A), .B(B), .C(C), .D(D), .M(M3),  .N(N3));

    // Dusal 4-bit Vector Ops
    DistDir       op0100 (.A(A), .B(B), .C(C), .D(D), .M(M4),  .N(N4));  
    VectorBoxArea op0101 (.A(A), .B(B), .C(C), .D(D), .M(M5),  .N(N5));
    BasicBuffer   op0110 (.A(A), .B(B), .C(C), .D(D), .M(M6),  .N(N6));
    AttrReclass   op0111 (.A(A), .B(B), .C(C), .D(D), .M(M7),  .N(N7));

    // Dual 4-bit Raster Ops
    FocalMeanRow  op1000 (.A(A), .B(B), .C(C), .D(D), .M(M8),  .N(N8)); 
    FocalSumRow   op1001 (.A(A), .B(B), .C(C), .D(D), .M(M9),  .N(N9));
    LocalDiv      op1010 (.A(A), .B(B), .C(C), .D(D), .M(M10), .N(N10));
    FocalMaxPoolRow op1011 (.A(A), .B(B), .C(C), .D(D), .M(M11), .N(N11));

    // Multispectral raster operations
    NormDiffIndex op1100 (.A(A), .B(B), .C(C), .D(D), .M(M12), .N(N12)); 
    LocalCodeOp   op1101 (.A(A), .B(B), .C(C), .D(D), .M(M13), .N(N13)); 

    // Single 8-bit Ops
    MHDist8       op1110 (.A(A), .B(B), .C(C), .D(D), .M(M14), .N(N14));
    DotProduct    op1111 (.A(A), .B(B), .C(C), .D(D), .M(M15), .N(N15));

    // Multiplexer: select the outputs based on the Op command.
    reg [3:0] Mt, Nt;
    always @(*) begin
        case (Op)
            4'd0:  begin Mt = M0;   Nt = N0;   end
            4'd1:  begin Mt = M1;   Nt = N1;   end
            4'd2:  begin Mt = M2;   Nt = N2;   end
            4'd3:  begin Mt = M3;   Nt = N3;   end
            4'd4:  begin Mt = M4;   Nt = N4;   end
            4'd5:  begin Mt = M5;   Nt = N5;   end
            4'd6:  begin Mt = M6;   Nt = N6;   end
            4'd7:  begin Mt = M7;   Nt = N7;   end
            4'd8:  begin Mt = M8;   Nt = N8;   end
            4'd9:  begin Mt = M9;   Nt = N9;   end
            4'd10: begin Mt = M10;  Nt = N10;  end
            4'd11: begin Mt = M11;  Nt = N11;  end
            4'd12: begin Mt = M12;  Nt = N12;  end
            4'd13: begin Mt = M13;  Nt = N13;  end
            4'd14: begin Mt = M14;  Nt = N14;  end
            4'd15: begin Mt = M15;  Nt = N15;  end
            default: begin Mt = 4'd0; Nt = 4'd0; end
        endcase
    end

    // Register the multiplexer outputs to produce final outputs.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            M_reg <= 4'd0;
            N_reg <= 4'd0;
        end else begin
            M_reg <= Mt;
            N_reg <= Nt;
        end
    end

    // Drive the design output.
    assign uo_out = {M_reg, N_reg};

    // Tie unused outputs to zero.
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

endmodule
