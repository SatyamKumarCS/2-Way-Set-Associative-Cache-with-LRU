# Final Master Audit Report — Phase I & Phase II
## Modern Computer Architecture Project

**Project Title:** Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache  
**Institution:** Newton School of Technology  
**Department:** Department of Computer Science and Artificial Intelligence  
**Repository:** [https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git](https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git)  
**Date of Audit:** November 23, 2026  
**Auditor:** Automated Independent Verification System (Antigravity Agent)

---

## 1. Executive Summary & Overall Project Status

| Project Phase | Overall Status | Notes & Conditions |
|---|:---:|---|
| **Phase I (30% Evaluation)** | **PASS / PENDING** | **RTL & Report: PASS**. All RTL compiles and passes 100% of unit & comparative tests. IEEE Report is compiled (9 pages) with all 5 authors. Repository structure is clean. **Video: PENDING external portal submission** (Video file `Cache_Project_Demo_Final.mp4` exists in repo with 240.2s duration; hosted streaming link awaits college portal submission). |
| **Phase II (70% Evaluation)** | **AWAITING INTERVIEW / ROADMAP READY** | Full IEEE Report covers all Phase II academic sections (Results & Discussion, Contributions, Conclusion, and Future Work Roadmap). Simulation & Python analytics are complete. Physical FPGA synthesis is explicitly scoped as post-Phase I future work. Project interview is **Awaiting College Evaluation**. |

---

## 2. Repository Structure Verification

**Status: PASS**

The actual Git root was confirmed via `git rev-parse --show-toplevel` as `/Users/chinmaysoni/MCA_project `. The directory contents strictly conform to the expected repository specification:

| Expected File / Directory | Actual Path in Repository | Status | Verification Detail |
|---|---|:---:|---|
| `rtl/cache_pkg.sv` | `rtl/cache_pkg.sv` | **PASS** | Package with parameters and 5 FSM states |
| `rtl/direct_mapped_cache.sv` | `rtl/direct_mapped_cache.sv` | **PASS** | 8 lines, 16B lines, single 25-bit comparator |
| `rtl/cache_2way_datapath.sv` | `rtl/cache_2way_datapath.sv` | **PASS** | 4 sets $\times$ 2 ways, dual 26-bit comparators |
| `rtl/lru_controller.sv` | `rtl/lru_controller.sv` | **PASS** | 4 set bits, invalid-first priority logic |
| `rtl/cache_2way_controller.sv` | `rtl/cache_2way_controller.sv` | **PASS** | 5-state Mealy/Moore sequencer & burst refill |
| `rtl/cache_2way_top.sv` | `rtl/cache_2way_top.sv` | **PASS** | Structural wrapper connecting datapath, LRU, controller |
| `sim/simple_main_memory.sv` | `sim/simple_main_memory.sv` | **PASS** | Synchronous 1024-word SRAM with multi-cycle latency |
| `tb/tb_direct_mapped.sv` | `tb/tb_direct_mapped.sv` | **PASS** | Standalone direct-mapped unit testbench |
| `tb/tb_cache_2way_datapath.sv` | `tb/tb_cache_2way_datapath.sv` | **PASS** | 11-step datapath unit testbench |
| `tb/tb_lru_controller.sv` | `tb/tb_lru_controller.sv` | **PASS** | Exhaustive 1-bit LRU controller unit testbench |
| `tb/tb_cache_2way_smoke.sv` | `tb/tb_cache_2way_smoke.sv` | **PASS** | 2-way top-level integration & 400 random reads |
| `tb/tb_cache_comparison.sv` | `tb/tb_cache_comparison.sv` | **PASS** | Dual-cache benchmark driver & CSV logger |
| `analysis/analyze_results.py` | `analysis/analyze_results.py` | **PASS** | Python analytics script & Matplotlib plot generator |
| `results/results.csv` | `results/results.csv` | **PASS** | Raw simulation metrics from `tb_cache_comparison` |
| `results/*.png` | 3 comparison plots | **PASS** | Generated hit rate, latency, and memory read plots |
| `docs/architecture.md` | `docs/architecture.md` | **PASS** | Microarchitectural specifications |
| `docs/interfaces.md` | `docs/interfaces.md` | **PASS** | Bus handshake and interface protocols |
| `docs/final_integration_report.md` | `docs/final_integration_report.md` | **PASS** | Multi-member integration log |
| `report/ieee_phase1_report.tex` | `report/ieee_phase1_report.tex` | **PASS** | Full IEEEtran LaTeX source |
| `report/ieee_phase1_report.pdf` | `report/ieee_phase1_report.pdf` | **PASS** | 9-page compiled IEEE conference PDF |
| `report/references.bib` | `report/references.bib` | **PASS** | 6 authentic computer architecture citations |
| `README.md` | `README.md` | **PASS** | Root README with badges, architecture, and tables |
| `.gitignore` | `.gitignore` | **PASS** | Correctly excludes `build/`, `.vvp`, LaTeX temp files |
| `Cache_Project_Demo_Final.mp4` | `Cache_Project_Demo_Final.mp4` | **PASS** | 14 MB demo video file (Duration: 240.2s / 4m 0s) |

