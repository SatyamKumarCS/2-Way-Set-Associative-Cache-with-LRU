# Final Integration and Validation Audit Report

**Project**: Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache  
**Authors**: Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, Lakshya Bapna  
**Affiliation**: Department of Computer Science and Artificial Intelligence, Newton School of Technology  
**Repository**: [https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git](https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git)  
**Course / Context**: Modern Computer Architecture (Phase I Evaluation)  
**Date**: November 16, 2026  
**Status**: Integrated, Fully Verified, All Tests Passed (0 Failures)  

---

## 1. Executive Summary

A full integration and validation audit of the shared multi-member repository was conducted. The collaborative team members' contributions were integrated, verified for port and protocol compatibility, compiled with Icarus Verilog, and validated through standalone unit testbenches, an integration smoke test, and a dual-cache comparative benchmarking harness.

### Key Milestones Verified:
1. **Zero Compilation Warnings or Errors**: All RTL modules compile cleanly with `iverilog -g2012 -Wall`.
2. **Zero Functional Violations**: All 11 datapath unit tests, all 6 LRU unit tests, all 7 direct-mapped tests, the 6-stage two-way smoke test (including 400 random accesses with random memory/CPU stalls), and all 4 comparison benchmarking scenarios passed with zero `$fatal` triggers and zero data mismatches.
3. **Data Integrity & Determinism**: All CPU read responses match the deterministic main memory reference model:
   $$\text{memory}[i] = 32'\text{hA5000000} \oplus i$$
4. **Architectural Invariants Strictly Preserved**: Across every scenario:
   $$\text{hits} + \text{misses} = \text{total CPU accesses}$$
   $$\text{mem\_word\_read\_count} = 4 \times \text{misses}$$
5. **Demonstrated Conflict Miss Elimination**: The 2-way set-associative cache eliminated thrashing under conflict-heavy access patterns, achieving a **75.00% hit rate** vs. **0.00%** for direct-mapped, reducing average CPU access latency by **64.3%** (from 17.50 to 6.25 cycles/access).

---

## 2. File and Architecture Audit

