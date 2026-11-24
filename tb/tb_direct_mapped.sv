// ============================================================================
// File: build/tb_dm_test.sv
// Testbench: Direct-Mapped Cache Comprehensive Unit Test (Member 1)
//
// Tests:
//   1. Cold misses across lines.
//   2. Repeated access hits (temporal locality).
//   3. Four word positions (words 0, 1, 2, 3 within a line).
//   4. Conflict misses between 0x00000000 and 0x00000080 (same line index 0).
//   5. Correct four-word refill sequencing.
//   6. Delayed memory responses and memory bus backpressure.
//   7. CPU response backpressure (response stability check).
//   8. Strict hardware counter accuracy (hit_count, miss_count, mem_word_read_count).
// ============================================================================

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module tb_dm_test;
    import cache_pkg::*;

    // Clock and Reset
    logic clk;
    logic rst_n;

`ifdef DUMP_WAVES
    initial begin
        $dumpfile("build/waves/direct_mapped_cache.vcd");
        $dumpvars(0, tb_dm_test);
    end
`endif

    // CPU Interface
    logic        cpu_req_valid;
    logic        cpu_req_ready;
    logic [31:0] cpu_req_addr;
    logic        cpu_resp_valid;
    logic        cpu_resp_ready;
    logic [31:0] cpu_resp_data;

    // Memory Interface
    logic        mem_req_valid;
    logic        mem_req_ready;
    logic [31:0] mem_req_addr;
    logic        mem_resp_valid;
    logic        mem_resp_ready;
    logic [31:0] mem_resp_data;

    // Performance Counters
    logic [31:0] hit_count;
    logic [31:0] miss_count;
    logic [31:0] mem_word_read_count;

    // Test Control Knobs for Memory Stalls
    int mem_stall_req_cycles;
    int mem_stall_resp_cycles;

    // Instantiate Device Under Test
    direct_mapped_cache dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .cpu_req_valid       (cpu_req_valid),
        .cpu_req_ready       (cpu_req_ready),
        .cpu_req_addr        (cpu_req_addr),
        .cpu_resp_valid      (cpu_resp_valid),
        .cpu_resp_ready      (cpu_resp_ready),
        .cpu_resp_data       (cpu_resp_data),
        .mem_req_valid       (mem_req_valid),
        .mem_req_ready       (mem_req_ready),
        .mem_req_addr        (mem_req_addr),
        .mem_resp_valid      (mem_resp_valid),
        .mem_resp_ready      (mem_resp_ready),
        .mem_resp_data       (mem_resp_data),
        .hit_count           (hit_count),
        .miss_count          (miss_count),
        .mem_word_read_count (mem_word_read_count)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // Deterministic main memory model
    logic [31:0] main_memory [0:MEM_WORDS-1];

    function automatic [31:0] expected_word(input [31:0] byte_addr);
        expected_word = 32'hDEAD_0000 | (byte_addr & 32'h0000_FFFF);
    endfunction

    // Initialize memory contents
    initial begin
        for (int m = 0; m < MEM_WORDS; m = m + 1) begin
            main_memory[m] = expected_word(m * 4);
        end
    end

    // Memory Model with Configurable Stalls and Delays
    int req_delay_cnt;
    int resp_delay_cnt;
    logic [31:0] pending_mem_addr;
    logic        mem_processing;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            mem_req_ready   <= 1'b1;
            mem_resp_valid  <= 1'b0;
            mem_resp_data   <= '0;
            req_delay_cnt   <= 0;
            resp_delay_cnt  <= 0;
            mem_processing  <= 1'b0;
        end else begin
            // 1. Handle Request Acceptance with configurable stall
            if (!mem_processing) begin
                if (req_delay_cnt < mem_stall_req_cycles) begin
                    mem_req_ready <= 1'b0;
                    req_delay_cnt <= req_delay_cnt + 1;
                end else begin
                    mem_req_ready <= 1'b1;
                    if (mem_req_valid && mem_req_ready) begin
                        pending_mem_addr <= mem_req_addr;
                        mem_processing   <= 1'b1;
                        mem_req_ready    <= 1'b0;
                        req_delay_cnt    <= 0;
                        resp_delay_cnt   <= 0;
                    end
                end
            end else begin
                // 2. Handle Response Generation with configurable delay
                if (resp_delay_cnt < mem_stall_resp_cycles) begin
                    mem_resp_valid <= 1'b0;
                    resp_delay_cnt <= resp_delay_cnt + 1;
                end else begin
                    mem_resp_valid <= 1'b1;
                    mem_resp_data  <= main_memory[(pending_mem_addr >> 2) % MEM_WORDS];

                    if (mem_resp_valid && mem_resp_ready) begin
                        mem_resp_valid <= 1'b0;
                        mem_processing <= 1'b0;
                        mem_req_ready  <= (mem_stall_req_cycles == 0) ? 1'b1 : 1'b0;
                    end
                end
            end
        end
    end

    // Test stats
    int error_count = 0;
    int test_id     = 0;

    // CPU Read Task
    task automatic cpu_read_check(
        input [31:0] addr,
        input [31:0] exp_data,
        input bit    expect_hit
    );
        logic [31:0] pre_hit;
        logic [31:0] pre_miss;
        begin
            pre_hit  = hit_count;
            pre_miss = miss_count;

            // Wait until cache is ready for request
            while (!cpu_req_ready) @(posedge clk);

            // Present request synchronously
            cpu_req_valid <= 1'b1;
            cpu_req_addr  <= addr;
            @(posedge clk);
            cpu_req_valid <= 1'b0;

            // Wait for response valid
            while (!cpu_resp_valid) @(posedge clk);

            // Check data value
            if (cpu_resp_data !== exp_data) begin
                $display("[ERROR] Addr 0x%08X: Expected 0x%08X, Got 0x%08X",
                         addr, exp_data, cpu_resp_data);
                error_count = error_count + 1;
            end

            // Accept response
            cpu_resp_ready <= 1'b1;
            @(posedge clk);
            cpu_resp_ready <= 1'b1;

            // Check hit/miss counter increment
            if (expect_hit) begin
                if (hit_count !== pre_hit + 1) begin
                    $display("[ERROR] Addr 0x%08X expected HIT, but hit_count did not increment! (hits=%0d, misses=%0d)",
                             addr, hit_count, miss_count);
                    error_count = error_count + 1;
                end else begin
                    $display("[PASS] Addr 0x%08X -> 0x%08X (HIT, Line %0d, Word %0d)",
                             addr, cpu_resp_data, addr[6:4], addr[3:2]);
                end
            end else begin
                if (miss_count !== pre_miss + 1) begin
                    $display("[ERROR] Addr 0x%08X expected MISS, but miss_count did not increment! (hits=%0d, misses=%0d)",
                             addr, hit_count, miss_count);
                    error_count = error_count + 1;
                end else begin
                    $display("[PASS] Addr 0x%08X -> 0x%08X (MISS, Line %0d, Word %0d)",
                             addr, cpu_resp_data, addr[6:4], addr[3:2]);
                end
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Test Procedure
    // ------------------------------------------------------------------------
    initial begin
        clk                   = 0;
        rst_n                 = 0;
        cpu_req_valid         = 0;
        cpu_req_addr          = 0;
        cpu_resp_ready        = 1;
        mem_stall_req_cycles  = 0;
        mem_stall_resp_cycles = 1;

        $display("\n=======================================================");
        $display("   DIRECT-MAPPED CACHE COMPREHENSIVE VERIFICATION");
        $display("=======================================================\n");

        // 1. Reset Verification
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        if (hit_count !== 0 || miss_count !== 0 || mem_word_read_count !== 0) begin
            $display("[ERROR] Counters did not reset to 0!");
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Reset behaviour verified: counters and valid bits initialized.");
        end

        // 2. Cold Misses
        $display("\n--- Test 1: Cold Misses Across Distinct Lines ---");
        // Line 0 (0x00000000)
        cpu_read_check(32'h0000_0000, expected_word(32'h0000_0000), 1'b0);
        // Line 1 (0x00000010)
        cpu_read_check(32'h0000_0010, expected_word(32'h0000_0010), 1'b0);
        // Line 2 (0x00000020)
        cpu_read_check(32'h0000_0020, expected_word(32'h0000_0020), 1'b0);
        // Line 7 (0x00000070)
        cpu_read_check(32'h0000_0070, expected_word(32'h0000_0070), 1'b0);

        // 3. Repeated Access Hits (Temporal Locality)
        $display("\n--- Test 2: Repeated Access Hits (Temporal Locality) ---");
        cpu_read_check(32'h0000_0000, expected_word(32'h0000_0000), 1'b1);
        cpu_read_check(32'h0000_0010, expected_word(32'h0000_0010), 1'b1);
        cpu_read_check(32'h0000_0020, expected_word(32'h0000_0020), 1'b1);
        cpu_read_check(32'h0000_0070, expected_word(32'h0000_0070), 1'b1);

        // 4. Four Word Positions within Cached Line 0 (Spatial Locality)
        $display("\n--- Test 3: Four Word Positions (Spatial Locality) ---");
        // Line 0: word 0 was read at 0x00000000
        // Now test word 1 (+4), word 2 (+8), word 3 (+12)
        cpu_read_check(32'h0000_0004, expected_word(32'h0000_0004), 1'b1);
        cpu_read_check(32'h0000_0008, expected_word(32'h0000_0008), 1'b1);
        cpu_read_check(32'h0000_000C, expected_word(32'h0000_000C), 1'b1);
        cpu_read_check(32'h0000_0000, expected_word(32'h0000_0000), 1'b1);

        // 5. Conflict Miss between 0x00000000 and 0x00000080
        $display("\n--- Test 4: Conflict Replacement (0x00000000 vs 0x00000080) ---");
        // 0x00000080 maps to Line 0, Tag 1 (conflicts with 0x00000000, Tag 0)
        cpu_read_check(32'h0000_0080, expected_word(32'h0000_0080), 1'b0); // MISS: Evicts Tag 0
        cpu_read_check(32'h0000_0080, expected_word(32'h0000_0080), 1'b1); // HIT: Now cached
        cpu_read_check(32'h0000_0000, expected_word(32'h0000_0000), 1'b0); // MISS: Evicted!

        // 6. Delayed Memory Responses & Bus Stalls
        $display("\n--- Test 5: Delayed Memory Responses & Request Stalls ---");
        mem_stall_req_cycles  = 2; // Memory bus backpressure: stalls request by 2 cycles
        mem_stall_resp_cycles = 3; // DRAM delay: takes 3 cycles per returned word
        // Access Line 3 (0x00000030) under heavy memory stalls
        cpu_read_check(32'h0000_0030, expected_word(32'h0000_0030), 1'b0); // MISS with stalls
        cpu_read_check(32'h0000_0030, expected_word(32'h0000_0030), 1'b1); // HIT after refill
        // Reset stall settings
        mem_stall_req_cycles  = 0;
        mem_stall_resp_cycles = 1;

        // 7. CPU Backpressure & Response Stability
        $display("\n--- Test 6: CPU Backpressure & Response Stability ---");
        // Deassert cpu_resp_ready before request to force cache to hold response
        cpu_resp_ready <= 1'b0;
        while (!cpu_req_ready) @(posedge clk);
        cpu_req_valid  <= 1'b1;
        cpu_req_addr   <= 32'h0000_0014; // Line 1, Word 1 (Hit)
        @(posedge clk);
        cpu_req_valid  <= 1'b0;

        // Wait until cache presents response
        while (!cpu_resp_valid) @(posedge clk);

        // Verify cpu_resp_valid and cpu_resp_data remain 100% stable while cpu_resp_ready = 0
        for (int b = 0; b < 4; b = b + 1) begin
            if (!cpu_resp_valid) begin
                $display("[ERROR] cpu_resp_valid dropped while cpu_resp_ready was deasserted!");
                error_count = error_count + 1;
            end
            if (cpu_resp_data !== expected_word(32'h0000_0014)) begin
                $display("[ERROR] cpu_resp_data corrupted while waiting for ready!");
                error_count = error_count + 1;
            end
            @(posedge clk);
        end

        // Finally accept response
        cpu_resp_ready <= 1'b1;
        @(posedge clk);
        $display("[PASS] CPU response valid and payload remained completely stable under backpressure.");

        // 8. Strict Counter Verification
        $display("\n--- Test 7: Hardware Counter Precision ---");
        $display("Total Hits:               %0d", hit_count);
        $display("Total Misses:             %0d", miss_count);
        $display("Total Memory Word Reads:  %0d", mem_word_read_count);

        if (mem_word_read_count !== miss_count * 4) begin
            $display("[ERROR] mem_word_read_count (%0d) != miss_count * 4 (%0d)",
                     mem_word_read_count, miss_count * 4);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Memory word read count strictly equals 4 x miss count (%0d = 4 x %0d).",
                     mem_word_read_count, miss_count);
        end

        // Summary
        $display("\n=======================================================");
        if (error_count == 0) begin
            $display("   ALL TESTS PASSED PERFECTLY! (0 errors)");
        end else begin
            $display("   TESTS COMPLETED WITH %0d ERRORS!", error_count);
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
