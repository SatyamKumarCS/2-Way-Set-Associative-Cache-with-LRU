# Waveform Generation and GTKWave Analysis Guide

**Project:** Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache  
**Institution:** Department of Computer Science and Artificial Intelligence, Newton School of Technology  
**Authors:** Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, Lakshya Bapna  
**Repository:** [https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git](https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git)

---

## 1. Overview of Waveform Infrastructure

This project supports cycle-accurate VCD (Value Change Dump) waveform generation for verifying hardware handshakes, cache lookups, line replacements, and memory burst refills.

Waveform generation is implemented safely using conditional compilation (` `ifdef DUMP_WAVES` `) and dedicated demonstration testbenches. This ensures that normal continuous regression runs remain fast without creating large unneeded trace files, while full waveform dumping is available on demand with a single compiler flag.

### Generated VCD Files and Locations

| VCD File Path | Source Testbench | Target Module Under Test | Description |
|---|---|---|---|
| `build/waves/direct_mapped_cache.vcd` | `tb/tb_direct_mapped.sv` | `direct_mapped_cache` | Unit verification of Chinmay's direct-mapped cache (cold misses, hits, line conflicts, backpressure). |
| `build/waves/lru_replacement_demo.vcd` | `tb/tb_lru_demo_wave.sv` | `cache_2way_top` | Focused 6-access canonical LRU replacement sequence ($A \to B \to A \to C \to A \to B$) on Set 0. |
| `build/waves/two_way_lru_cache.vcd` | `tb/tb_cache_comparison.sv` | `direct_mapped_cache` & `cache_2way_top` | Dual-cache comparison running all 4 evaluation scenarios concurrently against reference memories. |

---

## 2. Toolchain Setup & GTKWave on macOS

### 1. Icarus Verilog and VVP
Simulation requires `iverilog` v11+ and `vvp`. Verify installation:
```bash
iverilog -v
vvp -v
```
If missing, install via Homebrew:
```bash
brew install icarus-verilog
```

### 2. Installing GTKWave on macOS
GTKWave is distributed via Homebrew Cask on modern macOS:
```bash
# Check if already installed
command -v gtkwave

# Install GTKWave via Homebrew Cask
brew install --cask gtkwave
```
*Note on macOS Security Gatekeeper:* If macOS displays a prompt stating "GTKWave cannot be opened because the developer cannot be verified", open **System Settings $\to$ Privacy & Security** and click **Open Anyway**, or execute:
```bash
xattr -d com.apple.quarantine /Applications/gtkwave.app
```

---

## 3. Step-by-Step Compilation and Waveform Generation

All commands must be executed from the project root directory (`~/MCA_project`):
```bash
cd ~/MCA_project
mkdir -p build/waves
```

### A. Direct-Mapped Cache Waveform
Compiles and runs the direct-mapped unit testbench with waveform dumping enabled:
```bash
# 1. Compile with DUMP_WAVES macro
iverilog -g2012 -Wall -I rtl -s tb_dm_test -DDUMP_WAVES \
  -o build/direct_mapped_wave.vvp \
  rtl/cache_pkg.sv rtl/direct_mapped_cache.sv tb/tb_direct_mapped.sv

# 2. Execute simulation runtime
vvp build/direct_mapped_wave.vvp
```
*Expected Console Output:*
```
VCD info: dumpfile build/waves/direct_mapped_cache.vcd opened for output.
=======================================================
   DIRECT-MAPPED CACHE COMPREHENSIVE VERIFICATION
=======================================================
...
[PASS] Memory word read count strictly equals 4 x miss count (28 = 4 x 7).
   ALL TESTS PASSED PERFECTLY! (0 errors)
```
*Output File:* `build/waves/direct_mapped_cache.vcd` (approx. 17 KB).

---