| File | Primary Owner / Member | Interface / Contract Status | Audit Findings |
|---|---|---|---|
| `rtl/cache_pkg.sv` | Chinmay Soni (Member 1) | Defines constants (`ADDR_WIDTH`, `DATA_WIDTH`, `DM_LINES`, `SA_SETS`, `SA_WAYS`, etc.) and `cache_state_e` | Clean. Includes `` `timescale 1ns / 1ps `` and preprocessor guards (`CACHE_PKG_SV`) to avoid duplicate package compilation. |
| `rtl/direct_mapped_cache.sv` | Chinmay Soni (Member 1) | 8-line baseline cache with 17 top-level ports matching `docs/interfaces.md` | Synthesizable RTL. Tag [31:7], Index [6:4], Word [3:2]. Sequential 4-word refill with atomic commit. Synchronous active-low reset. Zero latches. |
| `rtl/cache_2way_datapath.sv` | Lakshya Bapna (Member 2) | Datapath storage, dual tag comparators, word data mux | Matches `docs/interfaces.md` verbatim. Dual way arrays `way0_data`, `way1_data` ($4 \times 4 \times 32$-bit). Deterministic priority to Way 0 on simultaneous hit. |
| `rtl/lru_controller.sv` | Satyam Kumar (Member 3) | 1-bit per set LRU replacement tracking | Matches `docs/interfaces.md` verbatim. Synchronous active-low reset initializes all sets to victim Way 0. Updates on `update_en`. |
| `rtl/cache_2way_controller.sv` | Satyam Kumar (Member 3) | Two-way FSM controller, refill sequencer, counter logic | Drives datapath and LRU controller. Replacement policy prioritizes invalid ways before evicting valid ways. Holds response stable under backpressure. |
| `rtl/cache_2way_top.sv` | Satyam Kumar (Member 3) | Unified top-level 2-way cache | Instantiates controller, datapath, and LRU controller. Exposes exact 17 ports identical to direct-mapped cache. |
| `sim/simple_main_memory.sv` | Krishna Verma (Member 4) | Deterministic simulation RAM ($1024 \times 32$-bit words) | Parameterized latency (`LATENCY_CYCLES = 2`) and request stalls (`REQUEST_GAP_CYCLES = 1`). Verified aligned 4-word refill handshakes. |
| `tb/tb_direct_mapped.sv` | Chinmay Soni (Member 1) | Direct-mapped standalone unit testbench | Self-checking. Tests cold misses, temporal hits, spatial hits, conflict replacement, CPU backpressure, and counter arithmetic. |
| `tb/tb_cache_2way_datapath.sv` | Lakshya Bapna (Member 2) | Two-way datapath standalone unit testbench | Self-checking. 11 tests verifying reset, dual-way fills, parallel lookups, cross-set isolation, and tag mismatch rejection. |
| `tb/tb_lru_controller.sv` | Satyam Kumar (Member 3) | LRU controller standalone unit testbench | Self-checking. 6 tests verifying reset state, transitions on Way 0 and Way 1 access, and set isolation. |
| `tb/tb_cache_2way_smoke.sv` | Satyam Kumar / Krishna Verma | Two-way integration smoke testbench | Self-checking. Tests standalone controller replacement priority, top-level misses, hits, coexistence, LRU eviction, and 400 random accesses with random stalls. |
| `tb/tb_cache_comparison.sv` | Krishna Verma (Member 4) | Dual-cache comparison testbench | Runs identical ordered traces on separate, identically initialized memory instances. Exports metrics to `results/results.csv`. |
| `analysis/analyze_results.py` | Krishna Verma (Member 4) | CSV parsing, invariant checks, ASCII reporting, plot generation | Reads `results/results.csv`, validates invariant checks, formats terminal table, renders 3 high-resolution grouped bar charts with Matplotlib. |
| *Documentation & Trace Validation* | Akshit Vats (Member 5) | Cross-functional verification support & Phase I reporting | Supported benchmark validation, invariant consistency checking across CSV metrics, and academic documentation. *(Subject to team confirmation)* |

---

## 3. Verification and Simulation Execution Records

### Test Suite 1: Direct-Mapped Cache Unit Test (`tb/tb_direct_mapped.sv`)
- **Compilation Command**:
  ```bash
  iverilog -g2012 -Wall -I rtl -s tb_dm_test -o build/tb_direct_mapped.vvp \
    rtl/cache_pkg.sv rtl/direct_mapped_cache.sv tb/tb_direct_mapped.sv
  ```
  *Exit Code*: `0` (Zero compiler warnings).
- **Execution Command**:
  ```bash
  vvp build/tb_direct_mapped.vvp
  ```
  *Exit Code*: `0`.
- **Simulation Summary**:
  ```text
  [PASS] Reset behaviour verified: counters and valid bits initialized.
  [PASS] Test 1: Cold Misses Across Distinct Lines (0x00, 0x10, 0x20, 0x70)
  [PASS] Test 2: Repeated Access Hits (Temporal Locality)
  [PASS] Test 3: Four Word Positions (Spatial Locality)
  [PASS] Test 4: Conflict Replacement (0x00000000 vs 0x00000080)
  [PASS] Test 5: Delayed Memory Responses & Request Stalls
  [PASS] Test 6: CPU Backpressure & Response Stability
  [PASS] Test 7: Hardware Counter Precision (Mem reads = 28 == 4 * 7 misses)
  ALL TESTS PASSED PERFECTLY! (0 errors)
  ```

---

### Test Suite 2: Two-Way Datapath Unit Test (`tb/tb_cache_2way_datapath.sv`)
- **Compilation Command**:
  ```bash
  iverilog -g2012 -Wall -I rtl -s tb_cache_2way_datapath -o build/tb_cache_2way_datapath.vvp \
    rtl/cache_pkg.sv rtl/cache_2way_datapath.sv tb/tb_cache_2way_datapath.sv
  ```
  *Exit Code*: `0` (Zero compiler warnings).
- **Execution Command**:
  ```bash
  vvp build/tb_cache_2way_datapath.vvp
  ```
  *Exit Code*: `0`.
- **Simulation Summary**:
  ```text
  [PASS] Test 1: Reset verified - both ways invalid in all four sets.
  [PASS] Test 2: Complete line filled into Way 0 of Set 0.
  [PASS] Test 3: Tag (0x00000A) and all four words confirmed correctly stored.
  [PASS] Test 4: Read all four words from Way 0 and verified hit0.
  [PASS] Test 5: Complete line with different tag filled into Way 1 of Set 0.
  [PASS] Test 6: Read all four words from Way 1 and verified hit1.
  [PASS] Test 7: Verified Way 0 is completely unchanged after filling Way 1.
  [PASS] Test 8: Verified different sets operate independently without interference.
  [PASS] Test 9: Verified tag mismatch produces a miss (hit0=0, hit1=0, data=0).
  [PASS] Test 10: Verified invalid ways never produce false hits.
  [PASS] Test 11: Reset verified clearing all valid bits across all four sets.
  ALL 11 UNIT TESTS PASSED SUCCESSFULLY! (cache_2way_datapath)
  ```

---

### Test Suite 3: LRU Controller Unit Test (`tb/tb_lru_controller.sv`)
- **Compilation Command**:
  ```bash
  iverilog -g2012 -Wall -I rtl -s tb_lru_controller -o build/tb_lru_controller.vvp \
    rtl/lru_controller.sv tb/tb_lru_controller.sv
  ```
  *Exit Code*: `0` (Zero compiler warnings).
- **Execution Command**:
  ```bash
  vvp build/tb_lru_controller.vvp
  ```
  *Exit Code*: `0`.
- **Simulation Summary**:
  ```text
  [PASS] TEST 1: All 4 LRU bits reset to 0 (Way 0 is victim)
  [PASS] TEST 2: Way 0 access in Set 0 makes Way 1 the victim
  [PASS] TEST 3: Way 1 access in Set 0 makes Way 0 the victim
  [PASS] TEST 4: Updating one set leaves the other sets unchanged
  [PASS] EXTRA : LRU state holds while update_en = 0
  [PASS] EXTRA : Reset clears modified LRU state to 0
  tb_lru_controller: ALL TESTS PASSED
  ```

---

### Test Suite 4: Two-Way Cache Smoke Test (`tb/tb_cache_2way_smoke.sv`)
- **Compilation Command**:
  ```bash
  iverilog -g2012 -Wall -I rtl -s tb_cache_2way_smoke -o build/tb_cache_2way_smoke.vvp \
    rtl/cache_pkg.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv \
    rtl/cache_2way_controller.sv rtl/cache_2way_top.sv tb/tb_cache_2way_smoke.sv
  ```
  *Exit Code*: `0` (Zero compiler warnings).
- **Execution Command**:
  ```bash
  vvp build/tb_cache_2way_smoke.vvp
  ```
  *Exit Code*: `0`.
- **Simulation Summary**:
  ```text
  [PASS] TEST 5: Invalid way chosen before LRU victim; hit way updates LRU
  [PASS] TEST 6: Miss on 0x00001238 fetched 4 words, tag 0x48 valid in set 3 way 0
  [PASS] TEST 7: Repeat and same-line reads hit with no extra memory reads
  [PASS] TEST 8: 0x00000000 (Way 0) and 0x00000080 (Way 1) coexist in set 0
  [PASS] TEST 9: A,B,A,C,A,B = M,M,H,M,H,M; C evicted B, A stayed, final B missed
  [PASS] TEST 10a: Stalls held stable (mem_req stall 36, mem_resp wait 60, cpu_resp stall 21 cyc)
  [PASS] TEST 10b: 400 random reads with random stalls matched the reference model
                   hits 123, misses 277, memory word reads 1108 (= 4 x misses)
  tb_cache_2way_smoke: ALL TESTS PASSED
  ```

---

### Test Suite 5: Complete Dual-Cache Comparison (`tb/tb_cache_comparison.sv`)
- **Compilation Command**:
  ```bash
  iverilog -g2012 -Wall -I rtl -I sim -s tb_cache_comparison -o build/tb_cache_comparison.vvp \
    rtl/cache_pkg.sv rtl/direct_mapped_cache.sv rtl/cache_2way_datapath.sv \
    rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv \
    sim/simple_main_memory.sv tb/tb_cache_comparison.sv
  ```
  *Exit Code*: `0` (Zero compiler warnings).
- **Execution Command**:
  ```bash
  vvp build/tb_cache_comparison.vvp
  ```
  *Exit Code*: `0`.
- **Simulation Summary**:
  ```text
  Starting scenario_1_sequential_locality (4 accesses)
    Direct-Mapped: Hits=3, Misses=1, MemReads=4, Cycles=27 (Avg: 6.75)
    Two-Way LRU:   Hits=3, Misses=1, MemReads=4, Cycles=27 (Avg: 6.75)
  [PASS] Scenario 1: Sequential Locality verified (1 miss, 3 hits for both).

  Starting scenario_2_conflict_heavy (8 accesses)
    Direct-Mapped: Hits=0, Misses=8, MemReads=32, Cycles=140 (Avg: 17.50)
    Two-Way LRU:   Hits=6, Misses=2, MemReads=8, Cycles=50 (Avg: 6.25)
  [PASS] Scenario 2: Conflict-Heavy Trace verified (DM: 8 misses, 2-Way: 2 misses, 6 hits).

  Starting scenario_3_explicit_lru (6 accesses)
    Direct-Mapped: Hits=0, Misses=6, MemReads=24, Cycles=102 (Avg: 17.00)
    Two-Way LRU:   Hits=2, Misses=4, MemReads=16, Cycles=72 (Avg: 12.00)
  [PASS] Scenario 3: Explicit LRU verified (A stayed hit, C evicted B, final B missed).

  Starting scenario_4_mixed_trace (16 accesses)
    Direct-Mapped: Hits=4, Misses=12, MemReads=48, Cycles=216 (Avg: 13.50)
    Two-Way LRU:   Hits=4, Misses=12, MemReads=48, Cycles=216 (Avg: 13.50)
  [PASS] Scenario 4: Deterministic Mixed Trace verified successfully.
  [tb_cache_comparison] Results successfully written to results/results.csv
  ALL TEST SCENARIOS PASSED PERFECTLY!
  ```

---

## 4. Architectural Analysis & Scenario Breakdown

### Scenario 1: Sequential Locality (4 accesses)
- **Addresses**: `0x00000000`, `0x00000004`, `0x00000008`, `0x0000000C` (all inside line 0).
- **Behavior**: Access 0 is a cold miss for both caches, fetching the 16-byte block. Accesses 1, 2, and 3 hit the cached line.
- **Results**: Both caches achieve **75.00% hit rate** and identical 27 execution cycles (6.75 cycles/access).

### Scenario 2: Conflict-Heavy Trace (8 accesses)
- **Addresses**: Alternating `0x00000000` (Tag 0) and `0x00000080` (Tag 1), 4 iterations.
- **Behavior**:
  - *Direct-Mapped*: Both addresses map to line index `3'b000`. Each access evicts the previous one, causing 8 misses out of 8 accesses (thrashing), generating 32 memory reads and taking 140 cycles (17.50 cycles/access).
  - *Two-Way Set-Associative*: Both addresses map to set index `2'b00`. The first two accesses allocate Way 0 and Way 1 respectively. All subsequent 6 accesses hit in cache.
