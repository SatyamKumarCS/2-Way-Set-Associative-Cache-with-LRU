// ============================================================================
// File: rtl/direct_mapped_cache.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 1 Responsibility: Direct-Mapped Cache Baseline
//
// Description:
//   Fully synthesizable 8-line Direct-Mapped Cache (128 bytes total capacity).
//   Each line stores 16 bytes organized as four 32-bit words, a 25-bit tag,
//   and 1 valid bit.
//
// Address Mapping (32-bit byte address):
//   - Tag:         address[31:7] (25 bits)
//   - Index:       address[6:4]  (3 bits, selects line 0 to 7)
//   - Word Index:  address[3:2]  (2 bits, selects word 0 to 3 in line)
//   - Byte Offset: address[1:0]  (2 bits, word-aligned = 2'b00)
//
// Storage Arrays:
//   - data_array  [0:7][0:3] (8 lines x 4 words, each 32 bits)
//   - tag_array   [0:7]      (8 lines x 25 bits)
//   - valid_array [0:7]      (8 lines x 1 bit)
//
// FSM States:
//   - IDLE:     Ready to accept a new CPU request
//   - LOOKUP:   Compare tag and check valid bit for hit/miss determination
//   - MEM_REQ:  Issue read request to memory for one refill word
//   - MEM_WAIT: Wait for memory response and buffer incoming word
//   - RESP:     Present requested word to CPU and hold valid until ready
//
// Replacement Policy:
//   - Direct-mapped: each address maps to exactly one line (Index = addr[6:4]).
//     A miss on a valid line directly evicts and replaces that line.
//
// Counters:
//   - hit_count:           increments once per CPU hit
//   - miss_count:          increments once per CPU miss
//   - mem_word_read_count: increments once per accepted memory word request
// ============================================================================