---

## 3. RTL Code & Architectural Verification

**Status: PASS**

Every SystemVerilog source file was inspected against the technical specifications:

1. **Parameters & Data Capacities**:
   - Both caches implement exactly **128 bytes of data capacity** partitioned into **16-byte lines** (4 words $\times$ 32 bits).
   - Direct-Mapped: 8 cache lines, Tag `[31:7]` (25 bits), Index `[6:4]` (3 bits), Word `[3:2]` (2 bits), Byte `[1:0]` (2 bits).
   - 2-Way Set-Associative: 4 sets, 2 ways per set, Tag `[31:6]` (26 bits), Set `[5:4]` (2 bits), Word `[3:2]` (2 bits), Byte `[1:0]` (2 bits).
2. **Comparator Sizing & Parallelism**:
   - Direct-mapped uses a single 25-bit comparator.
   - 2-way datapath uses two parallel 26-bit comparators (`cmp0` and `cmp1`) executing in parallel during the single-cycle `LOOKUP` state.
3. **1-Bit LRU Replacement Invariants**:
   - 4 independent bits stored in `lru_bits[3:0]`.
   - Access to Way 0 sets bit to `1` (evict Way 1). Access to Way 1 sets bit to `0` (evict Way 0).
   - Enforces **invalid-first priority**: if Way 0 is empty (`!valid0`), allocate Way 0; if Way 0 valid and Way 1 empty (`valid0 && !valid1`), allocate Way 1; LRU eviction occurs **only when both ways are valid**.
4. **FSM & Handshakes**:
   - Both controllers adhere to a 5-state FSM (`IDLE`, `LOOKUP`, `MEM_REQ`, `MEM_WAIT`, `RESP`).
   - Standard ready/valid handshakes on both CPU and memory interfaces.
   - Address poisoning protection verified: internal registers latch the address upon request handshake; external address bus corruption does not corrupt cache lookup or refill.
   - CPU response stability verified under backpressure: `cpu_resp_valid` and `cpu_resp_data` hold steady until `cpu_resp_ready` is asserted.
5. **Memory Refill & Counters**:
   - 4-word burst refill fetches sequential words from the aligned 16-byte boundary.
   - Hardware counters increment cleanly: `hit_count` and `miss_count` increment once per CPU lookup; `mem_word_read_count` increments on accepted memory requests ($== 4 \times \text{misses}$).
   - No multiple drivers, no circular combinational loops, and no unintended latches detected.

---

## 4. Simulation Execution & Unit Test Results

**Status: PASS**

All five test suites were compiled and executed with **Icarus Verilog (v12.0)** under IEEE 1800-2012 flags (`-g2012 -Wall`).

