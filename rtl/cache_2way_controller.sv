// ============================================================================
// File: rtl/cache_2way_controller.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 3 Responsibility: Two-Way Cache Controller FSM
//
// Description:
//   Control unit for the 4-set x 2-way read-only blocking cache. It does not
//   store any cache lines itself; it drives `cache_2way_datapath` (storage,
//   tag compare, word select) and `lru_controller` (replacement state).
//
// Address Mapping (latched request address req_addr_q):
//   - Tag:        req_addr_q[31:6] (26 bits)
//   - Set index:  req_addr_q[5:4]  (2 bits, sets 0 to 3)
//   - Word index: req_addr_q[3:2]  (2 bits, words 0 to 3)
//
// FSM States (cache_pkg::cache_state_e):
//   - IDLE:     cpu_req_ready = 1; latch cpu_req_addr on handshake
//   - LOOKUP:   read datapath hit0/hit1 for the latched address
//                 hit  -> capture selected_data, count hit, update LRU
//                 miss -> count miss, choose fill way, clear refill counter
//   - MEM_REQ:  mem_req_valid = 1 for word refill_count_q of the line
//   - MEM_WAIT: mem_resp_ready = 1; write the accepted word into the
//               datapath; after word 3 commit tag/valid and update LRU
//   - RESP:     cpu_resp_valid = 1 holding resp_data_q until accepted
//
// Replacement Way Selection (on a miss):
//   1. Way 0 if Way 0 is invalid
//   2. Way 1 if Way 1 is invalid
//   3. Otherwise the LRU victim from lru_controller
//
// Counters:
//   - hit_count:           +1 per CPU lookup that hits
//   - miss_count:          +1 per CPU lookup that misses
//   - mem_word_read_count: +1 per accepted memory request
// ============================================================================

`ifndef CACHE_2WAY_CONTROLLER_SV
`define CACHE_2WAY_CONTROLLER_SV

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module cache_2way_controller
    import cache_pkg::*;