### B. Dedicated LRU Replacement Demonstration Waveform
Compiles and executes the 6-access LRU proof sequence ($A \to B \to A \to C \to A \to B$):
```bash
# 1. Compile dedicated LRU demo
iverilog -g2012 -Wall -I rtl -I sim -s tb_lru_demo_wave \
  -o build/lru_demo_wave.vvp \
  rtl/cache_pkg.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv \
  rtl/cache_2way_controller.sv rtl/cache_2way_top.sv \
  sim/simple_main_memory.sv tb/tb_lru_demo_wave.sv

# 2. Execute simulation runtime
vvp build/lru_demo_wave.vvp
```
*Expected Console Output:*
```
VCD info: dumpfile build/waves/lru_replacement_demo.vcd opened for output.
==================================================================
   LRU REPLACEMENT DEMONSTRATION WAVEFORM SIMULATION
   Sequence: A -> B -> A -> C -> A -> B
==================================================================
[235000 ns] Step 1: Access A (0x00): Addr=0x00000000 -> MISS | LRU bit[0]=1 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000000 (V=0)
[435000 ns] Step 2: Access B (0x80): Addr=0x00000080 -> MISS | LRU bit[0]=0 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000002 (V=1)
[485000 ns] Step 3: Access A (0x00): Addr=0x00000000 -> HIT  | LRU bit[0]=1 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000002 (V=1)
[685000 ns] Step 4: Access C (0x100): Addr=0x00000100 -> MISS | LRU bit[0]=0 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000004 (V=1)
[735000 ns] Step 5: Access A (0x00): Addr=0x00000000 -> HIT  | LRU bit[0]=1 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000004 (V=1)
[935000 ns] Step 6: Access B (0x80): Addr=0x00000080 -> MISS | LRU bit[0]=0 | Way0_tag=0x0000000 (V=1) | Way1_tag=0x0000002 (V=1)
------------------------------------------------------------------
FINAL STATE VERIFICATION OF SET 0:
  Way 0 Tag: 0x0000000 (Valid=1) [Expected: A = 0x0000000]
  Way 1 Tag: 0x0000002 (Valid=1) [Expected: B = 0x0000002]
  LRU bit[0]: 0 [Expected: 0 -> Way 0 is LRU victim candidate]
[SUCCESS] Verified: Way 0 = A, Way 1 = B, Block C was successfully evicted!
```
*Output File:* `build/waves/lru_replacement_demo.vcd` (approx. 20 KB).

---

### C. Full Dual-Cache Comparison Waveform
Compiles and executes the master comparative benchmark across all four scenarios:
```bash
# 1. Compile comparison testbench with DUMP_WAVES macro
iverilog -g2012 -Wall -I rtl -I sim -s tb_cache_comparison -DDUMP_WAVES \
  -o build/two_way_lru_wave.vvp \
  rtl/cache_pkg.sv rtl/direct_mapped_cache.sv rtl/cache_2way_datapath.sv \
  rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv \
  sim/simple_main_memory.sv tb/tb_cache_comparison.sv

# 2. Execute simulation runtime
vvp build/two_way_lru_wave.vvp
```
*Output File:* `build/waves/two_way_lru_cache.vcd` (approx. 145 KB).

---

## 4. How to Inspect Waveforms in GTKWave

### Launching GTKWave on macOS
Run either of the following commands from your terminal:
```bash
gtkwave build/waves/direct_mapped_cache.vcd
# OR
gtkwave build/waves/lru_replacement_demo.vcd
# OR
open -a gtkwave build/waves/lru_replacement_demo.vcd
```

### Essential Navigation & Display Settings in GTKWave
1. **Expanding the Hierarchy (SST Pane):**  
   In the left-hand panel (**SST - Structural Signal Tree**), click the disclosure triangle next to the top-level testbench name (e.g., `tb_lru_demo_wave` or `tb_dm_test`), then expand `dut` to see internal submodules (`u_controller`, `u_datapath`, `u_lru`).
2. **Adding Signals to Waveform Window:**  
   Select the desired signals from the lower-left signal list and click **Append** or drag them into the black signal display area.
3. **Changing Radix to Hexadecimal / Binary:**  
   Right-click any address or data signal $\to$ **Data Format** $\to$ select **Hexadecimal** (for addresses, tags, and words) or **Binary** (for handshakes, valid bits, and LRU bits).
4. **Zooming and Centering:**
   - **Zoom Fit:** Press `Ctrl + Space` or click the magnifying glass with the red box icon to fit the entire simulation on screen.
   - **Zoom In / Out:** `Ctrl + +` / `Ctrl + -` or scroll with the mouse wheel.
5. **Placing Markers:**  
   Click anywhere in the wave window to drop the primary vertical marker; the top ruler displays the exact simulation timestamp in nanoseconds.

---

## 5. The Six Core Viva Demonstration Exercises

