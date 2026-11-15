// ============================================================================
// File: rtl/cache_2way_datapath.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 2 Responsibility: Two-Way Cache Datapath Storage, Parallel Tag
//                          Comparison, and Word Selection
//
// Description:
//   Synthesizable 2-Way Set-Associative Cache Datapath (128 bytes total data capacity).
//   - Organization: 4 sets, 2 ways per set (8 cache lines total).
//   - Line size: 16 bytes organized as four 32-bit words.
//   - Tag width: 26 bits (address[31:6]).
//   - Set index: 2 bits (address[5:4], sets 0 to 3).
//   - Word index: 2 bits (address[3:2], words 0 to 3).
//   - Byte offset: 2 bits (address[1:0], word-aligned = 2'b00).
//
// Storage Arrays:
//   logic [31:0] way0_data [0:3][0:3];  // Way 0: 4 sets x 4 words (32-bit each)
//   logic [31:0] way1_data [0:3][0:3];  // Way 1: 4 sets x 4 words (32-bit each)
//   logic [25:0] way0_tag  [0:3];       // Way 0 tags: 4 sets x 26 bits
//   logic [25:0] way1_tag  [0:3];       // Way 1 tags: 4 sets x 26 bits
//   logic        way0_valid[0:3];       // Way 0 valid bits: 4 sets x 1 bit
//   logic        way1_valid[0:3];       // Way 1 valid bits: 4 sets x 1 bit
//
// Lookup Operation (Combinational):
//   - Parallel tag comparators:
//       hit0 = way0_valid[set_index] && (way0_tag[set_index] == request_tag);
//       hit1 = way1_valid[set_index] && (way1_tag[set_index] == request_tag);
//   - Status signals:
//       valid0 = way0_valid[set_index];
//       valid1 = way1_valid[set_index];
//   - Data Selection:
//       If hit0, selected_data = way0_data[set_index][word_index].
//       Else if hit1, selected_data = way1_data[set_index][word_index].
//       Else selected_data = 32'h00000000.
//       (Deterministic priority: Way 0 takes priority if both hit).
//
// Fill Operation (Synchronous on posedge clk, active-low synchronous reset):
//   - Word Write:
//       When fill_word_we is asserted:
//         fill_way == 0: writes fill_word_data to way0_data[set_index][fill_word_index]
//         fill_way == 1: writes fill_word_data to way1_data[set_index][fill_word_index]
//   - Metadata Write (Tag & Valid):
//       When fill_meta_we is asserted:
//         fill_way == 0: writes fill_tag to way0_tag[set_index], sets way0_valid[set_index] = 1'b1
//         fill_way == 1: writes fill_tag to way1_tag[set_index], sets way1_valid[set_index] = 1'b1
// ============================================================================

`ifndef CACHE_2WAY_DATAPATH_SV
`define CACHE_2WAY_DATAPATH_SV

`timescale 1ns / 1ps

`ifndef CACHE_PKG_SV
`include "cache_pkg.sv"
`endif

module cache_2way_datapath (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  set_index,
    input  logic [25:0] request_tag,
    input  logic [1:0]  word_index,
    output logic        hit0,
    output logic        hit1,
    output logic        valid0,
    output logic        valid1,
    output logic [31:0] selected_data,
    input  logic        fill_word_we,
    input  logic        fill_way,
    input  logic [1:0]  fill_word_index,
    input  logic [31:0] fill_word_data,
    input  logic        fill_meta_we,
    input  logic [25:0] fill_tag
);

    // ------------------------------------------------------------------------
    // Internal Storage Arrays (4 sets, 2 ways, 4 words per line)
    // ------------------------------------------------------------------------
    logic [31:0] way0_data  [0:3][0:3];
    logic [31:0] way1_data  [0:3][0:3];
    logic [25:0] way0_tag   [0:3];
    logic [25:0] way1_tag   [0:3];
    logic        way0_valid [0:3];
    logic        way1_valid [0:3];

    // ------------------------------------------------------------------------
    // Status Valid Bits for the Selected Set
    // ------------------------------------------------------------------------
    assign valid0 = way0_valid[set_index];
    assign valid1 = way1_valid[set_index];

    // ------------------------------------------------------------------------
    // Parallel Tag Comparison and Hit Detection Logic
    // ------------------------------------------------------------------------
    // Both ways are evaluated concurrently in the selected set.
    // A hit occurs if and only if the way is valid and its stored tag equals request_tag.
    assign hit0   = way0_valid[set_index] && (way0_tag[set_index] == request_tag);
    assign hit1   = way1_valid[set_index] && (way1_tag[set_index] == request_tag);

    // ------------------------------------------------------------------------
    // Word Data Multiplexer / Selector
    // ------------------------------------------------------------------------
    // Multiplexes the requested 32-bit word from the hitting way.
    // Deterministic Priority: If both ways hit simultaneously (which represents an
    // illegal duplicate tag condition), Way 0 is chosen deterministically.
    // If neither way hits, selected_data defaults to zero (32'h00000000).
    always_comb begin
        if (hit0) begin
            selected_data = way0_data[set_index][word_index];
        end else if (hit1) begin
            selected_data = way1_data[set_index][word_index];
        end else begin
            selected_data = 32'h00000000;
        end
    end

    // ------------------------------------------------------------------------
    // Synchronous Write and Reset Logic
    // ------------------------------------------------------------------------
    // Synchronous active-low reset: clears all valid bits, tags, and data.
    // fill_word_we: writes one word into the addressed set, way, and word position.
    // fill_meta_we: writes the tag and asserts the valid bit for the filled way.
    integer s_idx, w_idx;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (s_idx = 0; s_idx < 4; s_idx = s_idx + 1) begin
                way0_valid[s_idx] <= 1'b0;
                way1_valid[s_idx] <= 1'b0;
                way0_tag[s_idx]   <= 26'd0;
                way1_tag[s_idx]   <= 26'd0;
                for (w_idx = 0; w_idx < 4; w_idx = w_idx + 1) begin
                    way0_data[s_idx][w_idx] <= 32'd0;
                    way1_data[s_idx][w_idx] <= 32'd0;
                end
            end
        end else begin
            // 1. Write refill word data
            if (fill_word_we) begin
                if (fill_way == 1'b0) begin
                    way0_data[set_index][fill_word_index] <= fill_word_data;
                end else begin
                    way1_data[set_index][fill_word_index] <= fill_word_data;
                end
            end

            // 2. Commit line metadata (tag and valid bit)
            if (fill_meta_we) begin
                if (fill_way == 1'b0) begin
                    way0_tag[set_index]   <= fill_tag;
                    way0_valid[set_index] <= 1'b1;
                end else begin
                    way1_tag[set_index]   <= fill_tag;
                    way1_valid[set_index] <= 1'b1;
                end
            end
        end
    end

endmodule : cache_2way_datapath

`endif // CACHE_2WAY_DATAPATH_SV