- **Impact**: **75.00% hit rate** vs. **0.00%**, **75.0% memory traffic reduction**, **64.3% latency reduction**.

### Scenario 3: Explicit LRU Verification (6 accesses)
- **Trace**: `A (0x00) -> B (0x80) -> A (0x00) -> C (0x100) -> A (0x00) -> B (0x80)`.
- **Behavior**:
  - Access 0 (`A`): Cold miss $\rightarrow$ allocates Way 0, LRU bit = 1.
  - Access 1 (`B`): Cold miss $\rightarrow$ allocates Way 1, LRU bit = 0.
  - Access 2 (`A`): **Hit in Way 0** $\rightarrow$ LRU bit toggles to 1 (Way 1 becomes victim).
  - Access 3 (`C`): Miss $\rightarrow$ both ways valid, LRU bit = 1 $\rightarrow$ **evicts Way 1 (`B`)**, installs `C`, LRU bit = 0.
  - Access 4 (`A`): **Hit in Way 0** $\rightarrow$ verifies `A` was preserved!
  - Access 5 (`B`): **Miss** $\rightarrow$ verifies `B` was properly evicted by `C`!
- **Results**: Two-way achieves 2 hits, 4 misses (33.33% hit rate), while direct-mapped suffers 6 misses (0.00% hit rate).

