// ============================================================================
// File: tb/tb_cache_2way_datapath.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 2 Responsibility: Unit Testbench for Two-Way Cache Datapath
//
// Description:
//   Self-checking verification testbench for `cache_2way_datapath`.
//   Instantiates the datapath with the agreed module interface and executes
//   11 comprehensive test cases covering reset, fill, lookup, dual-way
//   independence, cross-set isolation, tag mismatch, and false-hit prevention.
// ============================================================================

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module tb_cache_2way_datapath;
    import cache_pkg::*;

    // ------------------------------------------------------------------------
    // Clock and Interface Signals
    // ------------------------------------------------------------------------
    logic        clk;
    logic        rst_n;
    logic [1:0]  set_index;
    logic [25:0] request_tag;
    logic [1:0]  word_index;
    logic        hit0;
    logic        hit1;
    logic        valid0;
    logic        valid1;
    logic [31:0] selected_data;
    logic        fill_word_we;
    logic        fill_way;
    logic [1:0]  fill_word_index;
    logic [31:0] fill_word_data;
    logic        fill_meta_we;
    logic [25:0] fill_tag;

    // ------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // ------------------------------------------------------------------------
    cache_2way_datapath dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .set_index       (set_index),
        .request_tag     (request_tag),
        .word_index      (word_index),
        .hit0            (hit0),
        .hit1            (hit1),
        .valid0          (valid0),
        .valid1          (valid1),
        .selected_data   (selected_data),
        .fill_word_we    (fill_word_we),
        .fill_way        (fill_way),
        .fill_word_index (fill_word_index),
        .fill_word_data  (fill_word_data),
        .fill_meta_we    (fill_meta_we),
        .fill_tag        (fill_tag)
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
        rst_n           = 1'b0;
        set_index       = 2'b00;
        request_tag     = 26'd0;
        word_index      = 2'b00;
        fill_word_we    = 1'b0;
        fill_way        = 1'b0;
        fill_word_index = 2'b00;
        fill_word_data  = 32'd0;
        fill_meta_we    = 1'b0;
        fill_tag        = 26'd0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
    endtask

    // Line Fill Task: writes 4 words and commits metadata (tag + valid)
    // Driven cleanly at negedge clk to guarantee zero-race synchronous sampling
    task automatic fill_line(
        input logic [1:0]  set,
        input logic        way,
        input logic [25:0] tag,
        input logic [31:0] w0,
        input logic [31:0] w1,
        input logic [31:0] w2,
        input logic [31:0] w3
    );
        // Word 0
        @(negedge clk);
        set_index       = set;
        fill_way        = way;
        fill_word_we    = 1'b1;
        fill_word_index = 2'd0;
        fill_word_data  = w0;
        fill_meta_we    = 1'b0;

        // Word 1
        @(negedge clk);
        fill_word_index = 2'd1;
        fill_word_data  = w1;

        // Word 2
        @(negedge clk);
        fill_word_index = 2'd2;
        fill_word_data  = w2;

        // Word 3
        @(negedge clk);
        fill_word_index = 2'd3;
        fill_word_data  = w3;

        // Commit line metadata (tag and valid bit)
        @(negedge clk);
        fill_word_we    = 1'b0;
        fill_meta_we    = 1'b1;
        fill_tag        = tag;

        // De-assert all write enables
        @(negedge clk);
        fill_meta_we    = 1'b0;
        fill_tag        = 26'd0;
        fill_word_data  = 32'd0;
    endtask

    // Check Lookup Results Task
    task automatic check_lookup(
        input logic [1:0]  set,
        input logic [25:0] tag,
        input logic [1:0]  word,
        input logic        exp_hit0,
        input logic        exp_hit1,
        input logic        exp_valid0,
        input logic        exp_valid1,
        input logic [31:0] exp_data,
        input string       test_msg
    );
        set_index   = set;
        request_tag = tag;
        word_index  = word;
        #1; // Allow combinational evaluation

        if (hit0 !== exp_hit0 || hit1 !== exp_hit1 ||
            valid0 !== exp_valid0 || valid1 !== exp_valid1 ||
            selected_data !== exp_data) begin
            $display("[FATAL ERROR] Lookup verification failed: %s", test_msg);
            $display("  Inputs:   Set=%0d, Tag=0x%07x, Word=%0d", set, tag, word);
            $display("  Expected: hit0=%b, hit1=%b, valid0=%b, valid1=%b, data=0x%08x",
                     exp_hit0, exp_hit1, exp_valid0, exp_valid1, exp_data);
            $display("  Actual:   hit0=%b, hit1=%b, valid0=%b, valid1=%b, data=0x%08x",
                     hit0, hit1, valid0, valid1, selected_data);
            $fatal(1, "Test assertion failure.");
        end
    endtask

    // ------------------------------------------------------------------------
    // Verification Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        $display("==================================================================");
        $display("STARTING UNIT TEST: 2-Way Set-Associative Cache Datapath");
        $display("==================================================================");

        // --------------------------------------------------------------------
        // Test 1: Reset - both ways invalid in all four sets
        // --------------------------------------------------------------------
        apply_reset();
        for (int s = 0; s < 4; s = s + 1) begin
            check_lookup(s[1:0], 26'h123456, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 32'h00000000,
                         "Test 1: Check invalid status after reset");
        end
        $display("[PASS] Test 1: Reset verified - both ways invalid in all four sets.");

        // --------------------------------------------------------------------
        // Test 2: Fill a complete line into Way 0 of Set 0
        // --------------------------------------------------------------------
        fill_line(2'd0, 1'b0, 26'h00000A,
                  32'hAAAA_0000, 32'hAAAA_0001, 32'hAAAA_0002, 32'hAAAA_0003);
        $display("[PASS] Test 2: Complete line filled into Way 0 of Set 0.");

        // --------------------------------------------------------------------
        // Test 3: Confirm the tag and all four words are correctly stored
        // --------------------------------------------------------------------
        // Verify Way 0 is marked valid and Way 1 remains invalid
        set_index   = 2'd0;
        request_tag = 26'h00000A;
        word_index  = 2'd0;
        #1;
        if (valid0 !== 1'b1 || valid1 !== 1'b0) begin
            $fatal(1, "Test 3 failed: valid0 should be 1 and valid1 should be 0.");
        end
        // Check all 4 words match filled values
        check_lookup(2'd0, 26'h00000A, 2'd0, 1'b1, 1'b0, 1'b1, 1'b0, 32'hAAAA_0000, "Test 3: Word 0");
        check_lookup(2'd0, 26'h00000A, 2'd1, 1'b1, 1'b0, 1'b1, 1'b0, 32'hAAAA_0001, "Test 3: Word 1");
        check_lookup(2'd0, 26'h00000A, 2'd2, 1'b1, 1'b0, 1'b1, 1'b0, 32'hAAAA_0002, "Test 3: Word 2");
        check_lookup(2'd0, 26'h00000A, 2'd3, 1'b1, 1'b0, 1'b1, 1'b0, 32'hAAAA_0003, "Test 3: Word 3");
        $display("[PASS] Test 3: Tag (0x00000A) and all four words confirmed correctly stored.");

        // --------------------------------------------------------------------
        // Test 4: Read all four words from Way 0 and verify hit0
        // --------------------------------------------------------------------
        for (int w = 0; w < 4; w = w + 1) begin
            check_lookup(2'd0, 26'h00000A, w[1:0], 1'b1, 1'b0, 1'b1, 1'b0,
                         (32'hAAAA_0000 | w), "Test 4: Reading Way 0 words with hit0");
        end
        $display("[PASS] Test 4: Read all four words from Way 0 and verified hit0.");

        // --------------------------------------------------------------------
        // Test 5: Fill a different tag into Way 1 of the same set (Set 0)
        // --------------------------------------------------------------------
        fill_line(2'd0, 1'b1, 26'h00000B,
                  32'hBBBB_0000, 32'hBBBB_0001, 32'hBBBB_0002, 32'hBBBB_0003);
        $display("[PASS] Test 5: Complete line with different tag filled into Way 1 of Set 0.");

        // --------------------------------------------------------------------
        // Test 6: Read all four words from Way 1 and verify hit1
        // --------------------------------------------------------------------
        for (int w = 0; w < 4; w = w + 1) begin
            check_lookup(2'd0, 26'h00000B, w[1:0], 1'b0, 1'b1, 1'b1, 1'b1,
                         (32'hBBBB_0000 | w), "Test 6: Reading Way 1 words with hit1");
        end
        $display("[PASS] Test 6: Read all four words from Way 1 and verified hit1.");

        // --------------------------------------------------------------------
        // Test 7: Verify the other way is unchanged after filling one way
        // --------------------------------------------------------------------
        // Re-read Way 0 words to confirm neither tag nor data was altered by filling Way 1
        for (int w = 0; w < 4; w = w + 1) begin
            check_lookup(2'd0, 26'h00000A, w[1:0], 1'b1, 1'b0, 1'b1, 1'b1,
                         (32'hAAAA_0000 | w), "Test 7: Re-reading Way 0 after Way 1 fill");
        end
        // Re-read Way 1 words to confirm dual-way coexistence in Set 0
        for (int w = 0; w < 4; w = w + 1) begin
            check_lookup(2'd0, 26'h00000B, w[1:0], 1'b0, 1'b1, 1'b1, 1'b1,
                         (32'hBBBB_0000 | w), "Test 7: Re-reading Way 1 coexistence");
        end
        $display("[PASS] Test 7: Verified Way 0 is completely unchanged after filling Way 1.");

        // --------------------------------------------------------------------
        // Test 8: Verify different sets do not interfere with one another
        // --------------------------------------------------------------------
        // Fill Set 1
        fill_line(2'd1, 1'b0, 26'h111111,
                  32'h1100_0000, 32'h1100_0001, 32'h1100_0002, 32'h1100_0003);
        fill_line(2'd1, 1'b1, 26'h111112,
                  32'h1200_0000, 32'h1200_0001, 32'h1200_0002, 32'h1200_0003);

        // Fill Set 2
        fill_line(2'd2, 1'b0, 26'h222221,
                  32'h2100_0000, 32'h2100_0001, 32'h2100_0002, 32'h2100_0003);
        fill_line(2'd2, 1'b1, 26'h222222,
                  32'h2200_0000, 32'h2200_0001, 32'h2200_0002, 32'h2200_0003);

        // Fill Set 3
        fill_line(2'd3, 1'b0, 26'h333331,
                  32'h3100_0000, 32'h3100_0001, 32'h3100_0002, 32'h3100_0003);
        fill_line(2'd3, 1'b1, 26'h333332,
                  32'h3200_0000, 32'h3200_0001, 32'h3200_0002, 32'h3200_0003);

        // Verify Set 0 lines are untouched
        check_lookup(2'd0, 26'h00000A, 2'd0, 1'b1, 1'b0, 1'b1, 1'b1, 32'hAAAA_0000, "Set 0 Way 0 integrity");
        check_lookup(2'd0, 26'h00000B, 2'd0, 1'b0, 1'b1, 1'b1, 1'b1, 32'hBBBB_0000, "Set 0 Way 1 integrity");

        // Verify Set 1, 2, 3 contents
        check_lookup(2'd1, 26'h111111, 2'd2, 1'b1, 1'b0, 1'b1, 1'b1, 32'h1100_0002, "Set 1 Way 0");
        check_lookup(2'd1, 26'h111112, 2'd3, 1'b0, 1'b1, 1'b1, 1'b1, 32'h1200_0003, "Set 1 Way 1");
        check_lookup(2'd2, 26'h222221, 2'd1, 1'b1, 1'b0, 1'b1, 1'b1, 32'h2100_0001, "Set 2 Way 0");
        check_lookup(2'd2, 26'h222222, 2'd0, 1'b0, 1'b1, 1'b1, 1'b1, 32'h2200_0000, "Set 2 Way 1");
        check_lookup(2'd3, 26'h333331, 2'd3, 1'b1, 1'b0, 1'b1, 1'b1, 32'h3100_0003, "Set 3 Way 0");
        check_lookup(2'd3, 26'h333332, 2'd2, 1'b0, 1'b1, 1'b1, 1'b1, 32'h3200_0002, "Set 3 Way 1");
        $display("[PASS] Test 8: Verified different sets operate independently without interference.");

        // --------------------------------------------------------------------
        // Test 9: Verify a tag mismatch produces a miss
        // --------------------------------------------------------------------
        // Query Set 0 with non-existent tag 0x3FFFFFF
        check_lookup(2'd0, 26'h3FFFFFF, 2'd0, 1'b0, 1'b0, 1'b1, 1'b1, 32'h00000000,
                     "Test 9: Tag mismatch on valid set");
        $display("[PASS] Test 9: Verified tag mismatch produces a miss (hit0=0, hit1=0, data=0).");

        // --------------------------------------------------------------------
        // Test 10: Verify invalid ways never produce false hits
        // --------------------------------------------------------------------
        // Reset the cache and selectively fill only Set 1, Way 1 with tag 0x000000
        apply_reset();
        fill_line(2'd1, 1'b1, 26'd0,
                  32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF);
        // In Set 1, Way 0 tag is 0x0 (from reset), but valid bit is 0.
        // Querying tag 0x0 in Set 1 must hit Way 1, but NOT hit Way 0.
        check_lookup(2'd1, 26'd0, 2'd0, 1'b0, 1'b1, 1'b0, 1'b1, 32'hDEAD_BEEF,
                     "Test 10: Tag 0 with Way 0 invalid and Way 1 valid");
        // In Set 2, both ways have tag 0x0, but both valid bits are 0.
        check_lookup(2'd2, 26'd0, 2'd0, 1'b0, 1'b0, 1'b0, 1'b0, 32'h00000000,
                     "Test 10: Both ways invalid with matching reset tag");
        $display("[PASS] Test 10: Verified invalid ways never produce false hits.");

        // --------------------------------------------------------------------
        // Test 11: Reset and verify all valid bits clear
        // --------------------------------------------------------------------
        // First fill several lines
        fill_line(2'd0, 1'b0, 26'h111111, 32'h1, 32'h2, 32'h3, 32'h4);
        fill_line(2'd0, 1'b1, 26'h222222, 32'h5, 32'h6, 32'h7, 32'h8);
        fill_line(2'd3, 1'b0, 26'h333333, 32'h9, 32'hA, 32'hB, 32'hC);
        // Apply reset
        apply_reset();
        // Check all sets and both ways are invalid and yield misses
        for (int s = 0; s < 4; s = s + 1) begin
            check_lookup(s[1:0], 26'h111111, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 32'h00000000,
                         "Test 11: Set invalid check post-reset");
        end
        $display("[PASS] Test 11: Reset verified clearing all valid bits across all four sets.");

        // --------------------------------------------------------------------
        // All tests completed successfully
        // --------------------------------------------------------------------
        $display("==================================================================");
        $display("ALL 11 UNIT TESTS PASSED SUCCESSFULLY! (cache_2way_datapath)");
        $display("==================================================================");
        $finish;
    end

endmodule : tb_cache_2way_datapath