`ifndef DIRECT_MAPPED_CACHE_SV
`define DIRECT_MAPPED_CACHE_SV

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module direct_mapped_cache
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

    // Performance Counters
    output logic [31:0] hit_count,
    output logic [31:0] miss_count,
    output logic [31:0] mem_word_read_count
);

    // ------------------------------------------------------------------------
    // Internal Storage Arrays (8 lines, 4 words per line)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  data_array  [0:DM_LINES-1][0:WORDS_PER_LINE-1];
    logic [DM_TAG_BITS-1:0] tag_array   [0:DM_LINES-1];
    logic                   valid_array [0:DM_LINES-1];

    // ------------------------------------------------------------------------
    // State and Control Registers
    // ------------------------------------------------------------------------
    cache_state_e state_q, state_d;

    // Latched CPU request address
    logic [ADDR_WIDTH-1:0] req_addr_q;

    // Refill tracking registers
    logic [1:0]            refill_cnt_q;
    logic [DATA_WIDTH-1:0] refill_buf_q [0:WORDS_PER_LINE-1];

    // Response data holding register
    logic [DATA_WIDTH-1:0] resp_data_q;

    // Performance counter registers
    logic [31:0]           hit_count_q;
    logic [31:0]           miss_count_q;
    logic [31:0]           mem_word_read_count_q;

    // ------------------------------------------------------------------------
    // Address Field Extraction for Latched Request
    // ------------------------------------------------------------------------
    wire [DM_INDEX_BITS-1:0]  line_idx = req_addr_q[6:4]; // 3 bits: 0 to 7
    wire [DM_TAG_BITS-1:0]    req_tag  = req_addr_q[31:7]; // 25 bits tag
    wire [1:0]                word_idx = req_addr_q[3:2];  // 2 bits: 0 to 3

    // ------------------------------------------------------------------------
    // Tag Comparator and Hit Detection Logic
    // ------------------------------------------------------------------------
    wire line_valid = valid_array[line_idx];
    wire tag_match  = (tag_array[line_idx] == req_tag);
    wire is_hit     = line_valid && tag_match;

    // Continuous memory address generation: aligned 16-byte base + refill word offset
    assign mem_req_addr        = {req_addr_q[31:4], refill_cnt_q, 2'b00};

    // Performance counter output assignments
    assign hit_count           = hit_count_q;
    assign miss_count          = miss_count_q;
    assign mem_word_read_count = mem_word_read_count_q;

    // ------------------------------------------------------------------------
    // Combinational Next-State and Control Output Logic
    // ------------------------------------------------------------------------
    always_comb begin
        // Default control outputs
        state_d         = state_q;
        cpu_req_ready   = 1'b0;
        cpu_resp_valid  = 1'b0;
        cpu_resp_data   = resp_data_q;
        mem_req_valid   = 1'b0;
        mem_resp_ready  = 1'b0;

        case (state_q)
            IDLE: begin
                // Ready to accept a new CPU request
                cpu_req_ready = 1'b1;
                if (cpu_req_valid && cpu_req_ready) begin
                    state_d = LOOKUP;
                end
            end

            LOOKUP: begin
                if (is_hit) begin
                    // Cache Hit: data is selected and prepared for response
                    state_d = RESP;
                end else begin
                    // Cache Miss: initiate memory refill starting at word 0
                    state_d = MEM_REQ;
                end
            end

            MEM_REQ: begin
                // Present memory read request for word `refill_cnt_q`
                mem_req_valid = 1'b1;
                if (mem_req_valid && mem_req_ready) begin
                    // Memory accepted the read request
                    state_d = MEM_WAIT;
                end
            end

            MEM_WAIT: begin
                // Ready to accept incoming word from memory
                mem_resp_ready = 1'b1;
                if (mem_resp_valid && mem_resp_ready) begin
                    if (refill_cnt_q == 2'd3) begin
                        // All 4 words collected; write into line storage and respond
                        state_d = RESP;
                    end else begin
                        // Request next consecutive word
                        state_d = MEM_REQ;
                    end
                end
            end

            RESP: begin
                // Hold response valid and data stable until accepted by CPU
                cpu_resp_valid = 1'b1;
                cpu_resp_data  = resp_data_q;
                if (cpu_resp_valid && cpu_resp_ready) begin
                    // Transfer complete; return to IDLE for next request
                    state_d = IDLE;
                end
            end

            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------------
    // Synchronous Updates and Storage Modification
    // ------------------------------------------------------------------------
    integer i;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Active-low synchronous reset
            state_q               <= IDLE;
            req_addr_q            <= '0;
            refill_cnt_q          <= '0;
            resp_data_q           <= '0;
            hit_count_q           <= '0;
            miss_count_q          <= '0;
            mem_word_read_count_q <= '0;

            for (i = 0; i < DM_LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
            end

            for (i = 0; i < WORDS_PER_LINE; i = i + 1) begin
                refill_buf_q[i] <= '0;
            end
        end else begin
            state_q <= state_d;

            case (state_q)
                IDLE: begin
                    if (cpu_req_valid && cpu_req_ready) begin
                        // Latch requested CPU byte address
                        req_addr_q <= cpu_req_addr;
                    end
                end

                LOOKUP: begin
                    if (is_hit) begin
                        // Hit: select requested word from data_array and count hit
                        resp_data_q <= data_array[line_idx][word_idx];
                        hit_count_q <= hit_count_q + 1'b1;
                    end else begin
                        // Miss: start refill sequence at word 0 and count miss
                        refill_cnt_q <= 2'b00;
                        miss_count_q <= miss_count_q + 1'b1;
                    end
                end

                MEM_REQ: begin
                    if (mem_req_valid && mem_req_ready) begin
                        // Count every accepted memory word request
                        mem_word_read_count_q <= mem_word_read_count_q + 1'b1;
                    end
                end

                MEM_WAIT: begin
                    if (mem_resp_valid && mem_resp_ready) begin
                        // Buffer incoming word
                        refill_buf_q[refill_cnt_q] <= mem_resp_data;

                        if (refill_cnt_q == 2'd3) begin
                            // All four words received: commit full line to data_array
                            data_array[line_idx][0] <= refill_buf_q[0];
                            data_array[line_idx][1] <= refill_buf_q[1];
                            data_array[line_idx][2] <= refill_buf_q[2];
                            data_array[line_idx][3] <= mem_resp_data;

                            // Update tag and mark line valid
                            tag_array[line_idx]   <= req_tag;
                            valid_array[line_idx] <= 1'b1;

                            // Select the originally requested word for CPU response
                            if (word_idx == 2'd3) begin
                                resp_data_q <= mem_resp_data;
                            end else begin
                                resp_data_q <= refill_buf_q[word_idx];
                            end
                        end else begin
                            // Increment word count for next refill request
                            refill_cnt_q <= refill_cnt_q + 1'b1;
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

endmodule : direct_mapped_cache

`endif // DIRECT_MAPPED_CACHE_SV
