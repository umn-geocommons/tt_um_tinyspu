module DemoBench;
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
    localparam [3:0] Q_NOIO    = 4'b0000;
    localparam [3:0] Q_ZERO_CD = 4'b0001;
    localparam [3:0] Q_ZERO_AB = 4'b0010;
    localparam [3:0] Q_UIO_ACBD= 4'b0100;
    localparam [3:0] Q_AB_LOAD = 4'b0110;
    localparam [3:0] Q_CD_LOAD = 4'b0101;
    localparam [3:0] Q_UIO_ABCD= 4'b0111;
    localparam [3:0] Q_MN_ACBD = 4'b1000;
    localparam [3:0] Q_MN_CD   = 4'b1001;
    localparam [3:0] Q_MN_AB   = 4'b1010;
    localparam [3:0] Q_MN_ABCD = 4'b1011;

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
    task run_direct_function;
        input [3:0] A_val, B_val, C_val, D_val, Op_val;
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

            $display("Op=%b, A=%d, B=%d, C=%d, D=%d, OUTPUT: M: %d, N: %d", Op_val, A_val, B_val, C_val, D_val, uo_out[7:4], uo_out[3:0]);

            #20; // Optional delay between tests
        end
    endtask
    
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
        $display("Starting demobench...");
        $display("For vector operations: A, B correspond to point coordinate (x1, y1); C, D correspond to point coordinate (x2, y2)");
        $display(" ");
    
        $display("DEMO: RECTANGULAR BUFFER");
        $display("Performs a sequence of SPU op calls to get coordinates of a rectangle buffered by 2 units in the X and Y directions");
        $display("Rectangle: LL (3,3), LR (6,3), UR (6,5), UL(3,5)");
        $display(" ");
        $display("Step 1: LL in A/B --> LR in C/D; produces LL_buffered in M/N");
        run_direct_function(4'd3, 4'd3, 4'd6, 4'd3, OP_BASICBUFFER);
        $display("Step 2: LR in A/B --> UR in C/D; produces LR_buffered in M/N");
        run_direct_function(4'd6, 4'd3, 4'd6, 4'd5, OP_BASICBUFFER);
        $display("Step 3: UR in A/B --> UL in C/D; produces UR_buffered in M/N");
        run_direct_function(4'd6, 4'd5, 4'd3, 4'd5, OP_BASICBUFFER);
        $display("Step 4: UL in A/B --> LL in C/D; produces UL_buffered in M/N");
        run_direct_function(4'd3, 4'd5, 4'd3, 4'd3, OP_BASICBUFFER);
        $display(" ");
        $display("Buffered Rectangle: LL (1,1), LR (8,1), UR (8,7), UL(1,7)");
        $display("Basic Buffer Complete");
    
    end
endmodule