### Test Suite 1: Direct-Mapped Cache Unit Test
- **Command:** `iverilog -g2012 -Wall -I rtl -s tb_dm_test -o build/tb_direct_mapped.vvp rtl/cache_pkg.sv rtl/direct_mapped_cache.sv tb/tb_direct_mapped.sv && vvp build/tb_direct_mapped.vvp`
- **Compiler Exit Code:** 0 (0 warnings)
- **Simulation Exit Code:** 0
- **Tests Executed:** 7 sub-tests (Cold misses, temporal locality hits, spatial locality word access, conflict replacement thrashing, memory latency stalls, CPU backpressure response stability, hardware counter precision).
- **Failures:** 0
- **Summary:** `ALL TESTS PASSED PERFECTLY! (0 errors)`. Confirmed $28 \text{ mem reads} = 4 \times 7 \text{ misses}$.

### Test Suite 2: Two-Way Datapath Unit Test
- **Command:** `iverilog -g2012 -Wall -I rtl -s tb_cache_2way_datapath -o build/tb_cache_2way_datapath.vvp rtl/cache_pkg.sv rtl/cache_2way_datapath.sv tb/tb_cache_2way_datapath.sv && vvp build/tb_cache_2way_datapath.vvp`
- **Compiler Exit Code:** 0 (0 warnings)
- **Simulation Exit Code:** 0
- **Tests Executed:** 11 sub-tests (Reset state, fill Way 0, tag & word verification, read Way 0 hit, fill Way 1, read Way 1 hit, Way 0 invariance, independent set isolation, tag mismatch miss, invalid-way suppression, full reset).
- **Failures:** 0
- **Summary:** `ALL 11 UNIT TESTS PASSED SUCCESSFULLY! (cache_2way_datapath)`.

### Test Suite 3: LRU Controller Unit Test
- **Command:** `iverilog -g2012 -Wall -I rtl -s tb_lru_controller -o build/tb_lru_controller.vvp rtl/lru_controller.sv tb/tb_lru_controller.sv && vvp build/tb_lru_controller.vvp`
- **Compiler Exit Code:** 0 (0 warnings)
- **Simulation Exit Code:** 0
- **Tests Executed:** 6 test sequences (Reset to 0, Way 0 access toggles to 1, Way 1 access toggles to 0, cross-set state isolation, `update_en=0` state holding, synchronous reset).
- **Failures:** 0
- **Summary:** `tb_lru_controller: ALL TESTS PASSED`.

### Test Suite 4: Two-Way Cache Smoke Test
- **Command:** `iverilog -g2012 -Wall -I rtl -s tb_cache_2way_smoke -o build/tb_cache_2way_smoke.vvp rtl/cache_pkg.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv tb/tb_cache_2way_smoke.sv && vvp build/tb_cache_2way_smoke.vvp`
- **Compiler Exit Code:** 0 (0 warnings)
- **Simulation Exit Code:** 0
- **Tests Executed:** Invalid-way allocation priority, 4-word refill, spatial hits, conflict coexistence (`0x00000000` & `0x00000080`), 3-address LRU sequence ($A \to B \to A \to C \to A \to B$), random multi-cycle memory/CPU stall handling, and **400 randomized accesses** matching reference model.
- **Failures:** 0
- **Summary:** `tb_cache_2way_smoke: ALL TESTS PASSED` (123 hits, 277 misses, 1108 memory reads $= 4 \times 277$, zero lost or duplicate transfers).

### Test Suite 5: Dual Cache Comparison Test
- **Command:** `iverilog -g2012 -Wall -I rtl -I sim -s tb_cache_comparison -o build/tb_cache_comparison.vvp rtl/cache_pkg.sv rtl/direct_mapped_cache.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv sim/simple_main_memory.sv tb/tb_cache_comparison.sv && vvp build/tb_cache_comparison.vvp`
- **Compiler Exit Code:** 0 (0 warnings)
- **Simulation Exit Code:** 0
- **Tests Executed:** 4 comprehensive benchmarks (Sequential Locality, Conflict-Heavy Thrashing, Explicit LRU Validation, Mixed Trace).
- **Failures:** 0
- **Summary:** `ALL TEST SCENARIOS PASSED PERFECTLY! Results successfully written to results/results.csv`.

