// ============================================================================
// File: sim/simple_main_memory.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 4 Responsibility: Simulation Main Memory Model
//
// Description:
//   Simulation-only deterministic main memory model representing a 4 KB
//   (1024 words x 32 bits) address space from 0x00000000 to 0x00000FFF.
//
// Memory Initialization:
//   For index i from 0 to 1023:
//     memory[i] = 32'hA5000000 ^ i;
//
// Address Mapping:
//   - Word Index: mem_req_addr[11:2] (10 bits, 0 to 1023)
//   - Byte Offset: mem_req_addr[1:0] (must be 2'b00 for word alignment)
//   - Address Range: 0x00000000 to 0x00000FFF (mem_req_addr[31:12] must be 0)
//
// Handshake & Protocol:
//   - Ready/Valid handshake for requests and responses.
//   - Handshake transfer occurs on posedge clk when valid && ready.
//   - Configurable latency (default LATENCY_CYCLES = 2).
//   - Configurable request gap (default REQUEST_GAP_CYCLES = 1) forcing
//     mem_req_ready stalls between refill words.
//   - Response data and valid are held strictly stable until accepted.
//   - Only one outstanding request at a time (blocking).
// ============================================================================

`ifndef SIMPLE_MAIN_MEMORY_SV
`define SIMPLE_MAIN_MEMORY_SV

`timescale 1ns / 1ps

module simple_main_memory #(
    parameter int LATENCY_CYCLES     = 2, // Response delay in clock cycles (>= 1)
    parameter int REQUEST_GAP_CYCLES = 1  // Inactive cycles before accepting next req
) (
    input  logic        clk,
    input  logic        rst_n,

    // Memory Request Interface
    input  logic        mem_req_valid,
    output logic        mem_req_ready,
    input  logic [31:0] mem_req_addr,

    // Memory Response Interface
    output logic        mem_resp_valid,
    input  logic        mem_resp_ready,
    output logic [31:0] mem_resp_data
);

    // ------------------------------------------------------------------------
    // Memory Storage Array (1024 words of 32 bits)
    // ------------------------------------------------------------------------
    logic [31:0] memory [0:1023];

    // Safe error return data for unaligned or out-of-range accesses
    localparam logic [31:0] ERROR_DATA = 32'hDEAD_BEEF;

    // ------------------------------------------------------------------------
    // Deterministic Memory Initialization
    // ------------------------------------------------------------------------
    initial begin
        for (int i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'hA5000000 ^ i;
        end
    end

    // ------------------------------------------------------------------------
    // State Machine States
    // ------------------------------------------------------------------------
    typedef enum logic [1:0] {
        MEM_IDLE     = 2'b00, // Ready to accept a new read request
        MEM_DELAY    = 2'b01, // Simulating access latency cycles
        MEM_RESPONSE = 2'b10, // Driving response data; waiting for cache ready
        MEM_GAP      = 2'b11  // Request gap forcing mem_req_ready stall
    } mem_state_e;

    mem_state_e state_q, state_d;

    // Latched request and response registers
    logic [31:0] latched_addr_q;
    logic [31:0] resp_data_q;
    logic [31:0] delay_cnt_q;
    logic [31:0] gap_cnt_q;

    // Handshake strobes
    wire req_fire  = mem_req_valid  && mem_req_ready;
    wire resp_fire = mem_resp_valid && mem_resp_ready;

    // ------------------------------------------------------------------------
    // Combinational Next-State and Output Logic
    // ------------------------------------------------------------------------
    always_comb begin
        state_d        = state_q;
        mem_req_ready  = 1'b0;
        mem_resp_valid = 1'b0;
        mem_resp_data  = resp_data_q;

        case (state_q)
            MEM_IDLE: begin
                mem_req_ready = 1'b1;
                if (req_fire) begin
                    if (LATENCY_CYCLES <= 1) begin
                        state_d = MEM_RESPONSE;
                    end else begin
                        state_d = MEM_DELAY;
                    end
                end
            end

            MEM_DELAY: begin
                if (delay_cnt_q <= 1) begin
                    state_d = MEM_RESPONSE;
                end
            end

            MEM_RESPONSE: begin
                mem_resp_valid = 1'b1;
                if (resp_fire) begin
                    if (REQUEST_GAP_CYCLES > 0) begin
                        state_d = MEM_GAP;
                    end else begin
                        state_d = MEM_IDLE;
                    end
                end
            end

            MEM_GAP: begin
                if (gap_cnt_q <= 1) begin
                    state_d = MEM_IDLE;
                end
            end

            default: begin
                state_d = MEM_IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------------
    // Synchronous Updates (Memory Read, Counters, Latches)
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state_q        <= MEM_IDLE;
            latched_addr_q <= 32'h0;
            resp_data_q    <= 32'h0;
            delay_cnt_q    <= 32'h0;
            gap_cnt_q      <= 32'h0;
        end else begin
            state_q <= state_d;

            case (state_q)
                MEM_IDLE: begin
                    if (req_fire) begin
                        latched_addr_q <= mem_req_addr;

                        // Check alignment and 4KB range (0x00000000 - 0x00000FFF)
                        if ((mem_req_addr[1:0] == 2'b00) && (mem_req_addr[31:12] == 20'h00000)) begin
                            resp_data_q <= memory[mem_req_addr[11:2]];
                        end else begin
                            resp_data_q <= ERROR_DATA;
                            $display("[simple_main_memory] ERROR: Invalid access addr=0x%08h (aligned=%0d, in_range=%0d) at time %0t",
                                     mem_req_addr, (mem_req_addr[1:0] == 2'b00), (mem_req_addr[31:12] == 20'h00000), $time);
                        end

                        if (LATENCY_CYCLES > 1) begin
                            delay_cnt_q <= LATENCY_CYCLES - 1;
                        end
                    end
                end

                MEM_DELAY: begin
                    if (delay_cnt_q > 1) begin
                        delay_cnt_q <= delay_cnt_q - 1;
                    end
                end

                MEM_RESPONSE: begin
                    if (resp_fire) begin
                        if (REQUEST_GAP_CYCLES > 0) begin
                            gap_cnt_q <= REQUEST_GAP_CYCLES;
                        end
                    end
                end

                MEM_GAP: begin
                    if (gap_cnt_q > 1) begin
                        gap_cnt_q <= gap_cnt_q - 1;
                    end
                end

                default: ;
            endcase
        end
    end

endmodule : simple_main_memory

`endif // SIMPLE_MAIN_MEMORY_SV
