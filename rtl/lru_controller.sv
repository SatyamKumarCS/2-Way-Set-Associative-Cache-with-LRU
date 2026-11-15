// ============================================================================
// File: rtl/lru_controller.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 3 Responsibility: LRU Replacement State
//
// Description:
//   Stores one LRU (least-recently-used) bit for each of the 4 cache sets.
//   With only two ways per set, a single bit is enough to remember which
//   way was used less recently:
//
//     lru_bits[set] = 0 -> Way 0 is the replacement candidate (victim)
//     lru_bits[set] = 1 -> Way 1 is the replacement candidate (victim)
//
// Update Rule (when update_en is high on a rising clock edge):
//   - accessed_way = 0 -> lru_bits[set_index] <= 1 (Way 1 becomes victim)
//   - accessed_way = 1 -> lru_bits[set_index] <= 0 (Way 0 becomes victim)
//   Only the bit of the addressed set changes; the other sets keep their
//   state.
//
// Read Rule (combinational):
//   victim_way = lru_bits[set_index]
//
// Reset:
//   Synchronous active-low reset clears every bit to 0, so Way 0 is the
//   initial replacement candidate in every set.
// ============================================================================

`ifndef LRU_CONTROLLER_SV
`define LRU_CONTROLLER_SV

`timescale 1ns / 1ps

module lru_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [1:0] set_index,
    input  logic       update_en,
    input  logic       accessed_way,
    output logic       victim_way
);

    // ------------------------------------------------------------------------
    // LRU State Storage (one bit per set)
    // ------------------------------------------------------------------------
    logic lru_bits [0:3];

    // ------------------------------------------------------------------------
    // Victim Selection for the Currently Addressed Set
    // ------------------------------------------------------------------------
    assign victim_way = lru_bits[set_index];

    // ------------------------------------------------------------------------
    // Synchronous Reset and LRU Update
    // ------------------------------------------------------------------------
    integer s_idx;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (s_idx = 0; s_idx < 4; s_idx = s_idx + 1) begin
                lru_bits[s_idx] <= 1'b0;
            end
        end else if (update_en) begin
            if (accessed_way == 1'b0) begin
                // Way 0 was just used, so Way 1 is now least recently used
                lru_bits[set_index] <= 1'b1;
            end else begin
                // Way 1 was just used, so Way 0 is now least recently used
                lru_bits[set_index] <= 1'b0;
            end
        end
    end

endmodule : lru_controller

`endif // LRU_CONTROLLER_SV