### Scenario 4: Deterministic Mixed Trace (16 accesses)
- **Trace**: 16 accesses exercising multi-set spatial locality, conflict misses, and loop re-reads.
- **Results**: Both caches record 4 hits and 12 misses (25.00% hit rate), 48 memory reads, and 216 total cycles.

---

## 5. Verification Checklist

| Test / Evaluation Step | Target Component | Tool / Environment | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| Direct-Mapped Unit Test | `direct_mapped_cache` | Icarus Verilog 13.0 | 7 test blocks pass | 7 test blocks pass | **PASSED** |
| Two-Way Datapath Unit Test | `cache_2way_datapath` | Icarus Verilog 13.0 | 11 unit tests pass | 11 unit tests pass | **PASSED** |
| LRU Controller Unit Test | `lru_controller` | Icarus Verilog 13.0 | 6 test blocks pass | 6 test blocks pass | **PASSED** |
| Two-Way Cache Smoke Test | `cache_2way_top` | Icarus Verilog 13.0 | 6 smoke tests pass | 6 smoke tests pass | **PASSED** |
| Scenario 1: Sequential | Both Caches | Icarus Verilog 13.0 | 3 Hits, 1 Miss | 3 Hits, 1 Miss | **PASSED** |
| Scenario 2: Conflict-Heavy | Both Caches | Icarus Verilog 13.0 | DM: 0H 8M, 2W: 6H 2M | DM: 0H 8M, 2W: 6H 2M | **PASSED** |
| Scenario 3: Explicit LRU | Both Caches | Icarus Verilog 13.0 | DM: 0H 6M, 2W: 2H 4M | DM: 0H 6M, 2W: 2H 4M | **PASSED** |
| Scenario 4: Mixed Trace | Both Caches | Icarus Verilog 13.0 | Calculate from sim | 4 Hits, 12 Misses | **PASSED** |
| Invariant 1 ($\text{hits} + \text{misses} == \text{accesses}$) | Both Caches | CSV / Testbench | Exact equality | Verified for all rows | **PASSED** |
| Invariant 2 ($\text{reads} == 4 \times \text{misses}$) | Both Caches | CSV / Testbench | Exact equality | Verified for all rows | **PASSED** |
| CSV Output Generation | `results/results.csv` | File system | 8 valid data rows | 8 valid data rows | **PASSED** |
| Python Results Analyzer | `analyze_results.py` | Python 3.10 | Zero validation errors | Verified & formatted | **PASSED** |
| Plot 1: Hit Rate Chart | Matplotlib | Python 3.10 | Image generated | `results/hit_rate_comparison.png` | **PASSED** |
| Plot 2: Average Latency Chart | Matplotlib | Python 3.10 | Image generated | `results/average_latency_comparison.png` | **PASSED** |
| Plot 3: Memory Traffic Chart | Matplotlib | Python 3.10 | Image generated | `results/memory_reads_comparison.png` | **PASSED** |
| Hardware FPGA Synthesis | Vivado / Yosys | Host toolchain | LUT/FF resource metrics | Synthesis tool not installed | **UNEXECUTED (Tool Not Available)** |

