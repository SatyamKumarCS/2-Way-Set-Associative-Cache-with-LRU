// ============================================================================
// File: tb/tb_lru_controller.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 3 Responsibility: Unit Testbench for LRU Replacement State
//
// Description:
//   Self-checking verification testbench for `lru_controller`.
//   - TEST 1: All four set LRU bits reset to 0 (Way 0 is the victim)
//   - TEST 2: Accessing Way 0 in Set 0 makes Way 1 the victim
//   - TEST 3: Accessing Way 1 in Set 0 makes Way 0 the victim
//   - TEST 4: Updating Set 0 leaves Sets 1, 2 and 3 unchanged
//   - EXTRA:  update_en = 0 holds state; reset clears modified state
//   Any mismatch stops the simulation with $fatal.
// ============================================================================

`timescale 1ns / 1ps

module tb_lru_controller;

    // ------------------------------------------------------------------------
    // Clock and Interface Signals
    // ------------------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic [1:0] set_index;
    logic       update_en;
    logic       accessed_way;
    logic       victim_way;

    // ------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // ------------------------------------------------------------------------
    lru_controller dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .set_index    (set_index),
        .update_en    (update_en),
        .accessed_way (accessed_way),
        .victim_way   (victim_way)
    );

    // ------------------------------------------------------------------------
    // 100 MHz Clock Generation (10 ns period)
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Helper Tasks
    // ------------------------------------------------------------------------

    // Synchronous Reset Task
    task automatic apply_reset();
        @(negedge clk);
        rst_n        = 1'b0;
        set_index    = 2'b00;
        update_en    = 1'b0;
        accessed_way = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
    endtask

    // Record one access: update_en is high for exactly one rising edge
    task automatic access_way(input logic [1:0] set_i, input logic way_i);
        @(negedge clk);
        set_index    = set_i;
        accessed_way = way_i;
        update_en    = 1'b1;
        @(negedge clk);
        update_en    = 1'b0;
    endtask

    // Combinational read of the victim for one set
    task automatic expect_victim(input logic [1:0] set_i, input logic exp_way,
                                 input string context_msg);
        set_index = set_i;
        #1;
        if (victim_way !== exp_way) begin
            $fatal(1, "[FAIL] %s: set %0d victim_way = %b, expected %b",
                   context_msg, set_i, victim_way, exp_way);
        end
    endtask

    // ------------------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        $display("==========================================================");
        $display(" tb_lru_controller: LRU replacement state unit test");
        $display("==========================================================");

        rst_n        = 1'b1;
        set_index    = 2'b00;
        update_en    = 1'b0;
        accessed_way = 1'b0;

        // --------------------------------------------------------------------
        // TEST 1: LRU Reset
        // --------------------------------------------------------------------
        apply_reset();
        @(negedge clk);
        for (int s = 0; s < 4; s++) begin
            expect_victim(s[1:0], 1'b0, "TEST 1 reset");
        end
        $display("[PASS] TEST 1: All 4 LRU bits reset to 0 (Way 0 is victim)");

        // --------------------------------------------------------------------
        // TEST 2: Access Way 0 in Set 0 -> Way 1 becomes victim
        // --------------------------------------------------------------------
        access_way(2'd0, 1'b0);
        expect_victim(2'd0, 1'b1, "TEST 2 after Way 0 access");
        // Accessing the same way again keeps the same victim
        access_way(2'd0, 1'b0);
        expect_victim(2'd0, 1'b1, "TEST 2 after repeated Way 0 access");
        $display("[PASS] TEST 2: Way 0 access in Set 0 makes Way 1 the victim");

        // --------------------------------------------------------------------
        // TEST 3: Access Way 1 in Set 0 -> Way 0 becomes victim
        // --------------------------------------------------------------------
        access_way(2'd0, 1'b1);
        expect_victim(2'd0, 1'b0, "TEST 3 after Way 1 access");
        access_way(2'd0, 1'b1);
        expect_victim(2'd0, 1'b0, "TEST 3 after repeated Way 1 access");
        $display("[PASS] TEST 3: Way 1 access in Set 0 makes Way 0 the victim");

        // --------------------------------------------------------------------
        // TEST 4: Independent Sets
        // --------------------------------------------------------------------
        // Give each other set a distinct known state:
        //   Set 1 -> victim 1, Set 2 -> victim 0 (untouched), Set 3 -> victim 1
        access_way(2'd1, 1'b0);
        access_way(2'd3, 1'b0);
        expect_victim(2'd1, 1'b1, "TEST 4 setup");
        expect_victim(2'd2, 1'b0, "TEST 4 setup");
        expect_victim(2'd3, 1'b1, "TEST 4 setup");

        // Toggle Set 0 several times; Sets 1-3 must not move
        access_way(2'd0, 1'b0);
        expect_victim(2'd0, 1'b1, "TEST 4 Set 0 toggle");
        expect_victim(2'd1, 1'b1, "TEST 4 Set 1 unchanged");
        expect_victim(2'd2, 1'b0, "TEST 4 Set 2 unchanged");
        expect_victim(2'd3, 1'b1, "TEST 4 Set 3 unchanged");

        access_way(2'd0, 1'b1);
        expect_victim(2'd0, 1'b0, "TEST 4 Set 0 toggle");
        expect_victim(2'd1, 1'b1, "TEST 4 Set 1 unchanged");
        expect_victim(2'd2, 1'b0, "TEST 4 Set 2 unchanged");
        expect_victim(2'd3, 1'b1, "TEST 4 Set 3 unchanged");

        // Changing Set 2 must not disturb Sets 0, 1 and 3 either
        access_way(2'd2, 1'b0);
        expect_victim(2'd0, 1'b0, "TEST 4 Set 0 unchanged");
        expect_victim(2'd1, 1'b1, "TEST 4 Set 1 unchanged");
        expect_victim(2'd2, 1'b1, "TEST 4 Set 2 updated");
        expect_victim(2'd3, 1'b1, "TEST 4 Set 3 unchanged");
        $display("[PASS] TEST 4: Updating one set leaves the other sets unchanged");

        // --------------------------------------------------------------------
        // EXTRA: update_en = 0 must hold state
        // --------------------------------------------------------------------
        // Current state: Set0=0, Set1=1, Set2=1, Set3=1
        for (int s = 0; s < 4; s++) begin
            @(negedge clk);
            set_index    = s[1:0];
            accessed_way = (s == 0) ? 1'b0 : 1'b1; // would flip every set
            update_en    = 1'b0;
        end
        @(negedge clk);
        expect_victim(2'd0, 1'b0, "EXTRA hold");
        expect_victim(2'd1, 1'b1, "EXTRA hold");
        expect_victim(2'd2, 1'b1, "EXTRA hold");
        expect_victim(2'd3, 1'b1, "EXTRA hold");
        $display("[PASS] EXTRA : LRU state holds while update_en = 0");

        // --------------------------------------------------------------------
        // EXTRA: Reset clears previously modified state
        // --------------------------------------------------------------------
        apply_reset();
        @(negedge clk);
        for (int s = 0; s < 4; s++) begin
            expect_victim(s[1:0], 1'b0, "EXTRA reset after updates");
        end
        $display("[PASS] EXTRA : Reset clears modified LRU state to 0");

        $display("==========================================================");
        $display(" tb_lru_controller: ALL TESTS PASSED");
        $display("==========================================================");
        $finish;
    end

    // ------------------------------------------------------------------------
    // Simulation Watchdog
    // ------------------------------------------------------------------------
    initial begin
        #100000;
        $fatal(1, "[FAIL] tb_lru_controller watchdog timeout");
    end

endmodule : tb_lru_controller