---

## 5. Performance Metric Audit & CSV Invariant Validation

**Status: PASS**

The empirical simulation results logged to `results/results.csv` were verified against hardware invariants:

| Scenario | Cache Architecture | Accesses | Hits | Misses | Hit Rate | Miss Rate | Mem Reads | Total Cycles | Avg Latency | Invariant Checks |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Scenario 1: Sequential** | Direct-Mapped | 4 | 3 | 1 | 75.00% | 25.00% | 4 | 27 | 6.75 cyc | $3+1=4$, $4=4\times 1$ |
| (Spatial Locality) | 2-Way Set-Assoc. | 4 | 3 | 1 | 75.00% | 25.00% | 4 | 27 | 6.75 cyc | $3+1=4$, $4=4\times 1$ |
| **Scenario 2: Conflict-Heavy** | Direct-Mapped | 8 | 0 | 8 | 0.00% | 100.00% | 32 | 140 | 17.50 cyc | $0+8=8$, $32=4\times 8$ |
| (Thrashing Pattern) | 2-Way Set-Assoc. | 8 | 6 | 2 | **75.00%** | **25.00%** | **8** | **50** | **6.25 cyc** | $6+2=8$, $8=4\times 2$ |
| **Scenario 3: Explicit LRU** | Direct-Mapped | 6 | 0 | 6 | 0.00% | 100.00% | 24 | 102 | 17.00 cyc | $0+6=6$, $24=4\times 6$ |
| ($A \to B \to A \to C \to A \to B$) | 2-Way Set-Assoc. | 6 | 2 | 4 | **33.33%** | **66.67%** | **16** | **72** | **12.00 cyc** | $2+4=6$, $16=4\times 4$ |
| **Scenario 4: Mixed Trace** | Direct-Mapped | 16 | 4 | 12 | 25.00% | 75.00% | 48 | 216 | 13.50 cyc | $4+12=16$, $48=4\times 12$ |
| (Multi-set Capacity) | 2-Way Set-Assoc. | 16 | 4 | 12 | 25.00% | 75.00% | 48 | 216 | 13.50 cyc | $4+12=16$, $48=4\times 12$ |

### Architectural Breakthrough Highlights (Scenario 2):
- **Hit Rate Improvement:** $+75.00\%$ ($0.00\% \to 75.00\%$)
- **Memory Traffic Reduction:** $-75.00\%$ ($32 \text{ words} \to 8 \text{ words}$)
- **Execution Latency Speedup:** $-64.29\%$ ($140 \text{ cycles} \to 50 \text{ cycles}$)

### Python Analyzer Verification:
- **Command:** `python3 analysis/analyze_results.py`
- **Result:** Successfully recomputed summary table matching `results.csv` to 2 decimal places and updated:
  - `results/hit_rate_comparison.png`
  - `results/average_latency_comparison.png`
  - `results/memory_reads_comparison.png`

---

## 6. IEEE Project Report Audit & PDF Validation

**Status: PASS**

The report was verified both at the LaTeX source level (`report/ieee_phase1_report.tex`) and compiled into PDF via `tectonic`.

1. **Format & Typography:** Official `IEEEtran` conference template, 2-column layout, Times academic typography.
2. **Page Count:** 9 pages, complete with TikZ system architecture diagrams, address mapping diagrams, FSM state diagrams, and 3-panel comparative performance plots.
3. **Authorship & Affiliation:**
   - Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, Lakshya Bapna
   - Department of Computer Science and Artificial Intelligence, Newton School of Technology
4. **Required Sections (Covering both Phase I & Phase II):**
   - Abstract (Lines 52–54)
   - Introduction & 3C Miss Classification (Section I, Lines 63–79)
   - Literature Review & Prior Work (Section II, Lines 84–95)
   - Proposed Hardware Architecture & Circuit Implementation (Section III, Lines 100–460)
   - Team Roles & Individual Contributions (Section IV, Lines 465–502)
   - Experimental Results & Comparative Performance Analysis (Section V, Lines 506–654)
   - Conclusion & Future Work Roadmap (Section VI, Lines 659–671)
   - Authentic References & BibTeX (Lines 676–677)
