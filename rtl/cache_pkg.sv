// ============================================================================
// File: rtl/cache_pkg.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 1 Responsibility: Shared constants, parameters, and FSM states
//
// Description:
//   This package defines the common architectural configuration parameters
//   and FSM states used across the cache implementations.
// ============================================================================

`ifndef CACHE_PKG_SV
`define CACHE_PKG_SV

`timescale 1ns / 1ps

package cache_pkg;

    // ------------------------------------------------------------------------
    // Architectural Configuration Parameters
    // ------------------------------------------------------------------------
    localparam int ADDR_WIDTH      = 32;   // 32-bit CPU and Memory Addresses
    localparam int DATA_WIDTH      = 32;   // 32-bit Data Word Width
    localparam int LINE_BYTES      = 16;   // 16 Bytes per Cache Line
    localparam int WORDS_PER_LINE  = 4;    // 4 Words (32-bit each) per Line

    // ------------------------------------------------------------------------
    // Direct-Mapped Cache Parameters (8 lines x 1 way = 128 bytes)
    // ------------------------------------------------------------------------
    localparam int DM_LINES        = 8;    // 8 Cache Lines
    localparam int DM_INDEX_BITS   = 3;    // address[6:4] (3 bits to select 8 lines)
    localparam int DM_TAG_BITS     = 25;   // address[31:7] (25 bits tag)

    // ------------------------------------------------------------------------
    // Set-Associative Cache Parameters (4 sets x 2 ways = 128 bytes)
    // ------------------------------------------------------------------------
    localparam int SA_SETS         = 4;    // 4 Sets
    localparam int SA_WAYS         = 2;    // 2 Ways per Set
    localparam int SA_INDEX_BITS   = 2;    // address[5:4] (2 bits to select 4 sets)
    localparam int SA_TAG_BITS     = 26;   // address[31:6] (26 bits tag)

    // ------------------------------------------------------------------------
    // Memory Model Configuration
    // ------------------------------------------------------------------------
    localparam int MEM_WORDS       = 1024; // 1024 Words in Reference Memory

    // ------------------------------------------------------------------------
    // Cache Controller FSM States
    // ------------------------------------------------------------------------
    // IDLE:     Waiting for a new CPU request
    // LOOKUP:   Evaluating valid bit and tag match
    // MEM_REQ:  Asserting memory request for a cache line refill word
    // MEM_WAIT: Waiting for memory to return the refill word
    // RESP:     Holding response data and valid stable until accepted by CPU
    typedef enum logic [2:0] {
        IDLE     = 3'b000,
        LOOKUP   = 3'b001,
        MEM_REQ  = 3'b010,
        MEM_WAIT = 3'b011,
        RESP     = 3'b100
    } cache_state_e;

endpackage : cache_pkg

`endif // CACHE_PKG_SV