(
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

    // Datapath Lookup Control
    output logic [1:0]  dp_set_index,
    output logic [25:0] dp_request_tag,
    output logic [1:0]  dp_word_index,

    // Datapath Lookup Status
    input  logic        dp_hit0,
    input  logic        dp_hit1,
    input  logic        dp_valid0,
    input  logic        dp_valid1,
    input  logic [31:0] dp_selected_data,

    // Datapath Refill Control
    output logic        dp_fill_word_we,
    output logic        dp_fill_way,
    output logic [1:0]  dp_fill_word_index,
    output logic [31:0] dp_fill_word_data,
    output logic        dp_fill_meta_we,
    output logic [25:0] dp_fill_tag,

    // LRU Controller Interface
    output logic [1:0]  lru_set_index,
    output logic        lru_update_en,
    output logic        lru_accessed_way,
    input  logic        lru_victim_way,

    // Performance Counters
    output logic [31:0] hit_count,
    output logic [31:0] miss_count,
    output logic [31:0] mem_word_read_count
);

    // ------------------------------------------------------------------------
    // State and Control Registers
    // ------------------------------------------------------------------------
    cache_state_e state_q, state_d;

    // Latched CPU request address
    logic [ADDR_WIDTH-1:0] req_addr_q;

    // Refill tracking: next word to request, and the way being filled
    logic [1:0]            refill_count_q;
    logic                  fill_way_q;

    // Response data holding register
    logic [DATA_WIDTH-1:0] resp_data_q;

    // Performance counter registers
    logic [31:0]           hit_count_q;
    logic [31:0]           miss_count_q;
    logic [31:0]           mem_word_read_count_q;

    // ------------------------------------------------------------------------
    // Address Field Extraction for Latched Request
    // ------------------------------------------------------------------------
    logic [SA_TAG_BITS-1:0]   req_tag;
    logic [SA_INDEX_BITS-1:0] req_set;
    logic [1:0]               req_word;

    assign req_tag  = req_addr_q[31:6]; // 26 bits tag
    assign req_set  = req_addr_q[5:4];  // 2 bits: 0 to 3
    assign req_word = req_addr_q[3:2];  // 2 bits: 0 to 3

    // ------------------------------------------------------------------------
    // Handshake Strobes (transfer occurs when valid && ready on a clock edge)
    // ------------------------------------------------------------------------
    logic cpu_req_fire;
    logic mem_req_fire;
    logic mem_resp_fire;

    assign cpu_req_fire  = cpu_req_valid  && cpu_req_ready;
    assign mem_req_fire  = mem_req_valid  && mem_req_ready;
    assign mem_resp_fire = mem_resp_valid && mem_resp_ready;

    // ------------------------------------------------------------------------
    // Hit Detection and Replacement Way Selection
    // ------------------------------------------------------------------------
    logic lookup_hit;
    logic hit_way;
    logic replace_way;

    assign lookup_hit = dp_hit0 || dp_hit1;

    // Way 0 priority if both ways hit, matching the datapath data selector
    assign hit_way = dp_hit0 ? 1'b0 : 1'b1;

    // Fill an invalid way before evicting a valid one; otherwise use LRU
    always_comb begin
        if (!dp_valid0) begin
            replace_way = 1'b0;
        end else if (!dp_valid1) begin
            replace_way = 1'b1;
        end else begin
            replace_way = lru_victim_way;
        end
    end

    // ------------------------------------------------------------------------
    // Fixed Datapath, LRU, Memory and CPU Connections
    // ------------------------------------------------------------------------
    // Lookup and fill both address the set of the latched request
    assign dp_set_index       = req_set;
    assign dp_request_tag     = req_tag;
    assign dp_word_index      = req_word;
    assign lru_set_index      = req_set;

    // Refill payload; only takes effect when the write enables are asserted
    assign dp_fill_way        = fill_way_q;
    assign dp_fill_word_index = refill_count_q;
    assign dp_fill_word_data  = mem_resp_data;
    assign dp_fill_tag        = req_tag;

    // Aligned 16-byte line base + refill word offset (stable in MEM_REQ)
    assign mem_req_addr       = {req_addr_q[31:4], refill_count_q, 2'b00};

    // Response data comes from a register, so it is stable under backpressure
    assign cpu_resp_data      = resp_data_q;

    // Performance counter output assignments
    assign hit_count           = hit_count_q;
    assign miss_count          = miss_count_q;
    assign mem_word_read_count = mem_word_read_count_q;

    // ------------------------------------------------------------------------
    // Combinational Next-State and Control Output Logic
    // ------------------------------------------------------------------------
    always_comb begin
        // Default control outputs
        state_d          = state_q;
        cpu_req_ready    = 1'b0;
        cpu_resp_valid   = 1'b0;
        mem_req_valid    = 1'b0;
        mem_resp_ready   = 1'b0;
        dp_fill_word_we  = 1'b0;
        dp_fill_meta_we  = 1'b0;
        lru_update_en    = 1'b0;
        lru_accessed_way = 1'b0;

        case (state_q)
            IDLE: begin
                // Ready to accept a new CPU request
                cpu_req_ready = 1'b1;
                if (cpu_req_valid) begin
                    state_d = LOOKUP;
                end
            end

            LOOKUP: begin
                if (lookup_hit) begin
                    // Cache Hit: mark the hitting way as most recently used
                    lru_update_en    = 1'b1;
                    lru_accessed_way = hit_way;
                    state_d          = RESP;
                end else begin
                    // Cache Miss: start refill at word 0 of the line
                    state_d = MEM_REQ;
                end
            end

            MEM_REQ: begin
                // Present memory read request for word `refill_count_q`
                mem_req_valid = 1'b1;
                if (mem_req_ready) begin
                    state_d = MEM_WAIT;
                end
            end

            MEM_WAIT: begin
                // Ready to accept the refill word from memory
                mem_resp_ready = 1'b1;
                if (mem_resp_valid) begin
                    // Write the accepted word into the selected way
                    dp_fill_word_we = 1'b1;
                    if (refill_count_q == 2'd3) begin
                        // Last word: commit tag/valid and mark the way as MRU
                        dp_fill_meta_we  = 1'b1;
                        lru_update_en    = 1'b1;
                        lru_accessed_way = fill_way_q;
                        state_d          = RESP;
                    end else begin
                        // Request next consecutive word
                        state_d = MEM_REQ;
                    end
                end
            end

            RESP: begin
                // Hold response valid and data stable until accepted by CPU
                cpu_resp_valid = 1'b1;
                if (cpu_resp_ready) begin
                    state_d = IDLE;
                end
            end

            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------------
    // Synchronous Register Updates
    // ------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Active-low synchronous reset
            state_q               <= IDLE;
            req_addr_q            <= '0;
            refill_count_q        <= '0;
            fill_way_q            <= 1'b0;
            resp_data_q           <= '0;
            hit_count_q           <= '0;
            miss_count_q          <= '0;
            mem_word_read_count_q <= '0;
        end else begin
            state_q <= state_d;

            case (state_q)
                IDLE: begin
                    if (cpu_req_fire) begin
                        // Latch requested CPU byte address
                        req_addr_q <= cpu_req_addr;
                    end
                end

                LOOKUP: begin
                    if (lookup_hit) begin
                        // Hit: capture requested word and count hit
                        resp_data_q <= dp_selected_data;
                        hit_count_q <= hit_count_q + 1'b1;
                    end else begin
                        // Miss: remember the fill way, restart at word 0, count miss
                        fill_way_q     <= replace_way;
                        refill_count_q <= 2'b00;
                        miss_count_q   <= miss_count_q + 1'b1;
                    end
                end

                MEM_REQ: begin
                    if (mem_req_fire) begin
                        // Count every accepted memory word request
                        mem_word_read_count_q <= mem_word_read_count_q + 1'b1;
                    end
                end

                MEM_WAIT: begin
                    if (mem_resp_fire) begin
                        // Keep the word the CPU originally asked for
                        if (refill_count_q == req_word) begin
                            resp_data_q <= mem_resp_data;
                        end

                        if (refill_count_q != 2'd3) begin
                            // Advance to the next word of the line
                            refill_count_q <= refill_count_q + 1'b1;
                        end
                    end
                end

                RESP: begin
                    // Data and valid signals held stable until cpu_resp_ready
                end

                default: ;
            endcase
        end
    end

endmodule : cache_2way_controller

`endif // CACHE_2WAY_CONTROLLER_SV