5. **Numerical Consistency:** Every number in Table III (Simulation Results), Table I (Hardware Parameters), and Table IV (LRU Trace) strictly matches `results/results.csv`.
6. **Synthesis Clarification:** The report explicitly clarifies in Section V-E that Phase I evaluation is based on cycle-accurate RTL simulation with Icarus Verilog, and that physical FPGA implementation is targeted for Phase II.

---

## 7. Phase I Evaluation Requirements Checklist (30% Weightage)

| Rubric Deliverable | Target Weight | Required Components | Actual Repository Status | Evaluation Status |
|---|:---:|---|---|:---:|
| **IEEE Project Report** | 10 Marks | Abstract, Lit Review, Architecture, Individual Contributions, References, 2-column layout | Complete 9-page PDF (`report/ieee_phase1_report.pdf`) with all 5 authors and authentic citations. | **PASS** |
| **Demonstration Video** | 15 Marks | Max 5 min, team intro, working demonstration, Verilog implementation | Video file `Cache_Project_Demo_Final.mp4` (14 MB, 240.2s duration) is present in the repository root. Spoken 5-paragraph script available in `docs/team_presentation_script.md`. **Pending:** Uploading to external streaming host if required by college portal. | **PASS (File) / PENDING (Hosted URL)** |
| **GitHub Repository** | 5 Marks | Complete source, testbenches, CSV, plots, documentation, git history | Repository configured at `chinmay7980/2-Way-Set-Associative-Cache-with-LRU`, all required files present, git commits reflect all members. | **PASS** |

---

## 8. Phase II Evaluation Requirements Checklist (70% Weightage)

| Requirement | Required Focus | Actual Status in Repository | Evaluation Status |
|---|---|---|:---:|
| **Final IEEE Report** | Abstract, Lit Review, Architecture, Results & Discussion, Contributions, Conclusion, References | Fully expanded in `report/ieee_phase1_report.tex` and compiled to PDF. Contains all required Phase II sections. | **PASS** |
| **Repository Maintenance** | Clean repo, no binary blobs in version control, accurate documentation, reproducible scripts | Verified: `build/` and `.vvp` binaries are ignored via `.gitignore`. `README.md` documents complete setup and execution. | **PASS** |
| **Interview Readiness** | Explainable by all 5 members, deep grasp of cache concepts, viva readiness | Spoken script and slide guide documented. Individual responsibilities aligned to each author. | **AWAITING COLLEGE INTERVIEW** |
| **Hardware Implementation Roadmap** | Write policies (write-through/write-back), MSHR, FPGA synthesis | Outlined in report Section VI-A as Phase II engineering milestones. | **ROADMAP READY (NOT REQUIRED FOR PHASE I)** |

---

## 9. GitHub Repository History & Contributor Verification

**Status: PASS**

Inspection of Git commit logs (`git log --oneline` and `git shortlog -sne`) confirms that all five members have committed directly to the project:

```text
4  Chinmay Soni      <chinmaysoni@Chinmays-MacBook-Pro.local>
3  Krishna Verma     <krishnavermaambala05@gmail.com>
2  Chinmay Soni      <chinmaynst24@gmail.com>
2  SatyamKumarCS     <satyamkumarch15@gmail.com>
1  Akshit vats       <akshitvats93@gmail.com>
1  Lakshya Bapna     <lakshyabapna03@gmail.com>
1  Lakshya Bapna     <lakshyabapna@Lakshyas-MacBook-Pro-6.local>
```

