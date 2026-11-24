// ============================================================================
// File: tb/tb_cache_comparison.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 4 Responsibility: Cache Comparison Testbench & Performance Metrics
//
// Description:
//   Comprehensive, self-checking SystemVerilog testbench comparing the
//   Direct-Mapped Cache (`direct_mapped_cache`) against the Two-Way
//   Set-Associative Cache (`cache_2way_top`) with LRU replacement.
//
// Fairness Architecture:
//   - Identical reference memory instances initialized with:
//       memory[i] = 32'hA5000000 ^ i;
//   - Identical ordered CPU address traces driven to both caches.
//   - Concurrent, independent CPU drivers for each cache so differing
//     response latencies never alter or misalign the address stream.
//   - Request transitions driven on negedge clk; handshakes sampled on
//     posedge clk to eliminate race conditions.
//   - Synchronous reset clears both caches and memories between scenarios.
//
// Evaluation Scenarios:
//   1. Sequential Locality: 4 sequential word accesses in line 0.
//   2. Conflict-Heavy Trace: Alternating accesses to 0x00000000 and 0x00000080.
//   3. Explicit LRU Verification: A -> B -> A -> C -> A -> B pattern.
//   4. Deterministic Mixed Trace: Multi-set, spatial, and conflict mix.
//
// Deliverables:
//   - Live testbench pass/fail validation using $fatal on error.
//   - Real simulation results exported to `results/results.csv`.
// ============================================================================

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module tb_cache_comparison;

    import cache_pkg::*;

    // ------------------------------------------------------------------------
    // Clock and Global Synchronous Reset
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