During your Phase II evaluation and viva, you can open the VCD files and walk the examiner through these six concrete hardware behaviors.

---

### Exercise 1: Initial Cold Miss and Compulsory Refill
* **File to Open:** `build/waves/direct_mapped_cache.vcd` or `build/waves/lru_replacement_demo.vcd`
* **Signals to Add:**
  - `clk`, `rst_n`
  - `cpu_req_valid`, `cpu_req_ready`, `cpu_req_addr`
  - `dut.state_q` (or `dut.u_controller.state_q`)
  - `mem_req_valid`, `mem_req_ready`, `mem_req_addr`
  - `mem_resp_valid`, `mem_resp_data`
  - `cpu_resp_valid`, `cpu_resp_data`
* **What Happens at the Clock Edges:**
  1. At reset release, `cpu_req_valid` rises with `cpu_req_addr = 0x00000000`. The cache is in state `IDLE (000)` and asserts `cpu_req_ready = 1`.
  2. On the next clock edge, the handshake commits (`valid && ready`), and the FSM transitions to `LOOKUP (001)`.
  3. In `LOOKUP`, the cache checks `valid_array[0]`. Because it is `0`, a miss occurs (`tag_match = 0`, `cache_hit = 0`).
  4. The FSM transitions to `MEM_REQ (010)`, issuing four word read requests (`0x00`, `0x04`, `0x08`, `0x0C`) to main memory.
  5. As each word arrives in `MEM_WAIT (011)`, it is written into the data array.
  6. On the final word, the tag is committed, valid bit is set to `1`, and the FSM enters `RESP (100)`, asserting `cpu_resp_valid = 1`.
* **What to Say in the Viva:**  
  *"Here we observe a compulsory cold miss. The line valid bit was initially zero. The cache controller stalled the CPU, initiated a 4-word burst refill over the memory bus, populated the line, and returned the requested word in 27 clock cycles."*

---

### Exercise 2: Spatial Locality Hit
* **File to Open:** `build/waves/direct_mapped_cache.vcd` (Test 3: Four Word Positions)
* **Signals to Add:**
  - `cpu_req_addr`
  - `dut.cache_hit`
  - `dut.req_word`
  - `mem_req_valid`
* **What Happens at the Clock Edges:**
  1. The CPU sends `0x00000004` (Word 1 of the block just refilled).
  2. In state `LOOKUP`, `valid_array[0]` is `1` and the tag matches.
  3. `dut.cache_hit` goes HIGH immediately.
  4. `mem_req_valid` stays at **0** (zero off-chip memory traffic).
  5. The FSM transitions directly from `LOOKUP` to `RESP` in just **1 clock cycle**!
* **What to Say in the Viva:**  
  *"This demonstrates spatial locality. Because the preceding miss fetched all four words of the 16-byte line, accessing word offset 1 hits immediately on on-chip SRAM with zero main memory transactions."*

---

### Exercise 3: Direct-Mapped Conflict Thrashing
* **File to Open:** `build/waves/direct_mapped_cache.vcd` (Test 4)
* **Signals to Add:**
  - `cpu_req_addr`
  - `dut.tag_array[0]`
  - `dut.miss_count`
  - `mem_word_read_count`
* **What Happens at the Clock Edges:**
  1. Access `0x00000080` maps to line index `0` (`address[6:4] = 3'b000`), but has tag `0x000001`.
  2. It evicts address `0x00000000` (which had tag `0x000000`).
  3. When `0x00000000` is accessed again immediately afterward, it misses and evicts `0x00000080`.
  4. Every single access causes a full 4-word memory refill; `miss_count` increments on every access, causing a 100% miss rate (0% hit rate).
* **What to Say in the Viva:**  
  *"This is direct-mapped cache thrashing. Because both addresses share line index 0, they cannot coexist. Every access evicts the previous one, degrading effective performance to raw memory bus speed."*

---

### Exercise 4: Two-Way Cache Eliminates Conflict Thrashing
* **File to Open:** `build/waves/two_way_lru_cache.vcd` (Scenario 2: Conflict-Heavy Trace)
* **Signals to Add:**
  - `u_sa_cache.u_datapath.way0_tag[0]`, `u_sa_cache.u_datapath.way0_valid[0]`
  - `u_sa_cache.u_datapath.way1_tag[0]`, `u_sa_cache.u_datapath.way1_valid[0]`
  - `u_sa_cache.u_datapath.hit0`, `u_sa_cache.u_datapath.hit1`