- **Chinmay Soni (Member 1):** Package architecture, direct-mapped cache RTL, common configuration.
- **Lakshya Bapna (Member 2):** Two-way datapath arrays, parallel comparators, way selection MUX.
- **Satyam Kumar (Member 3):** 1-bit LRU replacement controller, 5-state cache FSM, top-level integration.
- **Krishna Verma (Member 4):** Main memory model, comparison testbench, CSV data logging, analytics script.
- **Akshit Vats (Member 5):** Verification support, trace invariant auditing, academic report compilation.

---

## 10. Technical Concepts for Viva & Interview Preparation

To ensure 100% readiness for the upcoming college project evaluation, each team member should be prepared to address the following technical questions:

### 1. Satyam Kumar (Integration & LRU FSM)
- Explain the 5 states of the cache FSM (`IDLE`, `LOOKUP`, `MEM_REQ`, `MEM_WAIT`, `RESP`) and why Mealy/Moore separation is used.
- How does the FSM guarantee blocking operation without dropping CPU requests during memory refill stalls?
- Walk through the LRU state transition: why does an access to Way 0 set the LRU bit to `1`?

### 2. Chinmay Soni (Baseline Architecture & Addressing)
- Explain the 32-bit address decomposition for the direct-mapped cache (Tag `[31:7]`, Index `[6:4]`, Word `[3:2]`, Byte `[1:0]`).
- Why does the direct-mapped cache experience catastrophic 0% hit rate in Scenario 2? Explain the ping-pong thrashing mechanism.
- How is a 16-byte aligned burst refill address generated from a CPU word request?

### 3. Lakshya Bapna (Datapath & Parallel Comparators)
- Why does the 2-way set-associative cache require a 26-bit tag, while the direct-mapped cache uses a 25-bit tag?
- Explain how dual parallel comparators operate concurrently and how the hit way multiplexer routes the correct 32-bit word.
- What is the invalid-first replacement rule and why is it critical during cold startup?

### 4. Krishna Verma (Verification & Simulation)
- Explain the address poisoning technique (`32'hFFFF_FFFF`) used in the testbench to verify address latching.
- Describe how the synchronous memory model simulates DRAM latency using `LATENCY_CYCLES` and `REQUEST_GAP_CYCLES`.
- Walk through the cycle-accurate execution of Scenario 3 ($A \to B \to A \to C \to A \to B$). Why does $C$ evict $B$ instead of $A$?

### 5. Akshit Vats (Performance Analysis & System Invariants)
- State the two mathematical hardware invariants and explain why they must hold for every completed transaction.
- Explain the trade-off: why did the 2-way cache achieve a 64.29% reduction in latency even though each individual memory miss penalty is identical?
- Why did Scenario 4 produce identical 25% hit rates on both caches? (Capacity misses vs. conflict misses).

---

## 11. Known Defects, Fixes & Current Clean State

1. **Git Remote & Author Configuration:** Confirmed remote points to `https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git`. Author information across `README.md`, `report/ieee_phase1_report.tex`, and `docs/final_integration_report.md` correctly reflects all five team members.
2. **Build Directory Cleanliness:** Verified that `.gitignore` correctly ignores intermediate object files (`build/*.vvp`, LaTeX `.aux`, `.log`, `.fls`). No binary files pollute git tracking.
3. **Simulation Determinism:** Fresh re-execution of all five testbenches produced zero warnings and zero assertion failures.
4. **FPGA Synthesis Boundary:** Fixed earlier ambiguous terminology; documentation and report strictly state that RTL simulation was performed in Phase I, while physical FPGA implementation remains future work for Phase II.

---

## 12. Remaining Mandatory Submission Steps

1. **Video Streaming Link (If required by submission form):**
   - The repository already contains the video file: `Cache_Project_Demo_Final.mp4` (Duration: 4m 0s).
   - If the college evaluation submission form specifically requires a hosted streaming link (YouTube unlisted URL or Google Drive link), upload `Cache_Project_Demo_Final.mp4` to that platform and paste the link into the submission form.
2. **Viva/Interview Readiness:**
   - Team members should review their individual technical questions listed in Section 10.
   - Use the 5-paragraph script in `docs/team_presentation_script.md` for oral presentation.
