module main;

    // Testbench signals for DUT I/O (using the original DUT interface)
    reg  [7:0] ui_in;   // [7:4]=Op, [3:0]=Q
    wire [7:0] uo_out;  // [7:4]=M, [3:0]=N
    reg  [7:0] uio_in;  // [7:4]=A/C, [3:0]=B/D
    wire [7:0] uio_out; // Not used in this testbench
    wire [7:0] uio_oe;  // Not used in this testbench
    reg        ena;
    reg        clk;
    reg        rst_n;

    // Internal registers for holding test values
    reg [3:0] A, B, C, D;
    reg [3:0] Op;
    reg [3:0] Q;

    // Localparams for Q-mux commands (to load registers)
    localparam [3:0] Q_AB_LOAD = 4'b0110;
    localparam [3:0] Q_CD_LOAD = 4'b0101;

    // Define localparams for opcodes
    localparam [3:0] OP_NOP           = 4'b0000;
    localparam [3:0] OP_MINGATE       = 4'b0001;
    localparam [3:0] OP_EQGATE        = 4'b0010;
    localparam [3:0] OP_ZEROMN        = 4'b0011;
    localparam [3:0] OP_DISTDIR       = 4'b0100;
    localparam [3:0] OP_VECTORBOXAREA = 4'b0101;
    localparam [3:0] OP_BASICBUFFER   = 4'b0110;
    localparam [3:0] OP_ATTRRECLASS   = 4'b0111;
    localparam [3:0] OP_FOCALMEANROW  = 4'b1000;
    localparam [3:0] OP_FOCALSUMROW   = 4'b1001;
    localparam [3:0] OP_LOCALDIV      = 4'b1010;
    localparam [3:0] OP_FOCALMAXPOOLROW = 4'b1011;
    localparam [3:0] OP_NORMDIFFINDEX = 4'b1100;
    localparam [3:0] OP_LOCALCODEOP   = 4'b1101;
    localparam [3:0] OP_MHDIST8       = 4'b1110;
    localparam [3:0] OP_DOTPRODUCT    = 4'b1111;

    // Instantiate the DUT (using your original DUT module)
    tt_um_tinyspu dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation: toggle every 10ns (50 MHz)
    always #10 clk = ~clk;

    // Task to run an individual test:
    // It loads A/B and C/D using the Q-mux, applies the operation, then checks outputs.
    task run_test;
        input [3:0] A_val, B_val, C_val, D_val, Op_val;
        input [3:0] Expected_M, Expected_N;
        begin
            // --- Load A and B ---
            A = A_val;
            B = B_val;
            Q = Q_AB_LOAD;                   // Q command for loading A and B
            ui_in  = {4'b0000, Q};           // No operation; just loading registers via Q
            uio_in = {A, B};                 // Place A in upper 4 bits, B in lower 4 bits
            #40;                             // Wait for data propagation

            // --- Load C and D ---
            C = C_val;
            D = D_val;
            Q = Q_CD_LOAD;                   // Q command for loading C and D
            ui_in  = {4'b0000, Q};           // No operation; just loading registers via Q
            uio_in = {C, D};                 // Place C in upper 4 bits, D in lower 4 bits
            #40;                             // Wait for data propagation

            // --- Execute the operation ---
            Op = Op_val;
            Q  = 4'b0000;                   // Q=0 ensures no register update during op
            ui_in = {Op, Q};                // Apply the operation
            #40;                            // Allow time for processing

            // --- Check the outputs ---
            if (uo_out[7:4] === Expected_M && uo_out[3:0] === Expected_N) begin
                $display("PASS: Op=%b, A=%d, B=%d, C=%d, D=%d -> M: expected %d, got %d; N: expected %d, got %d", 
                         Op_val, A_val, B_val, C_val, D_val, Expected_M, uo_out[7:4], Expected_N, uo_out[3:0]);
            end
            else begin
                $display(" ");
                $display("!!!!!!------!!!!!!");
                $display("ERROR: Op=%b, A=%d, B=%d, C=%d, D=%d -> M: expected %d, got %d; N: expected %d, got %d", 
                         Op_val, A_val, B_val, C_val, D_val, Expected_M, uo_out[7:4], Expected_N, uo_out[3:0]);
                $display("!!!!!!------!!!!!!");
                $display(" ");
            end

            #20; // Optional delay between tests
        end
    endtask

    // Test sequence: Initialize, reset, and then run a series of tests.
    initial begin
        // Initialization
        clk   = 0;
        rst_n = 1;
        ena   = 0;
        ui_in = 8'b0;
        uio_in = 8'b0;

        // Reset pulse sequence
        #50 rst_n = 0;
        #50 rst_n = 1;

        // Enable the design
        #30 ena = 1;
        $display("Starting testbench...");
        $display("For vector operations: A, B correspond to point coordinate (x1, y1); C, D correspond to point coordinate (x2, y2)");
        
        
        /*
        ERROR test
        Testing NOP, ONEMN, and DISTDIR with incorrect expected values
        Expecation: all tests will error. This is to ensure error testing functions.
        opcode value: 0000, 0001, 0100
        M: depends on OpCode, incorrect expected value is input
        N: depends on OpCode, incorrect expected value is input
        */
        $display(" ");
        $display("ERROR Test");
        run_test(4'd1, 4'd2, 4'd3, 4'd4, OP_ZEROMN,        4'd1, 4'd0); //NOP with incorrect M
        run_test(4'd1, 4'd2, 4'd3, 4'd4, OP_NOP,           4'd0, 4'd1); //NOP with incorrect N
        run_test(4'd1, 4'd2, 4'd3, 4'd4, OP_NOP,           4'd1, 4'd1); //NOP with both M & N incorrect
        run_test(4'd1, 4'd2, 4'd3, 4'd4, OP_EQGATE,         4'd0, 4'd1); //OneMN with M incorrect
        run_test(4'd2, 4'd2, 4'd4, 4'd4, OP_DISTDIR,       4'd0, 4'd0); //DistDir with M and N incorrect
        
        
        /*
        NOP opcode test
        No operation, output previous M and N values
        opcode value: 0000
        M: no calculation -- stays same M as previous
        N: no calculation -- stays same N as previous
        */
        $display(" ");
        $display("Test of OpCode 0000 -- NOP");
        run_test(4'd1, 4'd2, 4'd3, 4'd4,             OP_ZEROMN,  4'd0, 4'd0); //zero out M and N
        run_test(4'd1, 4'd2, 4'd3, 4'd4,             OP_NOP,     4'd0, 4'd0); //test NOP
        run_test(4'd0, 4'd0, 4'd15, 4'd15,           OP_NOP,     4'd0, 4'd0); 
        run_test(4'd2, 4'd6, 4'd5, 4'd3,             OP_DISTDIR, 4'd6, 4'd3); //Set M and N to 6 and 3
        run_test(4'd15, 4'd15, 4'd0, 4'd0,           OP_NOP,     4'd6, 4'd3);
        run_test(4'b0000, 4'b0000, 4'b0000, 4'b0000, OP_NOP,     4'd6, 4'd3);
        run_test(4'b1111, 4'b1111, 4'b1111, 4'b1111, OP_NOP,     4'd6, 4'd3);
        
        
        /*
        MIN GATE opcode test
        Comparison of minimum value of B and D
        opcode value: 0001
        M = A if (B < D) else C 
        N = min(B, D)
        */
        $display(" ");
        $display("Test of OpCode 0001 -- MIN GATE");
        
        run_test(4'd4, 4'd2, 4'd7, 4'd5, OP_MINGATE, 4'd4, 4'd2); // B < D: M = A, N = B
        run_test(4'd1, 4'd9, 4'd3, 4'd4, OP_MINGATE, 4'd3, 4'd4); // B > D: M = C, N = D
        run_test(4'd8, 4'd6, 4'd2, 4'd6, OP_MINGATE, 4'd2, 4'd6); // B == D: M = C, N = B
        run_test(4'd15, 4'd0, 4'd8, 4'd15, OP_MINGATE, 4'd15, 4'd0); // Extreme: B = 0, D = 15, so M = A, N = B
        

        /*
        EQ GATE opcode test
        Comparison of equality of B and D
        opcode: 0010
        M = A if (B == D) else C 
        N = D
        */
        $display(" ");
        $display("Test of OpCode 0010 -- EQ GATE");
        
        run_test(4'd2, 4'd5, 4'd7, 4'd5, OP_EQGATE, 4'd2, 4'd5); // B == D: M = A, N = D
        run_test(4'd1, 4'd3, 4'd9, 4'd4, OP_EQGATE, 4'd9, 4'd4); // B != D: M = C, N = D
        run_test(4'd12, 4'd0, 4'd5, 4'd0, OP_EQGATE, 4'd12, 4'd0); // Lower bound: B = 0, D = 0, M = A, N = 0
        run_test(4'd8, 4'd15, 4'd3, 4'd15, OP_EQGATE, 4'd8, 4'd15); // Upper bound: B = 15, D = 15, M = A, N = 15
        
        
        /*
        ZEROMN opcode test
        Always output a value of 0
        opcode value: 0011
        M: always 0
        N: always 0
        */
        $display(" ");
        $display("Test of OpCode 0010 -- OP_ZEROMN");
        run_test(4'd1, 4'd2, 4'd3, 4'd4,             OP_ZEROMN, 4'd0, 4'd0);
        run_test(4'd0, 4'd0, 4'd15, 4'd15,           OP_ZEROMN, 4'd0, 4'd0);
        run_test(4'd15, 4'd15, 4'd0, 4'd0,           OP_ZEROMN, 4'd0, 4'd0);
        run_test(4'b0000, 4'b0000, 4'b0000, 4'b0000, OP_ZEROMN, 4'd0, 4'd0);
        run_test(4'b1111, 4'b1111, 4'b1111, 4'b1111, OP_ZEROMN, 4'd0, 4'd0);
        
        
        /*
        DISTDIR opcode test
        Calculate Manhattan Distance & Aspect Direction
        opcode value: 0100
        M: Manhattan Distance = |A - C| + |B - D|; (4-bit, modulo 16)
        N: Aspect Direction -- N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7
        */
        $display(" ");
        $display("Test of OpCode 0010 -- OP_DISTDIR");
        run_test(4'd2, 4'd3, 4'd2, 4'd3, OP_DISTDIR, 4'd0, 4'd0); // Same Point (No Displacement)
        run_test(4'd2, 4'd3, 4'd2, 4'd6, OP_DISTDIR, 4'd3, 4'd0); // Vertical (North)
        run_test(4'd2, 4'd6, 4'd2, 4'd3, OP_DISTDIR, 4'd3, 4'd4); // Vertical (South)
        run_test(4'd2, 4'd3, 4'd5, 4'd3, OP_DISTDIR, 4'd3, 4'd2); // Horizontal (East)
        run_test(4'd5, 4'd3, 4'd2, 4'd3, OP_DISTDIR, 4'd3, 4'd6); // Horizontal (West)
        run_test(4'd2, 4'd3, 4'd5, 4'd6, OP_DISTDIR, 4'd6, 4'd1); // Diagonal Northeast (NE)
        run_test(4'd2, 4'd6, 4'd5, 4'd3, OP_DISTDIR, 4'd6, 4'd3); // Diagonal Southeast (SE)
        run_test(4'd5, 4'd6, 4'd2, 4'd3, OP_DISTDIR, 4'd6, 4'd5); // Diagonal Southwest (SW)
        run_test(4'd5, 4'd3, 4'd2, 4'd6, OP_DISTDIR, 4'd6, 4'd7); // Diagonal Northwest (NW)
        run_test(4'd15, 4'd0, 4'd0, 4'd15, OP_DISTDIR, 4'd14, 4'd7); // Extreme Case - Maximum Difference (NW)
        run_test(4'd0, 4'd15, 4'd15, 4'd0, OP_DISTDIR, 4'd14, 4'd3); // Extreme Case - Reverse Maximum (SE)
        run_test(4'd0, 4'd0, 4'd15, 4'd15, OP_DISTDIR, 4'd14, 4'd1); // Extreme Diagonal - Opposite Corners (NE)
        run_test(4'd1, 4'd14, 4'd14, 4'd1, OP_DISTDIR, 4'd10, 4'd3); // Large Diagonal with Unequal Intermediate Values (SE)
        run_test(4'd8, 4'd8, 4'd9, 4'd8, OP_DISTDIR, 4'd1, 4'd2); // Small Horizontal Step (East)
        run_test(4'd8, 4'd8, 4'd8, 4'd9, OP_DISTDIR, 4'd1, 4'd0); // Small Vertical Step (North)
        run_test(4'd9, 4'd3, 4'd6, 4'd7, OP_DISTDIR, 4'd7, 4'd7); // Diagonal with Unequal ΔX/ΔY (NW)
        run_test(4'd3, 4'd10, 4'd7, 4'd8, OP_DISTDIR, 4'd6, 4'd3); // Non-Symmetric Diagonal (SE)
        run_test(4'd7, 4'd8, 4'd3, 4'd10, OP_DISTDIR, 4'd6, 4'd7); // Reverse of Above (NW)
        run_test(4'd0, 4'd15, 4'd0, 4'd14, OP_DISTDIR, 4'd1, 4'd4); // Edge - Vertical (South) with Lower Bound
        run_test(4'd15, 4'd15, 4'd15, 4'd0, OP_DISTDIR, 4'd15, 4'd4); // Edge - Vertical (South) from Max Values
        run_test(4'd15, 4'd15, 4'd0, 4'd15, OP_DISTDIR, 4'd15, 4'd6); // Edge - Horizontal (West) from Max Values


        /*
        VECTOR BOX AREA opcode test
        Calculate Area and Perimeter of bounding box
        opcode value: 0101
        M: Area = |(A - C)| * |(B - D)|; (4-bit, modulo 16)
        N: Perimeter = 2*|A - C| + 2*|B - D|; (4-bit, modulo 16)
        */
        $display(" ");
        $display("Test of OpCode 0101 -- VECTOR BOX AREA");
        run_test(4'd4, 4'd4, 4'd4, 4'd4, OP_VECTORBOXAREA, 4'd0, 4'd0);  // Degenerate point: area=0, perimeter=0
        run_test(4'd2, 4'd3, 4'd5, 4'd3, OP_VECTORBOXAREA, 4'd0, 4'd6);  // Horizontal line: area=0, perimeter=6
        run_test(4'd6, 4'd2, 4'd6, 4'd9, OP_VECTORBOXAREA, 4'd0, 4'd14); // Vertical line: area=0, perimeter=14
        run_test(4'd4, 4'd6, 4'd1, 4'd4, OP_VECTORBOXAREA, 4'd6, 4'd10); // Standard rectangle (no overflow): |4-1|=3, |6-4|=2 -> area=6, perimeter=10
        run_test(4'd1, 4'd4, 4'd4, 4'd6, OP_VECTORBOXAREA, 4'd6, 4'd10); // Standard rectangle flipped bounding box (no overflow): |4-1|=3, |6-4|=2 -> area=6, perimeter=10
        run_test(4'd0, 4'd0, 4'd15, 4'd15, OP_VECTORBOXAREA, 4'd1, 4'd12); // Extreme: |0-15|=15, area=225 mod16=1, perimeter=60 mod16=12
        

        /*
        BASIC BUFFER opcode test
        Create a buffered point location given X and Y, buffer distance of 2.
        opcode value: 0110
        Operation:
            If B == D (horizontal alignment):
                M = (C > A) ? (A - 2) : (A + 2)
                N = (C > A) ? (B - 2) : (B + 2)
            Else if A == C (vertical alignment):
                M = (D > B) ? (A + 2) : (A - 2)
                N = (D > B) ? (B - 2) : (B + 2)
            Else:
                M = A, N = B
        */
        $display(" ");
        $display("Test of OpCode 0110 -- BASIC BUFFER");
        run_test(4'd4, 4'd5, 4'd7, 4'd5, OP_BASICBUFFER, 4'd2, 4'd3); // Horizontal, C>A: B==D, so M=A-2, N=B-2
        run_test(4'd7, 4'd5, 4'd3, 4'd5, OP_BASICBUFFER, 4'd9, 4'd7); // Horizontal, C<=A: B==D, so M=A+2, N=B+2
        run_test(4'd4, 4'd4, 4'd4, 4'd7, OP_BASICBUFFER, 4'd6, 4'd2); // Vertical, D>B: A==C, so M=A+2, N=B-2
        run_test(4'd8, 4'd7, 4'd8, 4'd4, OP_BASICBUFFER, 4'd6, 4'd9); // Vertical, D<=B: A==C, so M=A-2, N=B+2
        run_test(4'd3, 4'd2, 4'd5, 4'd6, OP_BASICBUFFER, 4'd3, 4'd2); // Non-aligned: neither horizontal nor vertical, so M=A, N=B
        
        
        /*
        ATTR RECLASS opcode test
        Attribute reclassification
        opcode 0111
        Operation:
            M = 3-class reclassification:
                 if (C > A) then 1
                 else if (C <= A && C >= B) then 2
                 else 3
            N = 2-class reclassification:
                 if (C >= D) then 0
                 else 5
        */
        $display(" ");
        $display("Test of OpCode 0111 -- ATTR RECLASS");
        run_test(4'd2, 4'd1, 4'd3, 4'd2, OP_ATTRRECLASS, 4'd1, 4'd0); // C>A and C>=D: M=1, N=0
        run_test(4'd2, 4'd1, 4'd3, 4'd4, OP_ATTRRECLASS, 4'd1, 4'd5); // C>A and C<D:  M=1, N=5
        run_test(4'd5, 4'd3, 4'd4, 4'd2, OP_ATTRRECLASS, 4'd2, 4'd0); // C<=A, C>=B and C>=D: M=2, N=0
        run_test(4'd5, 4'd3, 4'd4, 4'd7, OP_ATTRRECLASS, 4'd2, 4'd5); // C<=A, C>=B and C<D:  M=2, N=5
        run_test(4'd5, 4'd6, 4'd4, 4'd2, OP_ATTRRECLASS, 4'd3, 4'd0); // C<=A, C<B and C>=D: M=3, N=0
        run_test(4'd5, 4'd6, 4'd4, 4'd7, OP_ATTRRECLASS, 4'd3, 4'd5); // C<=A, C<B and C<D:  M=3, N=5
    
        
        /*
        FOCAL MEAN ROW opcode test
        Operation:
            M = (A+B+C) / 3
            N = (B+C+D) / 3
        */
        $display(" ");
        $display("Test of OpCode 1000 -- FocalMeanRow");
        run_test(4'd0, 4'd0, 4'd0, 4'd0, OP_FOCALMEANROW, 4'd0, 4'd0);  // All zeros: (0+0+0)/3 = 0, (0+0+0)/3 = 0
        run_test(4'd4, 4'd5, 4'd7, 4'd8, OP_FOCALMEANROW, 4'd5, 4'd6);  // Normal: M=(4+5+7)/3=16/3=5, N=(5+7+8)/3=20/3=6
        run_test(4'd15, 4'd15, 4'd15, 4'd15, OP_FOCALMEANROW, 4'd15, 4'd15);  // All max: (15+15+15)/3 = 45/3 = 15
        
        
        /*
        FOCAL SUM ROW opcode test
        Operation:
            M = (A+B+C)
            N = (B+C+D)
        */
        $display(" ");
        $display("Test of OpCode 1001 -- FocalSumRow");
        run_test(4'd0, 4'd0, 4'd0, 4'd0, OP_FOCALSUMROW, 4'd0, 4'd0);  // All zeros: 0+0+0 = 0, 0+0+0 = 0
        run_test(4'd3, 4'd4, 4'd5, 4'd6, OP_FOCALSUMROW, 4'd12, 4'd15); // Normal: M=3+4+5=12, N=4+5+6=15
        run_test(4'd15, 4'd15, 4'd15, 4'd15, OP_FOCALSUMROW, 4'd13, 4'd13); // All max: 15+15+15=45 mod16 = 13, 45 mod16 = 13
        
        
        /*
        FOCAL MAX POOL ROW opcode test
        Operation:
            M = max(A, B)
            N = max(C, D)
        */
        $display(" ");
        $display("Test of OpCode 1011 -- FocalMaxPoolRow");
        
        run_test(4'd5, 4'd5, 4'd7, 4'd7, OP_FOCALMAXPOOLROW, 4'd5, 4'd7);  // Equal inputs: M = 5, N = 7
        run_test(4'd9, 4'd4, 4'd12, 4'd3, OP_FOCALMAXPOOLROW, 4'd9, 4'd12); // A > B and C > D: M = 9, N = 12
        run_test(4'd2, 4'd8, 4'd1, 4'd6, OP_FOCALMAXPOOLROW, 4'd8, 4'd6);  // A < B and C < D: M = 8, N = 6
        run_test(4'd0, 4'd15, 4'd15, 4'd0, OP_FOCALMAXPOOLROW, 4'd15, 4'd15); // Extreme values: M = max(0,15)=15, N = max(15,0)=15
        

        /*
        NORM DIFF INDEX opcode test
        Operation:
            M = clip(8 + (8*(A-C))/(A+C)) to 4 bits; if (A+C)==0 then M=0
            N = clip(8 + (8*(B-D))/(B+D)) to 4 bits; if (B+D)==0 then N=0
        */
        $display(" ");
        $display("Test of OpCode 1100 -- NormDiffIndex");
        
        run_test(4'd0, 4'd0, 4'd0, 4'd0, OP_NORMDIFFINDEX, 4'd0, 4'd0); // Denom zero for both: A+C==0 and B+D==0 => M,N=0
        run_test(4'd15, 4'd15, 4'd0, 4'd0, OP_NORMDIFFINDEX, 4'd15, 4'd15); // Maximum positive diff (clipping): (15-0)/(15+0)=1 -> 8+8=16 clipped to 15
        run_test(4'd12, 4'd10, 4'd4, 4'd2, OP_NORMDIFFINDEX, 4'd12, 4'd13); // Normal positive: M=8+(8*8/16)=12, N=8+(8*8/12)=13
        run_test(4'd4, 4'd7, 4'd8, 4'd9, OP_NORMDIFFINDEX, 4'd6, 4'd7); // Normal negative: M=8+(8*(-4)/12)=6, N=8+(8*(-2)/16)=7
        run_test(4'd8, 4'd0, 4'd4, 4'd0, OP_NORMDIFFINDEX, 4'd10, 4'd0); // Denom zero for N only: for M: 8+(8*4/12)=10; for N: B+D==0 => N=0
        
        
        /*
        LOCAL CODE OP opcode test
        Operation:
            M = (A op1 B) where op1 is defined by D[3:2]:
                 00: A & B
                 01: A | B
                 10: A + B
                 11: A * B
            N = (M op2 C) where op2 is defined by D[1:0]:
                 00: M & C
                 01: M | C
                 10: M + C
                 11: M * C
        Note: All results are taken modulo 16 (lower 4 bits).
        */
        $display(" ");
        $display("Test of OpCode 1101 -- LocalCodeOp");
        
        // Using normal case inputs: A=5, B=3, C=6
        run_test(4'd5, 4'd3, 4'd6, 4'd0, OP_LOCALCODEOP, 4'd1, 4'd0);  // D=0: op1=AND,  op2=AND: M = 5&3 = 1;    N = 1 & 6 = 0
        run_test(4'd5, 4'd3, 4'd6, 4'd1, OP_LOCALCODEOP, 4'd1, 4'd7);  // D=1: op1=AND,  op2=OR:  M = 1;         N = 1 | 6 = 7
        run_test(4'd5, 4'd3, 4'd6, 4'd2, OP_LOCALCODEOP, 4'd1, 4'd7);  // D=2: op1=AND,  op2=ADD: M = 1;         N = 1 + 6 = 7
        run_test(4'd5, 4'd3, 4'd6, 4'd3, OP_LOCALCODEOP, 4'd1, 4'd6);  // D=3: op1=AND,  op2=MUL: M = 1;         N = 1 * 6 = 6
        
        run_test(4'd5, 4'd3, 4'd6, 4'd4, OP_LOCALCODEOP, 4'd7, 4'd6);  // D=4: op1=OR,   op2=AND: M = 5|3 = 7;       N = 7 & 6 = 6
        run_test(4'd5, 4'd3, 4'd6, 4'd5, OP_LOCALCODEOP, 4'd7, 4'd7);  // D=5: op1=OR,   op2=OR:  M = 7;           N = 7 | 6 = 7
        run_test(4'd5, 4'd3, 4'd6, 4'd6, OP_LOCALCODEOP, 4'd7, 4'd13); // D=6: op1=OR,   op2=ADD: M = 7;           N = 7 + 6 = 13
        run_test(4'd5, 4'd3, 4'd6, 4'd7, OP_LOCALCODEOP, 4'd7, 4'd10); // D=7: op1=OR,   op2=MUL: M = 7;           N = 7 * 6 = 42 mod16 = 10
        
        run_test(4'd5, 4'd3, 4'd6, 4'd8, OP_LOCALCODEOP, 4'd8, 4'd0);  // D=8: op1=ADD,  op2=AND: M = 5+3 = 8;       N = 8 & 6 = 0
        run_test(4'd5, 4'd3, 4'd6, 4'd9, OP_LOCALCODEOP, 4'd8, 4'd14); // D=9: op1=ADD,  op2=OR:  M = 8;           N = 8 | 6 = 14
        run_test(4'd5, 4'd3, 4'd6, 4'd10, OP_LOCALCODEOP, 4'd8, 4'd14); // D=10: op1=ADD, op2=ADD: M = 8;           N = 8 + 6 = 14
        run_test(4'd5, 4'd3, 4'd6, 4'd11, OP_LOCALCODEOP, 4'd8, 4'd0);  // D=11: op1=ADD, op2=MUL: M = 8;           N = 8 * 6 = 48 mod16 = 0
        
        run_test(4'd5, 4'd3, 4'd6, 4'd12, OP_LOCALCODEOP, 4'd15, 4'd6); // D=12: op1=MUL,  op2=AND: M = 5*3 = 15;      N = 15 & 6 = 6
        run_test(4'd5, 4'd3, 4'd6, 4'd13, OP_LOCALCODEOP, 4'd15, 4'd15); // D=13: op1=MUL,  op2=OR:  M = 15;          N = 15 | 6 = 15
        run_test(4'd5, 4'd3, 4'd6, 4'd14, OP_LOCALCODEOP, 4'd15, 4'd5);  // D=14: op1=MUL,  op2=ADD: M = 15;          N = 15 + 6 = 21 mod16 = 5
        run_test(4'd5, 4'd3, 4'd6, 4'd15, OP_LOCALCODEOP, 4'd15, 4'd10); // D=15: op1=MUL,  op2=MUL: M = 15;          N = 15 * 6 = 90 mod16 = 10
        
        run_test(4'd15, 4'd10, 4'd15, 4'd10, OP_LOCALCODEOP, 4'd9, 4'd8);  // D=10: op1=ADD, op2=ADD: M = 15+10 = 25 mod16 = 9; N = 25+15 = 40 mod16 = 8
        run_test(4'd15, 4'd15, 4'd15, 4'd15, OP_LOCALCODEOP, 4'd1, 4'd15); // D=15: op1=MUL, op2=MUL: M = 15*15 = 225 mod16 = 1; N = 1*15 = 15
        
        
        /*
        MHDist8 opcode test
        Operation:
            Compute Manhattan distance = |A - C| + |B - D| (8-bit value)
            M = high 4 bits, N = low 4 bits of the distance
        */
        $display(" ");
        $display("Test of OpCode 1110 -- MHDist8");
        
        run_test(4'd5, 4'd5, 4'd5, 4'd5, OP_MHDIST8, 4'd0, 4'd0);   // Degenerate: same points => distance 0 (high=0, low=0)
        run_test(4'd4, 4'd6, 4'd1, 4'd3, OP_MHDIST8, 4'd0, 4'd6);   // Normal: |4-1|=3, |6-3|=3, sum=6 => high=0, low=6
        run_test(4'd15, 4'd0, 4'd0, 4'd0, OP_MHDIST8, 4'd0, 4'd15);  // Edge: |15-0|=15, |0-0|=0, sum=15 => high=0, low=15
        run_test(4'd15, 4'd15, 4'd0, 4'd0, OP_MHDIST8, 4'd1, 4'd14); // Max diff: |15-0|=15, |15-0|=15, sum=30 => high=1, low=14
        run_test(4'd10, 4'd12, 4'd2, 4'd3, OP_MHDIST8, 4'd1, 4'd1);  // In-between: |10-2|=8, |12-3|=9, sum=17 => high=1, low=1
        

        /*
        DOT PRODUCT opcode test
        Operation:
            prod = A * B (8-bit result)
            accum = {C, D} (concatenation of C (high 4-bits) and D (low 4-bits))
            sum = prod + accum (8-bit, modulo 256)
            M = sum[7:4] (high nibble)
            N = sum[3:0] (low nibble)
        */
        $display(" ");
        $display("Test of OpCode 1111 -- DotProduct");
        
        run_test(4'd0, 4'd0, 4'd0, 4'd0, OP_DOTPRODUCT, 4'd0, 4'd0);    // All zeros: prod=0, accum=0, sum=0 -> M=0, N=0
        run_test(4'd3, 4'd2, 4'd1, 4'd4, OP_DOTPRODUCT, 4'd1, 4'd10);   // Normal: 3*2=6, accum={1,4}=20, sum=26 -> M=1, N=10
        run_test(4'd4, 4'd4, 4'd8, 4'd15, OP_DOTPRODUCT, 4'd9, 4'd15);  // Moderate: 4*4=16, accum={8,15}=143, sum=159 -> M=9, N=15
        run_test(4'd15, 4'd15, 4'd15, 4'd15, OP_DOTPRODUCT, 4'd14, 4'd0); // Maximum: 15*15=225, accum={15,15}=255, sum=480 mod256=224 -> M=14, N=0
        run_test(4'd15, 4'd10, 4'd0, 4'd1, OP_DOTPRODUCT, 4'd9, 4'd7);   // High product, low accum: 15*10=150, accum={0,1}=1, sum=151 -> M=9, N=7
        run_test(4'd2, 4'd3, 4'd0, 4'd5, OP_DOTPRODUCT, 4'd0, 4'd11);    // Low product, small accum: 2*3=6, accum={0,5}=5, sum=11 -> M=0, N=11

        $display(" ");
        $display("All tests completed!");
       
        $stop;
    end

endmodule