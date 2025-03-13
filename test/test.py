# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_main(dut):
    dut._log.info("Starting simulation...")

    # Create a 10 ns period clock (100 MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initial signal values
    dut.rst_n.value = 1
    dut.ena.value   = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset sequence: wait 5 cycles, drive rst_n low for 5 cycles, then release reset.
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Wait an additional 3 cycles then enable processing.
    await ClockCycles(dut.clk, 3)
    dut.ena.value = 1

    ############################################################################
    # Define Q-mux commands (as in the Verilog testbench)
    ############################################################################
    Q_AB_LOAD = 0b0110  # Command to load A/B registers
    Q_CD_LOAD = 0b0101  # Command to load C/D registers

    ############################################################################
    # Helper function to run one test case.
    #
    # For each test, we:
    #  1. Load A and B (using Q_AB_LOAD),
    #  2. Load C and D (using Q_CD_LOAD),
    #  3. Apply an operation by driving ui_in = {Op, 4'b0000},
    #  4. Wait for processing,
    #  5. Read uo_out and compare its high nibble (M) and low nibble (N)
    ############################################################################
    async def run_test(A_val, B_val, C_val, D_val, Op_val, Expected_M, Expected_N):
        dut._log.info(f"--- Starting test: A={A_val}, B={B_val}, C={C_val}, D={D_val}, Op={Op_val:04b} ---")
        # Load A and B
        dut.ui_in.value = (0 << 4) | Q_AB_LOAD
        dut.uio_in.value = (A_val << 4) | B_val
        await ClockCycles(dut.clk, 4)  # Wait ~40 ns for propagation

        # Load C and D
        dut.ui_in.value = (0 << 4) | Q_CD_LOAD
        dut.uio_in.value = (C_val << 4) | D_val
        await ClockCycles(dut.clk, 4)  # Wait ~40 ns for propagation

        # Apply operation (Q=0 to ensure no register update)
        dut.ui_in.value = (Op_val << 4) | 0
        await ClockCycles(dut.clk, 4)  # Wait ~40 ns for processing

        # Extract outputs: uo_out[7:4]=M, uo_out[3:0]=N.
        uo_val = int(dut.uo_out.value)
        M = (uo_val >> 4) & 0xF
        N = uo_val & 0xF

        sim_time = cocotb.utils.get_sim_time("ns")
        if M == Expected_M and N == Expected_N:
            dut._log.info(f"PASS at {sim_time} ns: Op={Op_val:04b}, A={A_val}, B={B_val}, C={C_val}, D={D_val} -> M: expected {Expected_M}, got {M}; N: expected {Expected_N}, got {N}")
        else:
            dut._log.error(f"ERROR at {sim_time} ns: Op={Op_val:04b}, A={A_val}, B={B_val}, C={C_val}, D={D_val} -> M: expected {Expected_M}, got {M}; N: expected {Expected_N}, got {N}")
        dut._log.info("-" * 30)
        await ClockCycles(dut.clk, 2)  # Optional delay between tests

    ############################################################################
    # Now run a series of tests matching the Verilog testbench.
    #
    # (The opcodes below correspond to:
    #  OP_NOP           = 0b0000,
    #  OP_MINGATE       = 0b0001,
    #  OP_EQGATE        = 0b0010,
    #  OP_ZEROMN        = 0b0011,
    #  OP_DISTDIR       = 0b0100,
    #  OP_VECTORBOXAREA = 0b0101,
    #  OP_BASICBUFFER   = 0b0110,
    #  OP_ATTRRECLASS   = 0b0111,
    #  OP_FOCALMEANROW   = 0b1000,
    #  OP_FOCALSUMROW    = 0b1001,
    #  OP_FOCALMAXPOOLROW = 0b1011,
    #  OP_NORMDIFFINDEX  = 0b1100,
    #  OP_LOCALCODEOP    = 0b1101,
    #  OP_MHDIST8        = 0b1110,
    #  OP_DOTPRODUCT     = 0b1111.)
    ############################################################################

    # --- ERROR Tests (intentionally wrong expected values) ---
    dut._log.info("ERROR Test Group")
    await run_test(1, 2, 3, 4, 0b0011, 1, 0)  # Using OP_ZEROMN with incorrect expected M
    await run_test(1, 2, 3, 4, 0b0000, 0, 1)  # Using OP_NOP with incorrect expected N
    await run_test(1, 2, 3, 4, 0b0000, 1, 1)  # Using OP_NOP with both values incorrect
    await run_test(1, 2, 3, 4, 0b0010, 0, 1)  # Using OP_EQGATE with M incorrect
    await run_test(2, 2, 4, 4, 0b0100, 0, 0)  # Using OP_DISTDIR with both incorrect

    # --- NOP Tests ---
    dut._log.info("NOP Test Group")
    await run_test(1, 2, 3, 4, 0b0011, 0, 0)  # Clear M and N using OP_ZEROMN
    await run_test(1, 2, 3, 4, 0b0000, 0, 0)  # OP_NOP test
    await run_test(0, 0, 15, 15, 0b0000, 0, 0)
    await run_test(2, 6, 5, 3, 0b0100, 6, 3)  # DISTDIR: expected M=6, N=3
    await run_test(15, 15, 0, 0, 0b0000, 6, 3)
    await run_test(0, 0, 0, 0, 0b0000, 6, 3)
    await run_test(15, 15, 15, 15, 0b0000, 6, 3)

    # --- MIN GATE Tests (OP_MINGATE = 0b0001) ---
    dut._log.info("MIN GATE Test Group")
    await run_test(4, 2, 7, 5, 0b0001, 4, 2)  # When B < D: M = A, N = B
    await run_test(1, 9, 3, 4, 0b0001, 3, 4)  # When B > D: M = C, N = D
    await run_test(8, 6, 2, 6, 0b0001, 2, 6)  # When B == D: M = C, N = B
    await run_test(15, 0, 8, 15, 0b0001, 15, 0)

    # --- EQ GATE Tests (OP_EQGATE = 0b0010) ---
    dut._log.info("EQ GATE Test Group")
    await run_test(2, 5, 7, 5, 0b0010, 2, 5)  # B == D: M = A, N = D
    await run_test(1, 3, 9, 4, 0b0010, 9, 4)  # B != D: M = C, N = D
    await run_test(12, 0, 5, 0, 0b0010, 12, 0)
    await run_test(8, 15, 3, 15, 0b0010, 8, 15)

    # --- ZEROMN Tests (OP_ZEROMN = 0b0011) ---
    dut._log.info("ZEROMN Test Group")
    await run_test(1, 2, 3, 4, 0b0011, 0, 0)
    await run_test(0, 0, 15, 15, 0b0011, 0, 0)
    await run_test(15, 15, 0, 0, 0b0011, 0, 0)
    await run_test(0, 0, 0, 0, 0b0011, 0, 0)
    await run_test(15, 15, 15, 15, 0b0011, 0, 0)

    # --- DISTDIR Tests (OP_DISTDIR = 0b0100) ---
    dut._log.info("DISTDIR Test Group")
    await run_test(2, 3, 2, 3, 0b0100, 0, 0)   # Same point (no displacement)
    await run_test(2, 3, 2, 6, 0b0100, 3, 0)   # Vertical (North)
    await run_test(2, 6, 2, 3, 0b0100, 3, 4)   # Vertical (South)
    await run_test(2, 3, 5, 3, 0b0100, 3, 2)   # Horizontal (East)
    await run_test(5, 3, 2, 3, 0b0100, 3, 6)   # Horizontal (West)
    await run_test(2, 3, 5, 6, 0b0100, 6, 1)   # Diagonal NE
    await run_test(2, 6, 5, 3, 0b0100, 6, 3)   # Diagonal SE
    await run_test(5, 6, 2, 3, 0b0100, 6, 5)   # Diagonal SW
    await run_test(5, 3, 2, 6, 0b0100, 6, 7)   # Diagonal NW
    await run_test(15, 0, 0, 15, 0b0100, 14, 7)
    await run_test(0, 15, 15, 0, 0b0100, 14, 3)
    await run_test(0, 0, 15, 15, 0b0100, 14, 1)
    await run_test(1, 14, 14, 1, 0b0100, 10, 3)
    await run_test(8, 8, 9, 8, 0b0100, 1, 2)
    await run_test(8, 8, 8, 9, 0b0100, 1, 0)
    await run_test(9, 3, 6, 7, 0b0100, 7, 7)
    await run_test(3, 10, 7, 8, 0b0100, 6, 3)
    await run_test(7, 8, 3, 10, 0b0100, 6, 7)
    await run_test(0, 15, 0, 14, 0b0100, 1, 4)
    await run_test(15, 15, 15, 0, 0b0100, 15, 4)
    await run_test(15, 15, 0, 15, 0b0100, 15, 6)

    # --- VECTOR BOX AREA Tests (OP_VECTORBOXAREA = 0b0101) ---
    dut._log.info("VECTOR BOX AREA Test Group")
    await run_test(4, 4, 4, 4, 0b0101, 0, 0)   # Degenerate point
    await run_test(2, 3, 5, 3, 0b0101, 0, 6)   # Horizontal line
    await run_test(6, 2, 6, 9, 0b0101, 0, 14)  # Vertical line
    await run_test(4, 6, 1, 4, 0b0101, 6, 10)  # Standard rectangle
    await run_test(1, 4, 4, 6, 0b0101, 6, 10)  # Flipped bounding box
    await run_test(0, 0, 15, 15, 0b0101, 1, 12) # Extreme case

    # --- BASIC BUFFER Tests (OP_BASICBUFFER = 0b0110) ---
    dut._log.info("BASIC BUFFER Test Group")
    await run_test(4, 5, 7, 5, 0b0110, 2, 3)  
    await run_test(7, 5, 3, 5, 0b0110, 9, 7)
    await run_test(4, 4, 4, 7, 0b0110, 6, 2)
    await run_test(8, 7, 8, 4, 0b0110, 6, 9)
    await run_test(3, 2, 5, 6, 0b0110, 3, 2)

    # --- ATTR RECLASS Tests (OP_ATTRRECLASS = 0b0111) ---
    dut._log.info("ATTR RECLASS Test Group")
    await run_test(2, 1, 3, 2, 0b0111, 1, 0)
    await run_test(2, 1, 3, 4, 0b0111, 1, 5)
    await run_test(5, 3, 4, 2, 0b0111, 2, 0)
    await run_test(5, 3, 4, 7, 0b0111, 2, 5)
    await run_test(5, 6, 4, 2, 0b0111, 3, 0)
    await run_test(5, 6, 4, 7, 0b0111, 3, 5)

    # --- FOCAL MEAN ROW Tests (OP_FOCALMEANROW = 0b1000) ---
    dut._log.info("FOCAL MEAN ROW Test Group")
    await run_test(0, 0, 0, 0, 0b1000, 0, 0)
    await run_test(4, 5, 7, 8, 0b1000, 5, 6)
    await run_test(15, 15, 15, 15, 0b1000, 15, 15)

    # --- FOCAL SUM ROW Tests (OP_FOCALSUMROW = 0b1001) ---
    dut._log.info("FOCAL SUM ROW Test Group")
    await run_test(0, 0, 0, 0, 0b1001, 0, 0)
    await run_test(3, 4, 5, 6, 0b1001, 12, 15)
    await run_test(15, 15, 15, 15, 0b1001, 13, 13)

    # --- FOCAL MAX POOL ROW Tests (OP_FOCALMAXPOOLROW = 0b1011) ---
    dut._log.info("FOCAL MAX POOL ROW Test Group")
    await run_test(5, 5, 7, 7, 0b1011, 5, 7)
    await run_test(9, 4, 12, 3, 0b1011, 9, 12)
    await run_test(2, 8, 1, 6, 0b1011, 8, 6)
    await run_test(0, 15, 15, 0, 0b1011, 15, 15)

    # --- NORM DIFF INDEX Tests (OP_NORMDIFFINDEX = 0b1100) ---
    dut._log.info("NORM DIFF INDEX Test Group")
    await run_test(0, 0, 0, 0, 0b1100, 0, 0)
    await run_test(15, 15, 0, 0, 0b1100, 15, 15)
    await run_test(12, 10, 4, 2, 0b1100, 12, 13)
    await run_test(4, 7, 8, 9, 0b1100, 6, 7)
    await run_test(8, 0, 4, 0, 0b1100, 10, 0)

    # --- LOCAL CODE OP Tests (OP_LOCALCODEOP = 0b1101) ---
    dut._log.info("LOCAL CODE OP Test Group")
    await run_test(5, 3, 6, 0, 0b1101, 1, 0)
    await run_test(5, 3, 6, 1, 0b1101, 1, 7)
    await run_test(5, 3, 6, 2, 0b1101, 1, 7)
    await run_test(5, 3, 6, 3, 0b1101, 1, 6)
    await run_test(5, 3, 6, 4, 0b1101, 7, 6)
    await run_test(5, 3, 6, 5, 0b1101, 7, 7)
    await run_test(5, 3, 6, 6, 0b1101, 7, 13)
    await run_test(5, 3, 6, 7, 0b1101, 7, 10)
    await run_test(5, 3, 6, 8, 0b1101, 8, 0)
    await run_test(5, 3, 6, 9, 0b1101, 8, 14)
    await run_test(5, 3, 6, 10, 0b1101, 8, 14)
    await run_test(5, 3, 6, 11, 0b1101, 8, 0)
    await run_test(5, 3, 6, 12, 0b1101, 15, 6)
    await run_test(5, 3, 6, 13, 0b1101, 15, 15)
    await run_test(5, 3, 6, 14, 0b1101, 15, 5)
    await run_test(5, 3, 6, 15, 0b1101, 15, 10)
    await run_test(15, 10, 15, 10, 0b1101, 9, 8)
    await run_test(15, 15, 15, 15, 0b1101, 1, 15)

    # --- MHDist8 Tests (OP_MHDIST8 = 0b1110) ---
    dut._log.info("MHDist8 Test Group")
    await run_test(5, 5, 5, 5, 0b1110, 0, 0)
    await run_test(4, 6, 1, 3, 0b1110, 0, 6)
    await run_test(15, 0, 0, 0, 0b1110, 0, 15)
    await run_test(15, 15, 0, 0, 0b1110, 1, 14)
    await run_test(10, 12, 2, 3, 0b1110, 1, 1)

    # --- DOT PRODUCT Tests (OP_DOTPRODUCT = 0b1111) ---
    dut._log.info("DOT PRODUCT Test Group")
    await run_test(0, 0, 0, 0, 0b1111, 0, 0)
    await run_test(3, 2, 1, 4, 0b1111, 1, 10)
    await run_test(4, 4, 8, 15, 0b1111, 9, 15)
    await run_test(15, 15, 15, 15, 0b1111, 14, 0)
    await run_test(15, 10, 0, 1, 0b1111, 9, 7)
    await run_test(2, 3, 0, 5, 0b1111, 0, 11)

    dut._log.info("All tests completed!")
