// ============================================================================
// File: tb/tb_cache_2way_smoke.sv
// Project: 2-Way Set-Associative Cache with LRU
// Member 3 Responsibility: Integration Smoke Test for the Two-Way Cache
//
// Description:
//   Self-checking testbench for `cache_2way_top` (controller + datapath +
//   LRU) plus a standalone `cache_2way_controller` for replacement checks.
//
//   - TEST 5:  Replacement priority (invalid ways first, then LRU victim)
//              and hit-way LRU update, on a standalone controller
//   - TEST 6:  Complete cold miss: 4 words fetched, tag/valid written,
//              requested word returned
//   - TEST 7:  Repeated address hits with no memory traffic
//   - TEST 8:  0x00 and 0x80 (same set, different tags) coexist in 2 ways
//   - TEST 9:  LRU eviction for A -> B -> A -> C -> A -> B
//   - TEST 10: Memory request/response stalls and CPU response backpressure,
//              directed and with a pseudo-random trace checked against a
//              reference model
//
//   Memory model: simulation-only, one outstanding request, word at byte
//   address `a` holds mem_value(a). Request/response delays are configurable.
//   Protocol monitors check handshake stability on every clock edge.
//   Any mismatch stops the simulation with $fatal.
// ============================================================================

`timescale 1ns / 1ps

module tb_cache_2way_smoke;

    // ------------------------------------------------------------------------
    // Clock and Reset
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Top-Level DUT Signals
    // ------------------------------------------------------------------------
    logic        cpu_req_valid;
    logic        cpu_req_ready;
    logic [31:0] cpu_req_addr;
    logic        cpu_resp_valid;
    logic        cpu_resp_ready;
    logic [31:0] cpu_resp_data;
    logic        mem_req_valid;
    logic        mem_req_ready;
    logic [31:0] mem_req_addr;
    logic        mem_resp_valid;
    logic        mem_resp_ready;
    logic [31:0] mem_resp_data;
    logic [31:0] hit_count;
    logic [31:0] miss_count;
    logic [31:0] mem_word_read_count;

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
    // Standalone Controller for TEST 5 (all inputs driven by the testbench)
    // ------------------------------------------------------------------------
    logic        ut_cpu_req_valid;
    logic        ut_cpu_req_ready;
    logic [31:0] ut_cpu_req_addr;
    logic        ut_cpu_resp_valid;
    logic        ut_cpu_resp_ready;
    logic [31:0] ut_cpu_resp_data;
    logic        ut_mem_req_valid;
    logic        ut_mem_req_ready;
    logic [31:0] ut_mem_req_addr;
    logic        ut_mem_resp_valid;
    logic        ut_mem_resp_ready;
    logic [31:0] ut_mem_resp_data;
    logic [1:0]  ut_dp_set_index;
    logic [25:0] ut_dp_request_tag;
    logic [1:0]  ut_dp_word_index;
    logic        ut_dp_hit0;
    logic        ut_dp_hit1;
    logic        ut_dp_valid0;
    logic        ut_dp_valid1;
    logic [31:0] ut_dp_selected_data;
    logic        ut_dp_fill_word_we;
    logic        ut_dp_fill_way;
    logic [1:0]  ut_dp_fill_word_index;
    logic [31:0] ut_dp_fill_word_data;
    logic        ut_dp_fill_meta_we;
    logic [25:0] ut_dp_fill_tag;
    logic [1:0]  ut_lru_set_index;
    logic        ut_lru_update_en;
    logic        ut_lru_accessed_way;
    logic        ut_lru_victim_way;
    logic [31:0] ut_hit_count;
    logic [31:0] ut_miss_count;
    logic [31:0] ut_mem_word_read_count;

    cache_2way_controller u_ctrl_unit (
        .clk                 (clk),
        .rst_n               (rst_n),
        .cpu_req_valid       (ut_cpu_req_valid),
        .cpu_req_ready       (ut_cpu_req_ready),
        .cpu_req_addr        (ut_cpu_req_addr),
        .cpu_resp_valid      (ut_cpu_resp_valid),
        .cpu_resp_ready      (ut_cpu_resp_ready),
        .cpu_resp_data       (ut_cpu_resp_data),
        .mem_req_valid       (ut_mem_req_valid),
        .mem_req_ready       (ut_mem_req_ready),
        .mem_req_addr        (ut_mem_req_addr),
        .mem_resp_valid      (ut_mem_resp_valid),
        .mem_resp_ready      (ut_mem_resp_ready),
        .mem_resp_data       (ut_mem_resp_data),
        .dp_set_index        (ut_dp_set_index),
        .dp_request_tag      (ut_dp_request_tag),
        .dp_word_index       (ut_dp_word_index),
        .dp_hit0             (ut_dp_hit0),
        .dp_hit1             (ut_dp_hit1),
        .dp_valid0           (ut_dp_valid0),
        .dp_valid1           (ut_dp_valid1),
        .dp_selected_data    (ut_dp_selected_data),
        .dp_fill_word_we     (ut_dp_fill_word_we),
        .dp_fill_way         (ut_dp_fill_way),
        .dp_fill_word_index  (ut_dp_fill_word_index),
        .dp_fill_word_data   (ut_dp_fill_word_data),
        .dp_fill_meta_we     (ut_dp_fill_meta_we),
        .dp_fill_tag         (ut_dp_fill_tag),
        .lru_set_index       (ut_lru_set_index),
        .lru_update_en       (ut_lru_update_en),
        .lru_accessed_way    (ut_lru_accessed_way),
        .lru_victim_way      (ut_lru_victim_way),
        .hit_count           (ut_hit_count),
        .miss_count          (ut_miss_count),
        .mem_word_read_count (ut_mem_word_read_count)
    );

    // ------------------------------------------------------------------------
    // Behavioral Memory Model (simulation only)
    // ------------------------------------------------------------------------
    // Deterministic contents: low half = address, high half = address ^ A5A5
    function automatic logic [31:0] mem_value(input logic [31:0] addr);
        return {addr[15:0] ^ 16'hA5A5, addr[15:0]};
    endfunction

    function automatic logic [31:0] xorshift32(input logic [31:0] x);
        logic [31:0] y;
        y = x ^ (x << 13);
        y = y ^ (y >> 17);
        y = y ^ (y << 5);
        return y;
    endfunction

    logic [3:0]  cfg_req_delay;     // cycles mem_req_ready stays low per request
    logic [3:0]  cfg_resp_delay;    // cycles before mem_resp_valid rises
    logic        cfg_random_delay;  // use per-request pseudo-random delays

    logic        mem_busy;          // a request was accepted, response pending
    logic [31:0] mem_pending_addr;
    logic [7:0]  mem_req_wait;
    logic [7:0]  mem_resp_wait;
    logic [31:0] mem_rng;
    logic [31:0] mem_rng_next;
    logic [3:0]  rnd_req_delay;
    logic [3:0]  rnd_resp_delay;
    logic [3:0]  eff_req_delay;
    logic [3:0]  eff_resp_delay;

    assign mem_rng_next   = xorshift32(mem_rng);
    assign eff_req_delay  = cfg_random_delay ? rnd_req_delay  : cfg_req_delay;
    assign eff_resp_delay = cfg_random_delay ? rnd_resp_delay : cfg_resp_delay;

    assign mem_req_ready  = !mem_busy && ({4'd0, eff_req_delay}  <= mem_req_wait);
    assign mem_resp_valid =  mem_busy && ({4'd0, eff_resp_delay} <= mem_resp_wait);
    // Garbage when not valid, so capturing an unaccepted word is detected
    assign mem_resp_data  = mem_resp_valid ? mem_value(mem_pending_addr) : 32'hBAD0_BAD0;

    always @(posedge clk) begin
        if (!rst_n) begin
            mem_busy         <= 1'b0;
            mem_pending_addr <= '0;
            mem_req_wait     <= '0;
            mem_resp_wait    <= '0;
            mem_rng          <= 32'h1357_9BDF;
            rnd_req_delay    <= 4'd0;
            rnd_resp_delay   <= 4'd0;
        end else if (!mem_busy) begin
            if (mem_req_valid && mem_req_ready) begin
                mem_busy         <= 1'b1;
                mem_pending_addr <= mem_req_addr;
                mem_req_wait     <= '0;
                mem_resp_wait    <= '0;
            end else if (mem_req_valid) begin
                mem_req_wait <= mem_req_wait + 1'b1;
            end
        end else begin
            if (mem_req_valid) begin
                $fatal(1, "[FAIL] mem_req_valid asserted while a memory response is outstanding");
            end
            if (mem_resp_valid && mem_resp_ready) begin
                mem_busy       <= 1'b0;
                mem_rng        <= mem_rng_next;
                rnd_req_delay  <= {2'b00, mem_rng_next[1:0]};
                rnd_resp_delay <= {1'b0,  mem_rng_next[6:4]};
            end else if (!mem_resp_valid) begin
                mem_resp_wait <= mem_resp_wait + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Protocol Monitors and Transaction Logs
    // ------------------------------------------------------------------------
    int unsigned cpu_req_accepts;
    int unsigned cpu_resp_accepts;
    int unsigned mem_req_accepts;
    int unsigned mem_resp_accepts;
    int unsigned fill_writes;
    int unsigned meta_writes;
    int unsigned mem_req_stall_cycles;   // mem_req_valid && !mem_req_ready
    int unsigned mem_resp_stall_cycles;  // mem_resp_ready && !mem_resp_valid
    int unsigned cpu_resp_stall_cycles;  // cpu_resp_valid && !cpu_resp_ready

    // Per-transaction logs, cleared by cpu_read()
    logic [31:0] mem_addr_log  [$];
    logic [1:0]  fill_idx_log  [$];
    logic        fill_way_log  [$];
    logic        fill_meta_log [$];

    logic        mem_req_pending_q;
    logic [31:0] mem_req_addr_q;
    logic        cpu_resp_pending_q;
    logic [31:0] cpu_resp_data_q;

    always @(posedge clk) begin
        if (!rst_n) begin
            cpu_req_accepts       = 0;
            cpu_resp_accepts      = 0;
            mem_req_accepts       = 0;
            mem_resp_accepts      = 0;
            fill_writes           = 0;
            meta_writes           = 0;
            mem_req_stall_cycles  = 0;
            mem_resp_stall_cycles = 0;
            cpu_resp_stall_cycles = 0;
            mem_req_pending_q     <= 1'b0;
            cpu_resp_pending_q    <= 1'b0;
        end else begin
            // Stalled memory request must keep valid high and address stable
            if (mem_req_pending_q) begin
                if (!mem_req_valid) begin
                    $fatal(1, "[FAIL] mem_req_valid dropped before handshake");
                end
                if (mem_req_addr !== mem_req_addr_q) begin
                    $fatal(1, "[FAIL] mem_req_addr changed during stall: %h -> %h",
                           mem_req_addr_q, mem_req_addr);
                end
            end
            mem_req_pending_q <= mem_req_valid && !mem_req_ready;
            mem_req_addr_q    <= mem_req_addr;

            // Stalled CPU response must keep valid high and data stable
            if (cpu_resp_pending_q) begin
                if (!cpu_resp_valid) begin
                    $fatal(1, "[FAIL] cpu_resp_valid dropped before handshake");
                end
                if (cpu_resp_data !== cpu_resp_data_q) begin
                    $fatal(1, "[FAIL] cpu_resp_data changed during stall: %h -> %h",
                           cpu_resp_data_q, cpu_resp_data);
                end
            end
            cpu_resp_pending_q <= cpu_resp_valid && !cpu_resp_ready;
            cpu_resp_data_q    <= cpu_resp_data;

            // Stall statistics (proves the stall paths were exercised)
            if (mem_req_valid  && !mem_req_ready)  mem_req_stall_cycles++;
            if (mem_resp_ready && !mem_resp_valid) mem_resp_stall_cycles++;
            if (cpu_resp_valid && !cpu_resp_ready) cpu_resp_stall_cycles++;

            // Only one outstanding CPU request at a time
            if (cpu_req_valid && cpu_req_ready) begin
                if (cpu_req_accepts != cpu_resp_accepts) begin
                    $fatal(1, "[FAIL] new CPU request accepted while one is outstanding");
                end
                cpu_req_accepts++;
            end
            if (cpu_resp_valid && cpu_resp_ready) begin
                if (cpu_resp_accepts >= cpu_req_accepts) begin
                    $fatal(1, "[FAIL] CPU response without a matching request");
                end
                cpu_resp_accepts++;
            end

            if (mem_req_valid && mem_req_ready) begin
                mem_req_accepts++;
                mem_addr_log.push_back(mem_req_addr);
            end

            // Every accepted memory word must be written exactly once
            if (mem_resp_valid && mem_resp_ready) begin
                mem_resp_accepts++;
                if (!dut.dp_fill_word_we) begin
                    $fatal(1, "[FAIL] accepted memory word was not written to the datapath");
                end
            end

            if (dut.dp_fill_word_we) begin
                if (!(mem_resp_valid && mem_resp_ready)) begin
                    $fatal(1, "[FAIL] datapath write without an accepted memory response");
                end
                if (dut.dp_fill_word_index !== mem_pending_addr[3:2]) begin
                    $fatal(1, "[FAIL] fill word index %0d does not match memory address %h",
                           dut.dp_fill_word_index, mem_pending_addr);
                end
                if (dut.dp_fill_word_data !== mem_value(mem_pending_addr)) begin
                    $fatal(1, "[FAIL] fill data %h, expected %h",
                           dut.dp_fill_word_data, mem_value(mem_pending_addr));
                end
                fill_writes++;
                fill_idx_log.push_back(dut.dp_fill_word_index);
                fill_way_log.push_back(dut.dp_fill_way);
                fill_meta_log.push_back(dut.dp_fill_meta_we);
            end

            if (dut.dp_fill_meta_we) begin
                if (!(dut.dp_fill_word_we && dut.dp_fill_word_index == 2'd3)) begin
                    $fatal(1, "[FAIL] tag/valid committed before the fourth refill word");
                end
                if (dut.dp_fill_tag !== mem_pending_addr[31:6]) begin
                    $fatal(1, "[FAIL] committed tag %h, expected %h",
                           dut.dp_fill_tag, mem_pending_addr[31:6]);
                end
                meta_writes++;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Helper Tasks: Reset and Datapath / LRU State Checks
    // ------------------------------------------------------------------------
    task automatic apply_reset();
        @(negedge clk);
        rst_n             = 1'b0;
        cpu_req_valid     = 1'b0;
        cpu_req_addr      = '0;
        cpu_resp_ready    = 1'b0;
        ut_cpu_req_valid  = 1'b0;
        ut_cpu_req_addr   = '0;
        ut_cpu_resp_ready = 1'b1;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
    endtask

    task automatic check_way(input logic [1:0] set_i, input logic way_i,
                             input logic exp_valid, input logic [25:0] exp_tag,
                             input string context_msg);
        logic        act_valid;
        logic [25:0] act_tag;
        if (way_i == 1'b0) begin
            act_valid = dut.u_datapath.way0_valid[set_i];
            act_tag   = dut.u_datapath.way0_tag[set_i];
        end else begin
            act_valid = dut.u_datapath.way1_valid[set_i];
            act_tag   = dut.u_datapath.way1_tag[set_i];
        end
        if (act_valid !== exp_valid) begin
            $fatal(1, "[FAIL] %s: set %0d way %0d valid = %b, expected %b",
                   context_msg, set_i, way_i, act_valid, exp_valid);
        end
        if (exp_valid && act_tag !== exp_tag) begin
            $fatal(1, "[FAIL] %s: set %0d way %0d tag = %h, expected %h",
                   context_msg, set_i, way_i, act_tag, exp_tag);
        end
    endtask

    task automatic check_line_data(input logic [1:0] set_i, input logic way_i,
                                   input logic [31:0] line_base,
                                   input string context_msg);
        logic [31:0] act_word;
        for (int w = 0; w < 4; w++) begin
            if (way_i == 1'b0) act_word = dut.u_datapath.way0_data[set_i][w];
            else               act_word = dut.u_datapath.way1_data[set_i][w];
            if (act_word !== mem_value(line_base + 32'(w * 4))) begin
                $fatal(1, "[FAIL] %s: set %0d way %0d word %0d = %h, expected %h",
                       context_msg, set_i, way_i, w, act_word,
                       mem_value(line_base + 32'(w * 4)));
            end
        end
    endtask

    task automatic check_lru(input logic [1:0] set_i, input logic exp_victim,
                             input string context_msg);
        if (dut.u_lru.lru_bits[set_i] !== exp_victim) begin
            $fatal(1, "[FAIL] %s: set %0d LRU bit = %b, expected %b",
                   context_msg, set_i, dut.u_lru.lru_bits[set_i], exp_victim);
        end
    endtask

    task automatic check_counters(input logic [31:0] exp_hits, input logic [31:0] exp_misses,
                                  input logic [31:0] exp_mem, input string context_msg);
        if (hit_count !== exp_hits || miss_count !== exp_misses ||
            mem_word_read_count !== exp_mem) begin
            $fatal(1, "[FAIL] %s: counters hit/miss/mem = %0d/%0d/%0d, expected %0d/%0d/%0d",
                   context_msg, hit_count, miss_count, mem_word_read_count,
                   exp_hits, exp_misses, exp_mem);
        end
    endtask

    // ------------------------------------------------------------------------
    // CPU Read Transaction (top-level DUT)
    // ------------------------------------------------------------------------
    // Issues one read, waits `resp_delay` cycles with cpu_resp_ready low while
    // checking the response stays stable, then accepts it. Checks the data,
    // the hit/miss counters, and for a miss the full 4-word refill sequence.
    logic last_fill_way;

    task automatic cpu_read(input logic [31:0] addr, input logic expect_hit,
                            input int resp_delay, input string context_msg);
        logic [31:0] hits_before;
        logic [31:0] misses_before;
        logic [31:0] mem_before;
        logic [31:0] first_data;
        logic [31:0] line_base;
        int          waited;

        hits_before   = hit_count;
        misses_before = miss_count;
        mem_before    = mem_word_read_count;
        line_base     = {addr[31:4], 4'b0000};
        mem_addr_log.delete();
        fill_idx_log.delete();
        fill_way_log.delete();
        fill_meta_log.delete();

        // Request phase: hold valid until the cache is ready
        @(negedge clk);
        cpu_req_valid = 1'b1;
        cpu_req_addr  = addr;
        waited = 0;
        while (!cpu_req_ready) begin
            @(negedge clk);
            if (++waited > 1000) $fatal(1, "[FAIL] %s: cpu_req_ready timeout", context_msg);
        end
        @(negedge clk); // the rising edge in between accepted the request
        cpu_req_valid = 1'b0;
        cpu_req_addr  = 32'hFFFF_FFF0; // must not be used after the handshake

        // Response phase
        waited = 0;
        while (!cpu_resp_valid) begin
            @(negedge clk);
            if (++waited > 1000) $fatal(1, "[FAIL] %s: cpu_resp_valid timeout", context_msg);
        end
        first_data = cpu_resp_data;
        repeat (resp_delay) begin
            @(negedge clk);
            if (!cpu_resp_valid || cpu_resp_data !== first_data) begin
                $fatal(1, "[FAIL] %s: response not held stable under backpressure",
                       context_msg);
            end
        end
        cpu_resp_ready = 1'b1;
        @(negedge clk);
        cpu_resp_ready = 1'b0;
        if (cpu_resp_valid) begin
            $fatal(1, "[FAIL] %s: response still valid after handshake (duplicate)",
                   context_msg);
        end

        // Data check
        if (first_data !== mem_value(addr)) begin
            $fatal(1, "[FAIL] %s: read %h returned %h, expected %h",
                   context_msg, addr, first_data, mem_value(addr));
        end

        // Hit / miss check
        if (expect_hit) begin
            if (hit_count !== hits_before + 1 || miss_count !== misses_before ||
                mem_word_read_count !== mem_before || mem_addr_log.size() != 0 ||
                fill_idx_log.size() != 0) begin
                $fatal(1, "[FAIL] %s: read %h expected HIT (hit +%0d, miss +%0d, mem +%0d)",
                       context_msg, addr, hit_count - hits_before,
                       miss_count - misses_before, mem_word_read_count - mem_before);
            end
        end else begin
            if (miss_count !== misses_before + 1 || hit_count !== hits_before ||
                mem_word_read_count !== mem_before + 4) begin
                $fatal(1, "[FAIL] %s: read %h expected MISS (hit +%0d, miss +%0d, mem +%0d)",
                       context_msg, addr, hit_count - hits_before,
                       miss_count - misses_before, mem_word_read_count - mem_before);
            end
            if (mem_addr_log.size() != 4 || fill_idx_log.size() != 4) begin
                $fatal(1, "[FAIL] %s: %0d memory requests / %0d fill writes, expected 4 / 4",
                       context_msg, mem_addr_log.size(), fill_idx_log.size());
            end
            for (int w = 0; w < 4; w++) begin
                if (mem_addr_log[w] !== line_base + 32'(w * 4)) begin
                    $fatal(1, "[FAIL] %s: memory request %0d address %h, expected %h",
                           context_msg, w, mem_addr_log[w], line_base + 32'(w * 4));
                end
                if (fill_idx_log[w] !== w[1:0] || fill_way_log[w] !== fill_way_log[0]) begin
                    $fatal(1, "[FAIL] %s: fill write %0d went to way %0d word %0d",
                           context_msg, w, fill_way_log[w], fill_idx_log[w]);
                end
                if (fill_meta_log[w] !== (w == 3)) begin
                    $fatal(1, "[FAIL] %s: fill_meta_we = %b on refill word %0d",
                           context_msg, fill_meta_log[w], w);
                end
            end
            last_fill_way = fill_way_log[0];
        end
    endtask

    // ------------------------------------------------------------------------
    // Standalone Controller Transactions (TEST 5)
    // ------------------------------------------------------------------------
    // Miss with the given valid bits and LRU victim. After LOOKUP the inputs
    // are changed to point at the other way, proving the choice is latched.
    task automatic unit_miss(input logic v0, input logic v1, input logic victim,
                             input logic exp_way, input string context_msg);
        int fills;
        int waited;

        @(negedge clk);
        if (!ut_cpu_req_ready) $fatal(1, "[FAIL] %s: controller not idle", context_msg);
        ut_dp_hit0        = 1'b0;
        ut_dp_hit1        = 1'b0;
        ut_dp_valid0      = v0;
        ut_dp_valid1      = v1;
        ut_lru_victim_way = victim;
        ut_cpu_req_valid  = 1'b1;
        ut_cpu_req_addr   = 32'h0000_0124;

        @(negedge clk); // LOOKUP
        ut_cpu_req_valid = 1'b0;
        if (ut_lru_update_en || ut_mem_req_valid || ut_dp_fill_word_we) begin
            $fatal(1, "[FAIL] %s: unexpected LRU/memory/fill activity in LOOKUP on a miss",
                   context_msg);
        end

        @(negedge clk); // MEM_REQ for word 0
        if (!ut_mem_req_valid) $fatal(1, "[FAIL] %s: no memory request after miss", context_msg);
        ut_dp_valid0      = 1'b1;
        ut_dp_valid1      = 1'b1;
        ut_lru_victim_way = ~exp_way;

        fills  = 0;
        waited = 0;
        while (!ut_cpu_resp_valid) begin
            if (ut_dp_fill_word_we) begin
                fills++;
                if (ut_dp_fill_way !== exp_way) begin
                    $fatal(1, "[FAIL] %s: filled way %0d, expected way %0d",
                           context_msg, ut_dp_fill_way, exp_way);
                end
                if (ut_dp_fill_meta_we !== (fills == 4)) begin
                    $fatal(1, "[FAIL] %s: fill_meta_we = %b on fill word %0d",
                           context_msg, ut_dp_fill_meta_we, fills);
                end
                if (ut_lru_update_en !== (fills == 4) ||
                    (fills == 4 && ut_lru_accessed_way !== exp_way)) begin
                    $fatal(1, "[FAIL] %s: LRU update_en=%b accessed_way=%b on fill word %0d",
                           context_msg, ut_lru_update_en, ut_lru_accessed_way, fills);
                end
            end else if (ut_lru_update_en) begin
                $fatal(1, "[FAIL] %s: LRU updated outside the final refill word", context_msg);
            end
            @(negedge clk);
            if (++waited > 100) $fatal(1, "[FAIL] %s: refill timeout", context_msg);
        end
        if (fills != 4) $fatal(1, "[FAIL] %s: %0d fill writes, expected 4", context_msg, fills);
        @(negedge clk); // RESP accepted (ut_cpu_resp_ready = 1)
    endtask

    // Hit with the given hit flags: checks the LRU update and returned data
    task automatic unit_hit(input logic h0, input logic h1, input logic exp_way,
                            input string context_msg);
        @(negedge clk);
        if (!ut_cpu_req_ready) $fatal(1, "[FAIL] %s: controller not idle", context_msg);
        ut_dp_hit0          = h0;
        ut_dp_hit1          = h1;
        ut_dp_valid0        = 1'b1;
        ut_dp_valid1        = 1'b1;
        ut_dp_selected_data = 32'h1234_ABCD;
        ut_cpu_req_valid    = 1'b1;
        ut_cpu_req_addr     = 32'h0000_0124;

        @(negedge clk); // LOOKUP
        ut_cpu_req_valid = 1'b0;
        if (!ut_lru_update_en || ut_lru_accessed_way !== exp_way) begin
            $fatal(1, "[FAIL] %s: LRU update_en=%b accessed_way=%b, expected 1/%b",
                   context_msg, ut_lru_update_en, ut_lru_accessed_way, exp_way);
        end
        if (ut_mem_req_valid) $fatal(1, "[FAIL] %s: memory request on a hit", context_msg);

        @(negedge clk); // RESP
        if (!ut_cpu_resp_valid || ut_cpu_resp_data !== 32'h1234_ABCD) begin
            $fatal(1, "[FAIL] %s: hit response valid=%b data=%h",
                   context_msg, ut_cpu_resp_valid, ut_cpu_resp_data);
        end
        if (ut_lru_update_en) $fatal(1, "[FAIL] %s: LRU updated twice for one hit", context_msg);
        ut_dp_hit0 = 1'b0;
        ut_dp_hit1 = 1'b0;
        @(negedge clk); // response accepted
    endtask

    // ------------------------------------------------------------------------
    // Reference Model for the Random Trace (TEST 10)
    // ------------------------------------------------------------------------
    logic        ref_valid [0:3][0:1];
    logic [25:0] ref_tag   [0:3][0:1];
    logic        ref_lru   [0:3];

    task automatic ref_reset();
        for (int s = 0; s < 4; s++) begin
            ref_valid[s][0] = 1'b0;
            ref_valid[s][1] = 1'b0;
            ref_tag[s][0]   = '0;
            ref_tag[s][1]   = '0;
            ref_lru[s]      = 1'b0;
        end
    endtask

    task automatic ref_access(input logic [31:0] addr, output logic hit, output logic way);
        logic [1:0]  s;
        logic [25:0] t;
        s = addr[5:4];
        t = addr[31:6];
        if (ref_valid[s][0] && ref_tag[s][0] == t) begin
            hit = 1'b1;
            way = 1'b0;
        end else if (ref_valid[s][1] && ref_tag[s][1] == t) begin
            hit = 1'b1;
            way = 1'b1;
        end else begin
            hit = 1'b0;
            if (!ref_valid[s][0])      way = 1'b0;
            else if (!ref_valid[s][1]) way = 1'b1;
            else                       way = ref_lru[s];
            ref_valid[s][way] = 1'b1;
            ref_tag[s][way]   = t;
        end
        ref_lru[s] = ~way;
    endtask

    // ------------------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------------------
    localparam logic [31:0] ADDR_A = 32'h0000_0000;
    localparam logic [31:0] ADDR_B = 32'h0000_0080;
    localparam logic [31:0] ADDR_C = 32'h0000_0100;

    logic [31:0] rng;
    logic        exp_hit;
    logic        exp_way;
    int          n_access;

    initial begin
        $display("==========================================================");
        $display(" tb_cache_2way_smoke: two-way cache integration test");
        $display("==========================================================");

        cfg_req_delay       = 4'd0;
        cfg_resp_delay      = 4'd0;
        cfg_random_delay    = 1'b0;
        ut_mem_req_ready    = 1'b1;
        ut_mem_resp_valid   = 1'b1;
        ut_mem_resp_data    = 32'hCAFE_0000;
        ut_dp_hit0          = 1'b0;
        ut_dp_hit1          = 1'b0;
        ut_dp_valid0        = 1'b0;
        ut_dp_valid1        = 1'b0;
        ut_dp_selected_data = '0;
        ut_lru_victim_way   = 1'b0;
        apply_reset();

        // --------------------------------------------------------------------
        // TEST 5: Invalid-Way Priority and LRU Victim Selection
        // --------------------------------------------------------------------
        unit_miss(1'b0, 1'b0, 1'b1, 1'b0, "TEST 5 both invalid");
        unit_miss(1'b1, 1'b0, 1'b0, 1'b1, "TEST 5 way0 valid, way1 invalid");
        unit_miss(1'b0, 1'b1, 1'b1, 1'b0, "TEST 5 way0 invalid, way1 valid");
        unit_miss(1'b1, 1'b1, 1'b0, 1'b0, "TEST 5 both valid, LRU victim 0");
        unit_miss(1'b1, 1'b1, 1'b1, 1'b1, "TEST 5 both valid, LRU victim 1");
        unit_hit (1'b1, 1'b0, 1'b0,       "TEST 5 hit way 0");
        unit_hit (1'b0, 1'b1, 1'b1,       "TEST 5 hit way 1");
        unit_hit (1'b1, 1'b1, 1'b0,       "TEST 5 both hit -> way 0 priority");
        if (ut_hit_count !== 3 || ut_miss_count !== 5 || ut_mem_word_read_count !== 20) begin
            $fatal(1, "[FAIL] TEST 5 counters hit/miss/mem = %0d/%0d/%0d, expected 3/5/20",
                   ut_hit_count, ut_miss_count, ut_mem_word_read_count);
        end
        $display("[PASS] TEST 5: Invalid way chosen before LRU victim; hit way updates LRU");
        $display("               (both invalid->W0, W0 valid->W1, W1 valid->W0, LRU 0->W0, LRU 1->W1)");

        // --------------------------------------------------------------------
        // TEST 6: Complete Cache Miss
        // --------------------------------------------------------------------
        // 0x1238: tag 0x48, set 3, word 2
        apply_reset();
        check_way(2'd3, 1'b0, 1'b0, '0, "TEST 6 before miss");
        check_way(2'd3, 1'b1, 1'b0, '0, "TEST 6 before miss");
        cpu_read(32'h0000_1238, 1'b0, 0, "TEST 6 cold miss");
        $display("        memory requests: %h %h %h %h",
                 mem_addr_log[0], mem_addr_log[1], mem_addr_log[2], mem_addr_log[3]);
        if (last_fill_way !== 1'b0) $fatal(1, "[FAIL] TEST 6: cold miss did not fill Way 0");
        check_way(2'd3, 1'b0, 1'b1, 26'h48, "TEST 6 after miss");
        check_way(2'd3, 1'b1, 1'b0, '0,     "TEST 6 after miss");
        check_line_data(2'd3, 1'b0, 32'h0000_1230, "TEST 6 after miss");
        check_lru(2'd3, 1'b1, "TEST 6 after miss");
        check_counters(0, 1, 4, "TEST 6");
        $display("[PASS] TEST 6: Miss on 0x00001238 fetched 4 words, tag 0x48 valid in set 3 way 0,");
        $display("               returned %h", mem_value(32'h0000_1238));

        // --------------------------------------------------------------------
        // TEST 7: Cache Hit
        // --------------------------------------------------------------------
        cpu_read(32'h0000_1238, 1'b1, 0, "TEST 7 repeat");
        cpu_read(32'h0000_1230, 1'b1, 0, "TEST 7 word 0 of same line");
        cpu_read(32'h0000_123C, 1'b1, 0, "TEST 7 word 3 of same line");
        check_counters(3, 1, 4, "TEST 7");
        $display("[PASS] TEST 7: Repeat and same-line reads hit with no extra memory reads");

        // --------------------------------------------------------------------
        // TEST 8: Two-Way Conflict (same set, different tags)
        // --------------------------------------------------------------------
        apply_reset();
        cpu_read(ADDR_A, 1'b0, 0, "TEST 8 A");
        if (last_fill_way !== 1'b0) $fatal(1, "[FAIL] TEST 8: A not placed in Way 0");
        cpu_read(ADDR_B, 1'b0, 0, "TEST 8 B");
        if (last_fill_way !== 1'b1) $fatal(1, "[FAIL] TEST 8: B not placed in Way 1");
        check_way(2'd0, 1'b0, 1'b1, ADDR_A[31:6], "TEST 8");
        check_way(2'd0, 1'b1, 1'b1, ADDR_B[31:6], "TEST 8");
        cpu_read(ADDR_A, 1'b1, 0, "TEST 8 A again");
        cpu_read(ADDR_B, 1'b1, 0, "TEST 8 B again");
        cpu_read(ADDR_A, 1'b1, 0, "TEST 8 A third");
        check_counters(3, 2, 8, "TEST 8");
        $display("[PASS] TEST 8: 0x00000000 (Way 0) and 0x00000080 (Way 1) coexist in set 0");

        // --------------------------------------------------------------------
        // TEST 9: LRU Eviction  A -> B -> A -> C -> A -> B
        // --------------------------------------------------------------------
        apply_reset();
        cpu_read(ADDR_A, 1'b0, 0, "TEST 9 A (1)");
        check_lru(2'd0, 1'b1, "TEST 9 after A");
        cpu_read(ADDR_B, 1'b0, 0, "TEST 9 B (2)");
        check_lru(2'd0, 1'b0, "TEST 9 after B");
        cpu_read(ADDR_A, 1'b1, 0, "TEST 9 A (3)");
        check_lru(2'd0, 1'b1, "TEST 9 after A hit");
        cpu_read(ADDR_C, 1'b0, 0, "TEST 9 C (4)");
        if (last_fill_way !== 1'b1) $fatal(1, "[FAIL] TEST 9: C did not replace Way 1 (B)");
        check_way(2'd0, 1'b0, 1'b1, ADDR_A[31:6], "TEST 9 after C");
        check_way(2'd0, 1'b1, 1'b1, ADDR_C[31:6], "TEST 9 after C");
        check_line_data(2'd0, 1'b1, ADDR_C, "TEST 9 after C");
        check_lru(2'd0, 1'b0, "TEST 9 after C");
        cpu_read(ADDR_A, 1'b1, 0, "TEST 9 A (5)");
        cpu_read(ADDR_B, 1'b0, 0, "TEST 9 B (6)");
        if (last_fill_way !== 1'b1) $fatal(1, "[FAIL] TEST 9: B did not replace Way 1 (C)");
        check_way(2'd0, 1'b0, 1'b1, ADDR_A[31:6], "TEST 9 final");
        check_way(2'd0, 1'b1, 1'b1, ADDR_B[31:6], "TEST 9 final");
        check_counters(2, 4, 16, "TEST 9");
        $display("[PASS] TEST 9: A,B,A,C,A,B = M,M,H,M,H,M; C evicted B, A stayed, final B missed");

        // --------------------------------------------------------------------
        // TEST 10a: Directed Memory Stalls and CPU Backpressure
        // --------------------------------------------------------------------
        apply_reset();
        cfg_req_delay  = 4'd3;
        cfg_resp_delay = 4'd5;
        cpu_read(32'h0000_200C, 1'b0, 4, "TEST 10a miss word 3");
        cpu_read(32'h0000_200C, 1'b1, 6, "TEST 10a hit word 3");
        cpu_read(32'h0000_2040, 1'b0, 3, "TEST 10a miss word 0 same set");
        cpu_read(32'h0000_2004, 1'b1, 2, "TEST 10a hit word 1");
        cpu_read(32'h0000_2048, 1'b1, 5, "TEST 10a hit word 2");
        cpu_read(32'h0000_2080, 1'b0, 1, "TEST 10a miss evicts LRU");
        check_counters(3, 3, 12, "TEST 10a");
        if (mem_req_stall_cycles == 0 || mem_resp_stall_cycles == 0 ||
            cpu_resp_stall_cycles == 0) begin
            $fatal(1, "[FAIL] TEST 10a: stall paths not exercised (%0d/%0d/%0d)",
                   mem_req_stall_cycles, mem_resp_stall_cycles, cpu_resp_stall_cycles);
        end
        $display("[PASS] TEST 10a: Stalls held stable (mem_req stall %0d, mem_resp wait %0d, cpu_resp stall %0d cycles)",
                 mem_req_stall_cycles, mem_resp_stall_cycles, cpu_resp_stall_cycles);

        // --------------------------------------------------------------------
        // TEST 10b: Pseudo-Random Trace with Random Stalls vs Reference Model
        // --------------------------------------------------------------------
        apply_reset();
        ref_reset();
        cfg_random_delay = 1'b1;
        rng      = 32'hC0FF_EE11;
        n_access = 400;
        for (int i = 0; i < n_access; i++) begin
            logic [31:0] addr;
            rng  = xorshift32(rng);
            // 24 distinct lines (6 tags per set) x 4 words
            addr = ((rng[15:0] % 24) << 4) | {28'd0, rng[17:16], 2'b00};
            ref_access(addr, exp_hit, exp_way);
            cpu_read(addr, exp_hit, int'(rng[21:20]), "TEST 10b random trace");
            if (!exp_hit && last_fill_way !== exp_way) begin
                $fatal(1, "[FAIL] TEST 10b access %0d addr %h filled way %0d, reference way %0d",
                       i, addr, last_fill_way, exp_way);
            end
        end
        for (int s = 0; s < 4; s++) begin
            check_way(s[1:0], 1'b0, ref_valid[s][0], ref_tag[s][0], "TEST 10b final state");
            check_way(s[1:0], 1'b1, ref_valid[s][1], ref_tag[s][1], "TEST 10b final state");
            check_lru(s[1:0], ref_lru[s], "TEST 10b final state");
        end
        if (hit_count + miss_count != n_access ||
            mem_word_read_count != 4 * miss_count ||
            cpu_req_accepts != n_access || cpu_resp_accepts != n_access ||
            mem_req_accepts != mem_word_read_count ||
            mem_resp_accepts != mem_req_accepts ||
            fill_writes != mem_resp_accepts || meta_writes != miss_count) begin
            $fatal(1, "[FAIL] TEST 10b bookkeeping mismatch: hits %0d misses %0d memreads %0d cpu req/resp %0d/%0d mem req/resp %0d/%0d fills %0d meta %0d",
                   hit_count, miss_count, mem_word_read_count, cpu_req_accepts,
                   cpu_resp_accepts, mem_req_accepts, mem_resp_accepts, fill_writes,
                   meta_writes);
        end
        $display("[PASS] TEST 10b: %0d random reads with random stalls matched the reference model",
                 n_access);
        $display("               hits %0d, misses %0d, memory word reads %0d (= 4 x misses)",
                 hit_count, miss_count, mem_word_read_count);
        $display("               no lost/duplicated CPU or memory transfers");

        $display("==========================================================");
        $display(" tb_cache_2way_smoke: ALL TESTS PASSED");
        $display("==========================================================");
        $finish;
    end

    // ------------------------------------------------------------------------
    // Simulation Watchdog
    // ------------------------------------------------------------------------
    initial begin
        #5000000;
        $fatal(1, "[FAIL] tb_cache_2way_smoke watchdog timeout");
    end

endmodule : tb_cache_2way_smoke