---

## 6. Integration Bugs Found and Corrections Performed

1. **Package Guarding (`rtl/cache_pkg.sv`)**:
   - *Issue*: Including `cache_pkg.sv` when already compiled on the command line created preprocessor duplicate definitions or required explicit `-I rtl` flags in some compilers.
   - *Fix*: Wrapped package in `` `ifndef CACHE_PKG_SV `` and in `direct_mapped_cache.sv` guarded the include statement.
2. **Explicit Timescale Precision**:
   - *Issue*: Icarus Verilog emitted warnings regarding unspecified design element time precision.
   - *Fix*: Added `` `timescale 1ns / 1ps `` consistently to `cache_pkg.sv` and `direct_mapped_cache.sv`.
3. **Memory Bus Address Bit-Select Warnings**:
   - *Issue*: Complex slicing inside `always_comb` triggered constant-select sensitivity warnings in Icarus Verilog.
   - *Fix*: Driven continuously via `assign mem_req_addr = {req_addr_q[31:4], refill_cnt_q, 2'b00};`, eliminating compiler warnings and ensuring clear hardware synthesis mapping.

---

## 7. Remaining Limitations

1. **Hardware FPGA Synthesis**: Neither Vivado nor Yosys is installed on the host machine. Both cache modules are designed to be fully synthesizable, but physical place-and-route and post-implementation timing closure remain unexecuted until a machine with synthesis toolchain access is available.
2. **Write Policy**: Both designs currently implement read-only caching per the architectural assignment contract; write-back / write-through with dirty-bit tracking is not part of this iteration.