* **What Happens at the Clock Edges:**
  1. Access 1 (`0x00000000`) misses and populates **Way 0** of Set 0.
  2. Access 2 (`0x00000080`) misses and populates **Way 1** of Set 0 (using the invalid-first rule).
  3. Accesses 3 through 8 alternate between `0x00` and `0x80`.
  4. Observe `hit0` pulse high when `0x00` is accessed, and `hit1` pulse high when `0x80` is accessed!
  5. Both lines remain concurrently valid in Set 0. The hit rate surges to **75.00%**, reducing execution latency from 140 cycles to 50 cycles (a **2.80x speedup**).
* **What to Say in the Viva:**  
  *"By adding a second way, both conflicting blocks reside simultaneously in Set 0. The parallel comparators detect which way matches, completely eliminating conflict thrashing."*

---

### Exercise 5: Cycle-Accurate 1-Bit LRU Replacement Proof
* **File to Open:** `build/waves/lru_replacement_demo.vcd`
* **Signals to Add:**
  - `cpu_req_addr`
  - `dut.u_controller.lookup_hit`
  - `dut.u_lru.lru_bits[0]`
  - `dut.u_datapath.way0_tag[0]`, `dut.u_datapath.way1_tag[0]`
* **Cycle-by-Cycle Verification Trace:**

| Step | Address | Result | Set 0 Contents | `lru_bits[0]` Before Access | `lru_bits[0]` After Access | Hardware Action |
|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **1** | $A$ (`0x00`) | **MISS** | W0: $A$, W1: Inv | `0` (Reset) | `1` (Victim = W1) | $A$ loaded into invalid Way 0; LRU points to Way 1. |
| **2** | $B$ (`0x80`) | **MISS** | W0: $A$, W1: $B$ | `1` | `0` (Victim = W0) | $B$ loaded into invalid Way 1; LRU points to Way 0. |
| **3** | $A$ (`0x00`) | **HIT** | W0: $A$, W1: $B$ | `0` | `1` (Victim = W1) | Access to Way 0 makes Way 1 the victim. |
| **4** | $C$ (`0x100`) | **MISS** | W0: $A$, W1: $C$ | `1` | `0` (Victim = W0) | $C$ evicts LRU victim Way 1 ($B$); $A$ preserved in Way 0! |
| **5** | $A$ (`0x00`) | **HIT** | W0: $A$, W1: $C$ | `0` | `1` (Victim = W1) | $A$ hits in Way 0; LRU updates to point to Way 1. |
| **6** | $B$ (`0x80`) | **MISS** | W0: $A$, W1: $B$ | `1` | `0` (Victim = W0) | $B$ missed (was evicted in Step 4); $B$ replaces Way 1 ($C$). |

* **Final Verified Hardware State:**  
  - Way 0 Tag = `0x0000000` ($A$)
  - Way 1 Tag = `0x0000002` ($B$)
  - Block $C$ is evicted.
* **What to Say in the Viva:**  
  *"At Step 4, when block C arrived, block A was protected because it was referenced at Step 3. The LRU bit pointed to Way 1, so block B was evicted. At Step 5, block A produced a confirmed hit. This provides cycle-accurate proof of 1-bit LRU correctness."*

---

### Exercise 6: Four-Word Burst Refill Loop
* **File to Open:** `build/waves/lru_replacement_demo.vcd` (Zoom in on Step 1)
* **Signals to Add:**
  - `dut.u_controller.state_q`
  - `dut.u_controller.refill_count_q`
  - `mem_req_valid`, `mem_req_ready`, `mem_req_addr`
  - `mem_resp_valid`, `mem_resp_ready`, `mem_resp_data`
  - `dut.u_datapath.fill_word_we`
* **What Happens at the Clock Edges:**
  1. In `MEM_REQ`, `mem_req_valid` is asserted with word offset `00` (`addr = 0x00`).
  2. Once the memory asserts `mem_req_ready`, the handshake commits and the controller transitions to `MEM_WAIT`.
  3. When `mem_resp_valid` is returned by memory, `fill_word_we` pulses high, writing Word 0 into the data array.
  4. The FSM loops back to `MEM_REQ`, incrementing `refill_count_q` to `1` (`addr = 0x04`).
  5. This cycle repeats exactly four times (`refill_count_q` = 0, 1, 2, 3) until all 16 bytes are written into the cache line.