`ifdef DUMP_WAVES
    initial begin
        $dumpfile("build/waves/two_way_lru_cache.vcd");
        $dumpvars(0, tb_cache_comparison);
    end
`endif

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Free-running simulation clock cycle counter
    longint unsigned cycle_count;
    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 64'd0;
        end else begin
            cycle_count <= cycle_count + 1'b1;
        end
    end

    // ------------------------------------------------------------------------
    // Direct-Mapped Cache DUT Signals
    // ------------------------------------------------------------------------
    logic        dm_cpu_req_valid;
    logic        dm_cpu_req_ready;
    logic [31:0] dm_cpu_req_addr;
    logic        dm_cpu_resp_valid;
    logic        dm_cpu_resp_ready;
    logic [31:0] dm_cpu_resp_data;

    logic        dm_mem_req_valid;
    logic        dm_mem_req_ready;
    logic [31:0] dm_mem_req_addr;
    logic        dm_mem_resp_valid;
    logic        dm_mem_resp_ready;
    logic [31:0] dm_mem_resp_data;

    logic [31:0] dm_hit_count;
    logic [31:0] dm_miss_count;
    logic [31:0] dm_mem_word_read_count;

    // ------------------------------------------------------------------------
    // Two-Way Set-Associative Cache DUT Signals
    // ------------------------------------------------------------------------
    logic        sa_cpu_req_valid;
    logic        sa_cpu_req_ready;
    logic [31:0] sa_cpu_req_addr;
    logic        sa_cpu_resp_valid;
    logic        sa_cpu_resp_ready;
    logic [31:0] sa_cpu_resp_data;

    logic        sa_mem_req_valid;
    logic        sa_mem_req_ready;
    logic [31:0] sa_mem_req_addr;
    logic        sa_mem_resp_valid;
    logic        sa_mem_resp_ready;
    logic [31:0] sa_mem_resp_data;

    logic [31:0] sa_hit_count;
    logic [31:0] sa_miss_count;
    logic [31:0] sa_mem_word_read_count;

    // ------------------------------------------------------------------------
    // DUT 1: Direct-Mapped Cache
    // ------------------------------------------------------------------------
    direct_mapped_cache u_dm_cache (
        .clk                 (clk),
        .rst_n               (rst_n),
        .cpu_req_valid       (dm_cpu_req_valid),
        .cpu_req_ready       (dm_cpu_req_ready),
        .cpu_req_addr        (dm_cpu_req_addr),
        .cpu_resp_valid      (dm_cpu_resp_valid),
        .cpu_resp_ready      (dm_cpu_resp_ready),
        .cpu_resp_data       (dm_cpu_resp_data),
        .mem_req_valid       (dm_mem_req_valid),
        .mem_req_ready       (dm_mem_req_ready),
        .mem_req_addr        (dm_mem_req_addr),
        .mem_resp_valid      (dm_mem_resp_valid),
        .mem_resp_ready      (dm_mem_resp_ready),
        .mem_resp_data       (dm_mem_resp_data),
        .hit_count           (dm_hit_count),
        .miss_count          (dm_miss_count),
        .mem_word_read_count (dm_mem_word_read_count)
    );

    // Dedicated Main Memory for Direct-Mapped Cache
    simple_main_memory #(
        .LATENCY_CYCLES     (2),
        .REQUEST_GAP_CYCLES (1)
    ) u_dm_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_req_valid  (dm_mem_req_valid),
        .mem_req_ready  (dm_mem_req_ready),
        .mem_req_addr   (dm_mem_req_addr),
        .mem_resp_valid (dm_mem_resp_valid),
        .mem_resp_ready (dm_mem_resp_ready),
        .mem_resp_data  (dm_mem_resp_data)
    );

    // ------------------------------------------------------------------------
    // DUT 2: Two-Way Set-Associative Cache
    // ------------------------------------------------------------------------
    cache_2way_top u_sa_cache (
        .clk                 (clk),
        .rst_n               (rst_n),
        .cpu_req_valid       (sa_cpu_req_valid),
        .cpu_req_ready       (sa_cpu_req_ready),
        .cpu_req_addr        (sa_cpu_req_addr),
        .cpu_resp_valid      (sa_cpu_resp_valid),
        .cpu_resp_ready      (sa_cpu_resp_ready),
        .cpu_resp_data       (sa_cpu_resp_data),
        .mem_req_valid       (sa_mem_req_valid),
        .mem_req_ready       (sa_mem_req_ready),
        .mem_req_addr        (sa_mem_req_addr),
        .mem_resp_valid      (sa_mem_resp_valid),
        .mem_resp_ready      (sa_mem_resp_ready),
        .mem_resp_data       (sa_mem_resp_data),
        .hit_count           (sa_hit_count),
        .miss_count          (sa_miss_count),
        .mem_word_read_count (sa_mem_word_read_count)
    );

    // Dedicated Main Memory for Two-Way Cache
    simple_main_memory #(
        .LATENCY_CYCLES     (2),
        .REQUEST_GAP_CYCLES (1)
    ) u_sa_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_req_valid  (sa_mem_req_valid),
        .mem_req_ready  (sa_mem_req_ready),
        .mem_req_addr   (sa_mem_req_addr),
        .mem_resp_valid (sa_mem_resp_valid),
        .mem_resp_ready (sa_mem_resp_ready),
        .mem_resp_data  (sa_mem_resp_data)
    );

    // ------------------------------------------------------------------------
    // Testbench Storage, Latency Tracking, and Synchronous Cycle Monitors
    // ------------------------------------------------------------------------
    localparam int MAX_TRACE_SIZE = 64;
    logic [31:0] trace_buffer [0:MAX_TRACE_SIZE-1];

    longint unsigned dm_start_cycle;
    longint unsigned dm_total_cycles;
    int              dm_completed_accesses;

    longint unsigned sa_start_cycle;
    longint unsigned sa_total_cycles;
    int              sa_completed_accesses;

    // Track per-access hits and misses in Scenario 3
    bit sa_access_was_hit [0:MAX_TRACE_SIZE-1];

    // Synchronous Cycle and Handshake Performance Monitor
    always @(posedge clk) begin
        if (!rst_n) begin
            dm_start_cycle        <= 64'd0;
            dm_total_cycles       <= 64'd0;
            dm_completed_accesses <= 0;

            sa_start_cycle        <= 64'd0;
            sa_total_cycles       <= 64'd0;
            sa_completed_accesses <= 0;
        end else begin
            // Direct-Mapped Request Handshake
            if (dm_cpu_req_valid && dm_cpu_req_ready) begin
                dm_start_cycle <= cycle_count;
            end

            // Direct-Mapped Response Handshake
            if (dm_cpu_resp_valid && dm_cpu_resp_ready) begin
                dm_total_cycles <= dm_total_cycles + (cycle_count - dm_start_cycle);
                dm_completed_accesses <= dm_completed_accesses + 1;
            end

            // Two-Way Request Handshake
            if (sa_cpu_req_valid && sa_cpu_req_ready) begin
                sa_start_cycle <= cycle_count;
            end

            // Two-Way Response Handshake
            if (sa_cpu_resp_valid && sa_cpu_resp_ready) begin
                sa_total_cycles <= sa_total_cycles + (cycle_count - sa_start_cycle);
                sa_completed_accesses <= sa_completed_accesses + 1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Reference Data Calculation
    // ------------------------------------------------------------------------
    function automatic [31:0] expected_word(input [31:0] byte_addr);
        expected_word = 32'hA5000000 ^ (byte_addr >> 2);
    endfunction

    // ------------------------------------------------------------------------
    // Reset Sequence Task
    // ------------------------------------------------------------------------
    task automatic apply_reset();
        @(negedge clk);
        rst_n             = 1'b0;
        dm_cpu_req_valid  = 1'b0;
        dm_cpu_req_addr   = 32'h0;
        dm_cpu_resp_ready = 1'b0;
        sa_cpu_req_valid  = 1'b0;
        sa_cpu_req_addr   = 32'h0;
        sa_cpu_resp_ready = 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Verify clean reset state
        if (dm_hit_count !== 0 || dm_miss_count !== 0 || dm_mem_word_read_count !== 0 ||
            sa_hit_count !== 0 || sa_miss_count !== 0 || sa_mem_word_read_count !== 0) begin
            $fatal(1, "[tb_cache_comparison] ERROR: Reset failed to clear performance counters!");
        end
    endtask

    // ------------------------------------------------------------------------
    // Independent CPU Driver for Direct-Mapped Cache
    // ------------------------------------------------------------------------
    task automatic drive_dm_access(
        input [31:0] addr,
        input int    resp_backpressure_cycles
    );
        logic [31:0] exp_data;
        int          timeout_cnt;

        exp_data = expected_word(addr);

        // Drive CPU request on negedge clk
        @(negedge clk);
        dm_cpu_req_valid = 1'b1;
        dm_cpu_req_addr  = addr;

        // Wait for request acceptance
        timeout_cnt = 0;
        while (!dm_cpu_req_ready) begin
            @(negedge clk);
            timeout_cnt = timeout_cnt + 1;
            if (timeout_cnt > 2000) begin
                $fatal(1, "[Direct-Mapped] TIMEOUT waiting for cpu_req_ready on addr 0x%08h", addr);
            end
        end

        // Deassert request on the negedge after acceptance
        @(negedge clk);
        dm_cpu_req_valid = 1'b0;
        dm_cpu_req_addr  = 32'hFFFF_FFFF; // Poison bus to catch stale latch bugs

        // Wait for CPU response valid
        timeout_cnt = 0;
        while (!dm_cpu_resp_valid) begin
            @(negedge clk);
            timeout_cnt = timeout_cnt + 1;
            if (timeout_cnt > 2000) begin
                $fatal(1, "[Direct-Mapped] TIMEOUT waiting for cpu_resp_valid on addr 0x%08h", addr);
            end
        end

        // Verify response stability under backpressure if requested
        repeat (resp_backpressure_cycles) begin
            @(negedge clk);
            if (!dm_cpu_resp_valid || dm_cpu_resp_data !== exp_data) begin
                $fatal(1, "[Direct-Mapped] Backpressure stability violated! valid=%0b data=0x%08h exp=0x%08h",
                       dm_cpu_resp_valid, dm_cpu_resp_data, exp_data);
            end
        end

        // Accept response
        dm_cpu_resp_ready = 1'b1;
        @(negedge clk);
        dm_cpu_resp_ready = 1'b0;

        // Data correctness verification
        if (dm_cpu_resp_data !== exp_data) begin
            $fatal(1, "[Direct-Mapped] DATA MISMATCH: Addr=0x%08h Got=0x%08h Expected=0x%08h",
                   addr, dm_cpu_resp_data, exp_data);
        end
    endtask

    // ------------------------------------------------------------------------
    // Independent CPU Driver for Two-Way Set-Associative Cache
    // ------------------------------------------------------------------------
    task automatic drive_sa_access(
        input [31:0] addr,
        input int    access_idx,
        input int    resp_backpressure_cycles
    );
        logic [31:0] exp_data;
        logic [31:0] pre_hit_cnt;
        int          timeout_cnt;

        exp_data    = expected_word(addr);
        pre_hit_cnt = sa_hit_count;

        // Drive CPU request on negedge clk
        @(negedge clk);
        sa_cpu_req_valid = 1'b1;
        sa_cpu_req_addr  = addr;

        // Wait for request acceptance
        timeout_cnt = 0;
        while (!sa_cpu_req_ready) begin
            @(negedge clk);
            timeout_cnt = timeout_cnt + 1;
            if (timeout_cnt > 2000) begin
                $fatal(1, "[Two-Way] TIMEOUT waiting for cpu_req_ready on addr 0x%08h", addr);
            end
        end

        // Deassert request on the negedge after acceptance
        @(negedge clk);
        sa_cpu_req_valid = 1'b0;
        sa_cpu_req_addr  = 32'hFFFF_FFFF; // Poison bus to catch stale latch bugs

        // Wait for CPU response valid
        timeout_cnt = 0;
        while (!sa_cpu_resp_valid) begin
            @(negedge clk);
            timeout_cnt = timeout_cnt + 1;
            if (timeout_cnt > 2000) begin
                $fatal(1, "[Two-Way] TIMEOUT waiting for cpu_resp_valid on addr 0x%08h", addr);
            end
        end

        // Record whether this access was a hit
        sa_access_was_hit[access_idx] = (sa_hit_count > pre_hit_cnt);

        // Verify response stability under backpressure if requested
        repeat (resp_backpressure_cycles) begin
            @(negedge clk);
            if (!sa_cpu_resp_valid || sa_cpu_resp_data !== exp_data) begin
                $fatal(1, "[Two-Way] Backpressure stability violated! valid=%0b data=0x%08h exp=0x%08h",
                       sa_cpu_resp_valid, sa_cpu_resp_data, exp_data);
            end
        end

        // Accept response
        sa_cpu_resp_ready = 1'b1;
        @(negedge clk);
        sa_cpu_resp_ready = 1'b0;

        // Data correctness verification
        if (sa_cpu_resp_data !== exp_data) begin
            $fatal(1, "[Two-Way] DATA MISMATCH: Addr=0x%08h Got=0x%08h Expected=0x%08h",
                   addr, sa_cpu_resp_data, exp_data);
        end
    endtask

    // ------------------------------------------------------------------------
    // Concurrent Scenario Execution Engine
    // ------------------------------------------------------------------------
    task automatic run_scenario(
        input string scenario_name,
        input int    num_accesses,
        input int    test_backpressure
    );
        int bp_dm;
        int bp_sa;

        $display("----------------------------------------------------------------------");
        $display("Starting %s (%0d accesses)", scenario_name, num_accesses);
        $display("----------------------------------------------------------------------");

        apply_reset();

        // Fork independent CPU drivers concurrently for fairness
        fork
            begin : dm_driver_thread
                for (int i = 0; i < num_accesses; i = i + 1) begin
                    bp_dm = (test_backpressure && (i == 1 || i == 3)) ? 2 : 0;
                    drive_dm_access(trace_buffer[i], bp_dm);
                end
            end
            begin : sa_driver_thread
                for (int j = 0; j < num_accesses; j = j + 1) begin
                    bp_sa = (test_backpressure && (j == 1 || j == 3)) ? 2 : 0;
                    drive_sa_access(trace_buffer[j], j, bp_sa);
                end
            end
        join

        // Allow pipeline and counters to settle
        repeat (4) @(posedge clk);

        // Verify fundamental invariants for both caches
        // 1. hit_count + miss_count == number_of_completed_CPU_accesses
        // 2. mem_word_read_count == 4 * miss_count
        if (dm_hit_count + dm_miss_count !== num_accesses) begin
            $fatal(1, "[Direct-Mapped] Invariant violated: hits(%0d) + misses(%0d) != accesses(%0d)",
                   dm_hit_count, dm_miss_count, num_accesses);
        end
        if (dm_mem_word_read_count !== (4 * dm_miss_count)) begin
            $fatal(1, "[Direct-Mapped] Invariant violated: mem_reads(%0d) != 4 * misses(%0d)",
                   dm_mem_word_read_count, dm_miss_count);
        end

        if (sa_hit_count + sa_miss_count !== num_accesses) begin
            $fatal(1, "[Two-Way] Invariant violated: hits(%0d) + misses(%0d) != accesses(%0d)",
                   sa_hit_count, sa_miss_count, num_accesses);
        end
        if (sa_mem_word_read_count !== (4 * sa_miss_count)) begin
            $fatal(1, "[Two-Way] Invariant violated: mem_reads(%0d) != 4 * misses(%0d)",
                   sa_mem_word_read_count, sa_miss_count);
        end

        $display("  Direct-Mapped: Hits=%0d, Misses=%0d, MemReads=%0d, Cycles=%0d (Avg: %0.2f)",
                 dm_hit_count, dm_miss_count, dm_mem_word_read_count, dm_total_cycles,
                 real'(dm_total_cycles) / real'(num_accesses));
        $display("  Two-Way LRU:   Hits=%0d, Misses=%0d, MemReads=%0d, Cycles=%0d (Avg: %0.2f)",
                 sa_hit_count, sa_miss_count, sa_mem_word_read_count, sa_total_cycles,
                 real'(sa_total_cycles) / real'(num_accesses));
    endtask

    // ------------------------------------------------------------------------
    // CSV Export Routine
    // ------------------------------------------------------------------------
    task automatic export_scenario_csv(
        input int    fd,
        input string scenario_name,
        input int    num_accesses
    );
        real dm_hr, dm_mr, dm_avg_cyc;
        real sa_hr, sa_mr, sa_avg_cyc;

        dm_hr      = (real'(dm_hit_count)  / real'(num_accesses)) * 100.0;
        dm_mr      = (real'(dm_miss_count) / real'(num_accesses)) * 100.0;
        dm_avg_cyc = real'(dm_total_cycles) / real'(num_accesses);

        sa_hr      = (real'(sa_hit_count)  / real'(num_accesses)) * 100.0;
        sa_mr      = (real'(sa_miss_count) / real'(num_accesses)) * 100.0;
        sa_avg_cyc = real'(sa_total_cycles) / real'(num_accesses);

        // CSV Header format:
        // scenario,cache,accesses,hits,misses,hit_rate,miss_rate,mem_word_reads,total_cycles,average_cycles
        $fwrite(fd, "%s,direct_mapped,%0d,%0d,%0d,%.2f,%.2f,%0d,%0d,%.2f\n",
                scenario_name, num_accesses, dm_hit_count, dm_miss_count,
                dm_hr, dm_mr, dm_mem_word_read_count, dm_total_cycles, dm_avg_cyc);

        $fwrite(fd, "%s,two_way,%0d,%0d,%0d,%.2f,%.2f,%0d,%0d,%.2f\n",
                scenario_name, num_accesses, sa_hit_count, sa_miss_count,
                sa_hr, sa_mr, sa_mem_word_read_count, sa_total_cycles, sa_avg_cyc);
    endtask

    // ------------------------------------------------------------------------
    // Main Test Execution Flow
    // ------------------------------------------------------------------------
    int csv_fd;

    initial begin
        $display("======================================================================");
        $display("   COMPREHENSIVE CACHE COMPARISON TESTBENCH (MEMBER 4)");
        $display("   Direct-Mapped vs 2-Way Set-Associative with LRU");
        $display("======================================================================");

        // Open results CSV file
        csv_fd = $fopen("results/results.csv", "w");
        if (csv_fd == 0) begin
            $fatal(1, "[tb_cache_comparison] FATAL: Could not open results/results.csv for writing!");
        end
        $fwrite(csv_fd, "scenario,cache,accesses,hits,misses,hit_rate,miss_rate,mem_word_reads,total_cycles,average_cycles\n");

        // ====================================================================
        // SCENARIO 1: SEQUENTIAL LOCALITY
        // ====================================================================
        trace_buffer[0] = 32'h0000_0000;
        trace_buffer[1] = 32'h0000_0004;
        trace_buffer[2] = 32'h0000_0008;
        trace_buffer[3] = 32'h0000_000C;

        run_scenario("scenario_1_sequential_locality", 4, 1);

        // Verify exact expected results: 1 miss, 3 hits for both caches
        if (dm_hit_count !== 3 || dm_miss_count !== 1) begin
            $fatal(1, "[FAIL] Scenario 1 DM expected 3 hits, 1 miss. Got %0d hits, %0d misses",
                   dm_hit_count, dm_miss_count);
        end
        if (sa_hit_count !== 3 || sa_miss_count !== 1) begin
            $fatal(1, "[FAIL] Scenario 1 2-Way expected 3 hits, 1 miss. Got %0d hits, %0d misses",
                   sa_hit_count, sa_miss_count);
        end
        $display("[PASS] Scenario 1: Sequential Locality verified (1 miss, 3 hits for both).");
        export_scenario_csv(csv_fd, "scenario_1_sequential_locality", 4);

        // ====================================================================
        // SCENARIO 2: CONFLICT-HEAVY TRACE
        // Repeat 0x00000000 and 0x00000080 four times (8 accesses total)
        // ====================================================================
        for (int k = 0; k < 4; k = k + 1) begin
            trace_buffer[2*k]     = 32'h0000_0000;
            trace_buffer[2*k + 1] = 32'h0000_0080;
        end

        run_scenario("scenario_2_conflict_heavy", 8, 1);

        // Expected Direct-Mapped: 8 misses, 0 hits (thrashing on line 0)
        // Expected Two-Way: 2 misses (filling Way 0 & Way 1), 6 hits (coexisting in Set 0)
        if (dm_hit_count !== 0 || dm_miss_count !== 8) begin
            $fatal(1, "[FAIL] Scenario 2 DM expected 0 hits, 8 misses. Got %0d hits, %0d misses",
                   dm_hit_count, dm_miss_count);
        end
        if (sa_hit_count !== 6 || sa_miss_count !== 2) begin
            $fatal(1, "[FAIL] Scenario 2 2-Way expected 6 hits, 2 misses. Got %0d hits, %0d misses",
                   sa_hit_count, sa_miss_count);
        end
        $display("[PASS] Scenario 2: Conflict-Heavy Trace verified (DM: 8 misses, 2-Way: 2 misses, 6 hits).");
        export_scenario_csv(csv_fd, "scenario_2_conflict_heavy", 8);

        // ====================================================================
        // SCENARIO 3: EXPLICIT LRU VERIFICATION
        // A -> B -> A -> C -> A -> B (6 accesses total)
        // A = 0x00000000, B = 0x00000080, C = 0x00000100
        // ====================================================================
        trace_buffer[0] = 32'h0000_0000; // A
        trace_buffer[1] = 32'h0000_0080; // B
        trace_buffer[2] = 32'h0000_0000; // A
        trace_buffer[3] = 32'h0000_0100; // C
        trace_buffer[4] = 32'h0000_0000; // A
        trace_buffer[5] = 32'h0000_0080; // B

        run_scenario("scenario_3_explicit_lru", 6, 0);

        // Expected Direct-Mapped: 0 hits, 6 misses (all map to line 0)
        // Expected Two-Way: 2 hits, 4 misses
        if (dm_hit_count !== 0 || dm_miss_count !== 6) begin
            $fatal(1, "[FAIL] Scenario 3 DM expected 0 hits, 6 misses. Got %0d hits, %0d misses",
                   dm_hit_count, dm_miss_count);
        end
        if (sa_hit_count !== 2 || sa_miss_count !== 4) begin
            $fatal(1, "[FAIL] Scenario 3 2-Way expected 2 hits, 4 misses. Got %0d hits, %0d misses",
                   sa_hit_count, sa_miss_count);
        end

        // Explicit LRU behavior assertions:
        // 1. Access 2 (A) was a hit
        if (!sa_access_was_hit[2]) begin
            $fatal(1, "[FAIL] Scenario 3: Access 2 (A) was expected to HIT");
        end
        // 2. Access 3 (C) was a miss (replaces B, not A)
        if (sa_access_was_hit[3]) begin
            $fatal(1, "[FAIL] Scenario 3: Access 3 (C) was expected to MISS");
        end
        // 3. Access 4 (A) remains a hit after C is loaded
        if (!sa_access_was_hit[4]) begin
            $fatal(1, "[FAIL] Scenario 3: Access 4 (A) was expected to remain a HIT after C is loaded");
        end
        // 4. Access 5 (B) causes a miss because B was evicted by C
        if (sa_access_was_hit[5]) begin
            $fatal(1, "[FAIL] Scenario 3: Access 5 (B) was expected to MISS because B was evicted by C");
        end

        $display("[PASS] Scenario 3: Explicit LRU verified (A stayed hit, C evicted B, final B missed).");
        export_scenario_csv(csv_fd, "scenario_3_explicit_lru", 6);

        // ====================================================================
        // SCENARIO 4: DETERMINISTIC MIXED TRACE (16 accesses)
        // Exercises spatial locality, multiple sets, and conflict dynamics
        // ====================================================================
        trace_buffer[0]  = 32'h0000_0200;
        trace_buffer[1]  = 32'h0000_0204;
        trace_buffer[2]  = 32'h0000_0210;
        trace_buffer[3]  = 32'h0000_0220;
        trace_buffer[4]  = 32'h0000_0280;
        trace_buffer[5]  = 32'h0000_0300;
        trace_buffer[6]  = 32'h0000_0200;
        trace_buffer[7]  = 32'h0000_0380;
        trace_buffer[8]  = 32'h0000_0210;
        trace_buffer[9]  = 32'h0000_0400;
        trace_buffer[10] = 32'h0000_0224;
        trace_buffer[11] = 32'h0000_0500;
        trace_buffer[12] = 32'h0000_0300;
        trace_buffer[13] = 32'h0000_0580;
        trace_buffer[14] = 32'h0000_0200;
        trace_buffer[15] = 32'h0000_0210;

        run_scenario("scenario_4_mixed_trace", 16, 1);

        $display("[PASS] Scenario 4: Deterministic Mixed Trace verified successfully.");
        export_scenario_csv(csv_fd, "scenario_4_mixed_trace", 16);

        // Close results file
        $fclose(csv_fd);
        $display("----------------------------------------------------------------------");
        $display("[tb_cache_comparison] Results successfully written to results/results.csv");
        $display("======================================================================");
        $display("   ALL TEST SCENARIOS PASSED PERFECTLY!");
        $display("======================================================================");

        $finish;
    end

endmodule : tb_cache_comparison
