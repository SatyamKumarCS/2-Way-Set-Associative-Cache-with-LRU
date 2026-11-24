// ============================================================================
// File: tb/tb_lru_demo_wave.sv
// Project: 2-Way Set-Associative Cache with LRU
// Description:
//   Dedicated, clean waveform-focused testbench for the canonical 6-access
//   LRU replacement sequence:
//       Step 1: Access A (0x00000000) -> MISS, loads into Way 0
//       Step 2: Access B (0x00000080) -> MISS, loads into Way 1
//       Step 3: Access A (0x00000000) -> HIT in Way 0 (LRU bit points to Way 1)
//       Step 4: Access C (0x00000100) -> MISS, evicts LRU victim Way 1 (B)
//       Step 5: Access A (0x00000000) -> HIT in Way 0 (LRU bit points to Way 1)
//       Step 6: Access B (0x00000080) -> MISS, evicts LRU victim Way 1 (C)
//
// Expected Final State:
//   Set 0: Way 0 = A, Way 1 = B (C is completely evicted)
//
// Output VCD: build/waves/lru_replacement_demo.vcd
// ============================================================================

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module tb_lru_demo_wave;
    import cache_pkg::*;

    // ------------------------------------------------------------------------
    // Clock and Reset Generation
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz (10 ns period)

    // ------------------------------------------------------------------------
    // CPU Interface Signals
    // ------------------------------------------------------------------------
    logic        cpu_req_valid;
    logic        cpu_req_ready;
    logic [31:0] cpu_req_addr;
    logic        cpu_resp_valid;
    logic        cpu_resp_ready;
    logic [31:0] cpu_resp_data;

    // ------------------------------------------------------------------------
    // Memory Interface Signals
    // ------------------------------------------------------------------------
    logic        mem_req_valid;
    logic        mem_req_ready;
    logic [31:0] mem_req_addr;
    logic        mem_resp_valid;
    logic        mem_resp_ready;
    logic [31:0] mem_resp_data;

    // ------------------------------------------------------------------------
    // Performance Counters
    // ------------------------------------------------------------------------
    logic [31:0] hit_count;
    logic [31:0] miss_count;
    logic [31:0] mem_word_read_count;

    // ------------------------------------------------------------------------
    // Cache Instance (DUT)
    // ------------------------------------------------------------------------
    cache_2way_top dut (
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

    // ------------------------------------------------------------------------
    // Reference Main Memory Model
    // ------------------------------------------------------------------------
    simple_main_memory #(
        .LATENCY_CYCLES     (2),
        .REQUEST_GAP_CYCLES (1)
    ) mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_req_valid  (mem_req_valid),
        .mem_req_ready  (mem_req_ready),
        .mem_req_addr   (mem_req_addr),
        .mem_resp_valid (mem_resp_valid),
        .mem_resp_ready (mem_resp_ready),
        .mem_resp_data  (mem_resp_data)
    );

    // ------------------------------------------------------------------------
    // Trace Constants
    // ------------------------------------------------------------------------
    localparam [31:0] ADDR_A = 32'h0000_0000;
    localparam [31:0] ADDR_B = 32'h0000_0080;
    localparam [31:0] ADDR_C = 32'h0000_0100;

    // ------------------------------------------------------------------------
    // Waveform Dumping Setup
    // ------------------------------------------------------------------------
    initial begin
        $dumpfile("build/waves/lru_replacement_demo.vcd");
        $dumpvars(0, tb_lru_demo_wave);
    end

    // ------------------------------------------------------------------------
    // CPU Read Access Task
    // ------------------------------------------------------------------------
    task automatic cpu_read(
        input [31:0] addr,
        input string  desc,
        input bit     expected_hit
    );
        int timeout;
        bit hit_observed;

        // Drive request on negedge clk to eliminate race conditions
        @(negedge clk);
        cpu_req_valid = 1'b1;
        cpu_req_addr  = addr;
        cpu_resp_ready = 1'b1;

        // Wait for request acceptance
        while (!cpu_req_ready) begin
            @(posedge clk);
        end
        @(posedge clk);
        @(negedge clk);
        cpu_req_valid = 1'b0;

        // Sample hit status during LOOKUP from controller
        hit_observed = dut.u_controller.lookup_hit;

        // Wait for CPU response
        timeout = 0;
        while (!cpu_resp_valid) begin
            @(posedge clk);
            timeout++;
            if (timeout > 100) $fatal(1, "[TIMEOUT] Waiting for CPU response at addr 0x%08h", addr);
        end

        @(posedge clk);
        @(negedge clk);
        cpu_resp_ready = 1'b0;
        @(posedge clk);

        $display("[%0t ns] %s: Addr=0x%08h -> %s | LRU bit[0]=%0b | Way0_tag=0x%07h (V=%0b) | Way1_tag=0x%07h (V=%0b)",
                 $time, desc, addr,
                 (hit_observed ? "HIT " : "MISS"),
                 dut.u_lru.lru_bits[0],
                 dut.u_datapath.way0_tag[0], dut.u_datapath.way0_valid[0],
                 dut.u_datapath.way1_tag[0], dut.u_datapath.way1_valid[0]);

        if (hit_observed !== expected_hit) begin
            $fatal(1, "[FAIL] %s expected hit=%0b, observed=%0b", desc, expected_hit, hit_observed);
        end
    endtask

    // ------------------------------------------------------------------------
    // Verification Sequence
    // ------------------------------------------------------------------------
    initial begin
        // Reset initialization
        rst_n          = 1'b0;
        cpu_req_valid  = 1'b0;
        cpu_req_addr   = 32'h0;
        cpu_resp_ready = 1'b0;

        #25;
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("==================================================================");
        $display("   LRU REPLACEMENT DEMONSTRATION WAVEFORM SIMULATION");
        $display("   Sequence: A -> B -> A -> C -> A -> B");
        $display("==================================================================");

        // Step 1: Access A -> Miss, fills Way 0
        cpu_read(ADDR_A, "Step 1: Access A (0x00)", 1'b0);

        // Step 2: Access B -> Miss, fills Way 1
        cpu_read(ADDR_B, "Step 2: Access B (0x80)", 1'b0);

        // Step 3: Access A -> HIT in Way 0, LRU bit updates to 1 (victim=Way 1)
        cpu_read(ADDR_A, "Step 3: Access A (0x00)", 1'b1);

        // Step 4: Access C -> Miss, LRU bit is 1, so C replaces Way 1 (B)!
        cpu_read(ADDR_C, "Step 4: Access C (0x100)", 1'b0);

        // Step 5: Access A -> HIT in Way 0, LRU bit updates to 1 (victim=Way 1)
        cpu_read(ADDR_A, "Step 5: Access A (0x00)", 1'b1);

        // Step 6: Access B -> Miss (B was evicted), LRU bit is 1, B replaces Way 1 (C)!
        cpu_read(ADDR_B, "Step 6: Access B (0x80)", 1'b0);

        // Final State Check
        #20;
        $display("------------------------------------------------------------------");
        $display("FINAL STATE VERIFICATION OF SET 0:");
        $display("  Way 0 Tag: 0x%07h (Valid=%0b) [Expected: A = 0x0000000]",
                 dut.u_datapath.way0_tag[0], dut.u_datapath.way0_valid[0]);
        $display("  Way 1 Tag: 0x%07h (Valid=%0b) [Expected: B = 0x0000002]",
                 dut.u_datapath.way1_tag[0], dut.u_datapath.way1_valid[0]);
        $display("  LRU bit[0]: %0b [Expected: 0 -> Way 0 is LRU victim candidate]",
                 dut.u_lru.lru_bits[0]);

        if (dut.u_datapath.way0_tag[0] == 26'h0000000 &&
            dut.u_datapath.way1_tag[0] == 26'h0000002 &&
            dut.u_datapath.way0_valid[0] == 1'b1 &&
            dut.u_datapath.way1_valid[0] == 1'b1) begin
            $display("[SUCCESS] Verified: Way 0 = A, Way 1 = B, Block C was successfully evicted!");
        end else begin
            $fatal(1, "[FAIL] Final state does not match expected Way 0 = A, Way 1 = B!");
        end

        $display("==================================================================");
        $display("Waveform successfully dumped to build/waves/lru_replacement_demo.vcd");
        $display("==================================================================");
        $finish;
    end

endmodule
