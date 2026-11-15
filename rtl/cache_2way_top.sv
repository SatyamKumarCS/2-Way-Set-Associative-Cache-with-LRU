// ============================================================================
// File: rtl/cache_2way_top.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 3 Responsibility: Two-Way Cache Top-Level Integration
//
// Description:
//   Complete 128-byte, 4-set x 2-way read-only blocking cache with LRU
//   replacement. Exposes the same CPU, memory and counter ports as
//   `direct_mapped_cache` so both caches can be compared on identical traces.
//
// Submodules:
//   - u_controller (cache_2way_controller): FSM, refill, counters
//   - u_datapath   (cache_2way_datapath):   tags, valid bits, data, compare
//   - u_lru        (lru_controller):        one LRU bit per set
//
//                    +---------------------------+
//   CPU  <---------> |                           | <---------> Memory
//                    |   cache_2way_controller   |
//   Counters <------ |                           |
//                    +---------------------------+
//                       |  dp_*  ^        |  lru_*  ^
//                       v        |        v         |
//              +---------------------+  +----------------+
//              | cache_2way_datapath |  | lru_controller |
//              +---------------------+  +----------------+
// ============================================================================

`ifndef CACHE_2WAY_TOP_SV
`define CACHE_2WAY_TOP_SV

`timescale 1ns / 1ps

module cache_2way_top (
    input  logic        clk,
    input  logic        rst_n,

    // CPU Request Interface
    input  logic        cpu_req_valid,
    output logic        cpu_req_ready,
    input  logic [31:0] cpu_req_addr,

    // CPU Response Interface
    output logic        cpu_resp_valid,
    input  logic        cpu_resp_ready,
    output logic [31:0] cpu_resp_data,

    // Memory Request Interface
    output logic        mem_req_valid,
    input  logic        mem_req_ready,
    output logic [31:0] mem_req_addr,

    // Memory Response Interface
    input  logic        mem_resp_valid,
    output logic        mem_resp_ready,
    input  logic [31:0] mem_resp_data,

    // Performance Counters
    output logic [31:0] hit_count,
    output logic [31:0] miss_count,
    output logic [31:0] mem_word_read_count
);

    // ------------------------------------------------------------------------
    // Controller <-> Datapath Wires
    // ------------------------------------------------------------------------
    logic [1:0]  dp_set_index;
    logic [25:0] dp_request_tag;
    logic [1:0]  dp_word_index;
    logic        dp_hit0;
    logic        dp_hit1;
    logic        dp_valid0;
    logic        dp_valid1;
    logic [31:0] dp_selected_data;
    logic        dp_fill_word_we;
    logic        dp_fill_way;
    logic [1:0]  dp_fill_word_index;
    logic [31:0] dp_fill_word_data;
    logic        dp_fill_meta_we;
    logic [25:0] dp_fill_tag;

    // ------------------------------------------------------------------------
    // Controller <-> LRU Wires
    // ------------------------------------------------------------------------
    logic [1:0]  lru_set_index;
    logic        lru_update_en;
    logic        lru_accessed_way;
    logic        lru_victim_way;

    // ------------------------------------------------------------------------
    // Cache Controller (FSM, refill sequencing, counters)
    // ------------------------------------------------------------------------
    cache_2way_controller u_controller (
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

        .dp_set_index        (dp_set_index),
        .dp_request_tag      (dp_request_tag),
        .dp_word_index       (dp_word_index),
        .dp_hit0             (dp_hit0),
        .dp_hit1             (dp_hit1),
        .dp_valid0           (dp_valid0),
        .dp_valid1           (dp_valid1),
        .dp_selected_data    (dp_selected_data),
        .dp_fill_word_we     (dp_fill_word_we),
        .dp_fill_way         (dp_fill_way),
        .dp_fill_word_index  (dp_fill_word_index),
        .dp_fill_word_data   (dp_fill_word_data),
        .dp_fill_meta_we     (dp_fill_meta_we),
        .dp_fill_tag         (dp_fill_tag),

        .lru_set_index       (lru_set_index),
        .lru_update_en       (lru_update_en),
        .lru_accessed_way    (lru_accessed_way),
        .lru_victim_way      (lru_victim_way),

        .hit_count           (hit_count),
        .miss_count          (miss_count),
        .mem_word_read_count (mem_word_read_count)
    );

    // ------------------------------------------------------------------------
    // Two-Way Datapath (Member 2: storage, tag compare, word select)
    // ------------------------------------------------------------------------
    cache_2way_datapath u_datapath (
        .clk             (clk),
        .rst_n           (rst_n),
        .set_index       (dp_set_index),
        .request_tag     (dp_request_tag),
        .word_index      (dp_word_index),
        .hit0            (dp_hit0),
        .hit1            (dp_hit1),
        .valid0          (dp_valid0),
        .valid1          (dp_valid1),
        .selected_data   (dp_selected_data),
        .fill_word_we    (dp_fill_word_we),
        .fill_way        (dp_fill_way),
        .fill_word_index (dp_fill_word_index),
        .fill_word_data  (dp_fill_word_data),
        .fill_meta_we    (dp_fill_meta_we),
        .fill_tag        (dp_fill_tag)
    );

    // ------------------------------------------------------------------------
    // LRU Replacement State (one bit per set)
    // ------------------------------------------------------------------------
    lru_controller u_lru (
        .clk          (clk),
        .rst_n        (rst_n),
        .set_index    (lru_set_index),
        .update_en    (lru_update_en),
        .accessed_way (lru_accessed_way),
        .victim_way   (lru_victim_way)
    );

endmodule : cache_2way_top

`endif // CACHE_2WAY_TOP_SV