* **What to Say in the Viva:**  
  *"The cache controller implements a 4-word burst transaction loop. It issues aligned 32-bit word read requests, waits for memory ready/valid handshakes, and increments its internal refill counter until the entire 16-byte line is assembled."*

---

## 6. Hierarchical Signal Reference Cheat-Sheet

Use this table to quickly find any signal in GTKWave:

### Direct-Mapped Cache (`build/waves/direct_mapped_cache.vcd`)
- **Top Scope:** `tb_dm_test`
- **DUT Instance:** `tb_dm_test.dut`
  - `state_q`: Current FSM state (`IDLE=0`, `LOOKUP=1`, `MEM_REQ=2`, `MEM_WAIT=3`, `RESP=4`)
  - `req_tag [24:0]`: Extracted 25-bit tag from request address
  - `req_idx [2:0]`: Extracted 3-bit line index
  - `req_word [1:0]`: Extracted 2-bit word offset
  - `tag_match`: Combinational tag comparator output
  - `cache_hit`: `valid_array[req_idx] && tag_match`
  - `valid_array [0:7]`: 8 valid bits
  - `tag_array [0:7]`: 8 tag registers (25 bits each)
  - `data_array [0:7][0:3]`: $8 \times 4$ 32-bit word data array

### Two-Way Set-Associative Cache (`build/waves/lru_replacement_demo.vcd`)
- **Top Scope:** `tb_lru_demo_wave`
- **DUT Top Instance:** `tb_lru_demo_wave.dut`
  - **Controller Instance:** `dut.u_controller`
    - `state_q`: FSM state
    - `lookup_hit`: `dp_hit0 || dp_hit1`
    - `hit_way`: Which way matched (`0` = Way 0, `1` = Way 1)
    - `replace_way`: Chosen replacement way (invalid-first, else LRU victim)
    - `refill_count_q [1:0]`: Refill word counter (0 to 3)
  - **Datapath Instance:** `dut.u_datapath`
    - `hit0`, `hit1`: Parallel tag match signals
    - `valid0`, `valid1`: Way 0 and Way 1 validity for currently addressed set
    - `way0_tag [0:3]`, `way1_tag [0:3]`: 26-bit tag storage for Sets 0 to 3
    - `way0_valid [0:3]`, `way1_valid [0:3]`: 1-bit validity flags
    - `way0_data [0:3][0:3]`, `way1_data [0:3][0:3]`: 32-bit data storage arrays
  - **LRU Instance:** `dut.u_lru`
    - `lru_bits [0:3]`: 1-bit LRU state per set (`0` $\to$ Way 0 is victim, `1` $\to$ Way 1 is victim)
    - `victim_way`: Selected candidate for eviction

---

## 7. Clean Build and Verification Instructions

To clean intermediate files and re-verify everything from scratch:

```bash
# 1. Remove old build artifacts
rm -rf build/*.vvp build/waves/*.vcd

# 2. Re-create directories
mkdir -p build/waves

# 3. Generate all three waveforms
iverilog -g2012 -Wall -I rtl -s tb_dm_test -DDUMP_WAVES -o build/direct_mapped_wave.vvp rtl/cache_pkg.sv rtl/direct_mapped_cache.sv tb/tb_direct_mapped.sv
vvp build/direct_mapped_wave.vvp

iverilog -g2012 -Wall -I rtl -I sim -s tb_lru_demo_wave -o build/lru_demo_wave.vvp rtl/cache_pkg.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv sim/simple_main_memory.sv tb/tb_lru_demo_wave.sv
vvp build/lru_demo_wave.vvp

iverilog -g2012 -Wall -I rtl -I sim -s tb_cache_comparison -DDUMP_WAVES -o build/two_way_lru_wave.vvp rtl/cache_pkg.sv rtl/direct_mapped_cache.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv sim/simple_main_memory.sv tb/tb_cache_comparison.sv
vvp build/two_way_lru_wave.vvp

# 4. Run Python analytics
python3 analysis/analyze_results.py
```
All commands execute cleanly with zero warnings or errors.
