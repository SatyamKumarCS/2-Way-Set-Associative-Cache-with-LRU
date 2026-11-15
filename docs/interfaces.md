# Shared module interface contract

This document is the source of truth for module names, ports and handshake behaviour. All members must follow it. If a change is required, update this file first and tell the whole team before changing RTL.

## External CPU and memory interface

Both `direct_mapped_cache` and `cache_2way_top` should expose the same external ports:

| Port | Direction | Width | Meaning |
|---|---|---:|---|
| `clk` | input | 1 | Rising-edge clock |
| `rst_n` | input | 1 | Active-low synchronous reset (sampled on the rising clock edge) |
| `cpu_req_valid` | input | 1 | CPU request is present |
| `cpu_req_ready` | output | 1 | Cache can accept a CPU request |
| `cpu_req_addr` | input | 32 | Byte address; word aligned |
| `cpu_resp_valid` | output | 1 | CPU response is present |
| `cpu_resp_ready` | input | 1 | CPU accepts response |
| `cpu_resp_data` | output | 32 | Returned word |
| `mem_req_valid` | output | 1 | Cache presents a memory read request |
| `mem_req_ready` | input | 1 | Memory accepts request |
| `mem_req_addr` | output | 32 | Address of requested word |
| `mem_resp_valid` | input | 1 | Memory response is present |
| `mem_resp_ready` | output | 1 | Cache accepts memory response |
| `mem_resp_data` | input | 32 | Returned memory word |
| `hit_count` | output | 32 | Number of CPU requests that hit |
| `miss_count` | output | 32 | Number of CPU requests that missed |
| `mem_word_read_count` | output | 32 | Number of accepted memory word requests |

A transfer occurs at the rising clock edge when both `valid` and `ready` are high. A response producer must keep `valid` asserted and keep its payload stable until the receiver accepts it.

## Two-way datapath contract

Member 2's `cache_2way_datapath` module should use the following agreed ports:

```systemverilog
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
```

`set_index` selects the set for lookup and for writes. `fill_way=0` writes Way 0; `fill_way=1` writes Way 1. `fill_word_we` writes one data word. `fill_meta_we` writes the tag and sets that way's valid bit. The controller must only assert `fill_meta_we` after all four refill words have been accepted.

## LRU contract

Suggested module name: `lru_controller`.

Ports:

```systemverilog
module lru_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [1:0] set_index,
    input  logic       update_en,
    input  logic       accessed_way,
    output logic       victim_way
);
```

`victim_way` is the current replacement candidate for `set_index`. When `update_en` is asserted, `accessed_way` identifies the way just accessed or filled; update the stored LRU bit so the other way becomes the victim.

## Counter semantics

- Increment `hit_count` exactly once for each CPU request that hits.
- Increment `miss_count` exactly once for each CPU request that misses.
- Increment `mem_word_read_count` once for each memory request accepted (`mem_req_valid && mem_req_ready` on a rising edge).
- Refill words are not additional CPU hits or misses.

## Resolve these before integration

- Use active-low synchronous reset consistently in every module (`if (!rst_n)` inside the rising-edge clocked block).
- Agree on exact module port declarations and named-port instantiations.
- Agree on the CSV columns and file path between the testbench and Python script.
- Confirm the direct-mapped and two-way modules use identical CPU/memory handshake semantics.
