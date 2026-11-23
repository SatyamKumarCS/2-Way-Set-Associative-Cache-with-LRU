# Project Demonstration Video Script (Phase I Evaluation)

**Project Title:** Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache  
**Institution:** Newton School of Technology  
**Department:** Computer Science and Artificial Intelligence  
**GitHub Repository:** [https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU](https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU)  
**Target Video Duration:** 4 Minutes 45 Seconds (Maximum limit: 4:50)  

---

## 1. Scene-by-Scene Script & Production Table

| Timestamp | Speaker | Dialogue | What Appears on Screen | Recording Instructions |
|---|---|---|---|---|
| **0:00–0:12** | **Satyam Kumar** | "Hello everyone! Welcome to our Phase One project demonstration for Modern Computer Architecture at Newton School of Technology, Department of Computer Science and Artificial Intelligence." | **Title Slide:**<br>• Project Title in bold clean typography.<br>• Subtitle: *Phase I Prototype Demonstration*.<br>• Department & Institution name.<br>• GitHub link watermark at the bottom. | Crisp 1080p slide. Subtle slow zoom-in (Ken Burns effect). Keep narration warm, confident, and articulate. |
| **0:12–0:30** | **Satyam Kumar** | "In modern computing, CPUs operate at speeds far beyond off-chip main memory. If a processor must fetch every single instruction and operand directly from DRAM, high memory access latency throttles overall throughput—a challenge known as the memory wall. Cache memory mitigates this bottleneck by buffering recently accessed data on-chip. In this project, we implement and evaluate two synthesizable hardware architectures in SystemVerilog: an eight-line direct-mapped cache baseline and a four-set, two-way set-associative cache with one-bit LRU replacement." | **Animated Concept Slide:**<br>• CPU $\longleftrightarrow$ L1 Cache $\longleftrightarrow$ Main Memory hierarchy diagram.<br>• Visual callout emphasizing the *Memory Wall* latency gap.<br>• Side-by-side block cards: Direct-Mapped vs. 2-Way Set-Associative with LRU. | Smooth cross-dissolve from title slide. Animate data flow arrows between CPU, Cache, and DRAM. |
| **0:30–0:43** | **Akshit Vats** | "Our development team consists of five student researchers: Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, and Lakshya Bapna. Together, we designed, modeled, and verified both cache architectures under identical, cycle-accurate simulation environments." | **Team Roster Slide:**<br>• Professional cards displaying all five member names in order.<br>• Department badge: *Computer Science & AI, Newton School of Technology*.<br>• Clean modern layout with verified project role badges. | Show all 5 names clearly on screen simultaneously. Highlight names smoothly as introduced. |
| **0:43–0:55** | **Akshit Vats** | "Our technical engineering packages were organized into four core hardware modules: Chinmay developed the direct-mapped cache baseline; Lakshya engineered the two-way datapath; Satyam built the LRU replacement controller and top integration; and Krishna developed the main memory model and analytics suite, with joint verification support across the entire team." | **Work Package Breakdown:**<br>• 4 modular blocks matching repository structure:<br>1. *Direct-Mapped Baseline*<br>2. *Two-Way Datapath*<br>3. *LRU & FSM Controller*<br>4. *Memory Model & Benchmarking* | Slide transition highlighting the modular division of labor from `README.md`. |
| **0:55–1:10** | **Chinmay Soni** | "Let's examine the hardware architecture. Both caches share an identical total data capacity of 128 bytes, a line size of 16 bytes—which is four 32-bit words—and a 32-bit byte-addressed memory interface. In our direct-mapped baseline, the cache contains exactly eight lines. Address bits 6 down to 4 select the line index, bits 3 down to 2 select the word, and bits 31 down to 7 form a 25-bit tag. Because each physical memory block maps to exactly one line, lookup requires only a single comparator, making hit detection exceptionally fast." | **Direct-Mapped Architecture Diagram:**<br>• Display Fig. 2 address decoder (`addr[31:7]` tag, `[6:4]` line, `[3:2]` word, `[1:0]` offset).<br>• 8-line array diagram with single 25-bit comparator.<br>• Highlight 128-byte total capacity. | Pan across address bit-slice breakdown. Highlight the single tag comparator comparing against the selected line. |
| **1:10–1:25** | **Lakshya Bapna** | "However, direct-mapped caches suffer from conflict misses when multiple active memory lines hash to the same line index. To solve this, our two-way set-associative cache organizes storage into four sets, with two independent lines or 'ways' per set. Address bits 5 down to 4 select the set index, while bits 31 down to 6 form a 26-bit tag. During lookup, two parallel 26-bit comparators check Way 0 and Way 1 simultaneously. This enables two conflicting memory blocks that map to the same set to coexist on-chip without evicting each other." | **2-Way Datapath Diagram:**<br>• Display Fig. 3 from IEEE report (`cache_2way_datapath.sv`).<br>• Dual ways (Way 0 and Way 1) across Sets 0 to 3.<br>• Dual parallel 26-bit comparators and way selection multiplexer. | Zoom into dual comparators firing in parallel. Visually illustrate Way 0 and Way 1 storing different tags for Set 0. |
| **1:25–1:40** | **Satyam Kumar** | "To govern replacement when both ways in a set are valid, our design implements a dedicated 1-bit Least Recently Used (LRU) controller. Each of the four sets maintains one LRU state bit. When a set experiences a cache miss, our controller enforces a strict invalid-first priority rule: if any way is unallocated, it is used immediately. Only when both ways are valid does the controller evict the candidate indicated by the LRU bit. Furthermore, every access to Way 0 sets the bit to 1, while every access to Way 1 clears it to 0, protecting the most recently accessed data." | **LRU State Transition Diagram:**<br>• 1-bit per set convention table ($0 \to \text{Way 0 victim}, 1 \to \text{Way 1 victim}$).<br>• Invalid-first allocation flow.<br>• State transition diagram showing LRU bit toggling on Way 0 / Way 1 access. | Display visual flowchart of the invalid-first check followed by the LRU eviction decision. |
| **1:40–1:58** | **Chinmay Soni** | "Now, let's step into the working implementation in our development workspace. All hardware modules are authored in synthesizable IEEE 1800-2012 SystemVerilog. Here in `direct_mapped_cache.sv`, we see the synchronous 5-state FSM: IDLE, LOOKUP, MEM_REQ, MEM_WAIT, and RESP. On a miss, the controller issues aligned 4-word burst requests to main memory, updates the internal tag and valid arrays, and holds the response data stable until accepted by the CPU." | **Screen Recording (VS Code / Antigravity):**<br>• Open `rtl/direct_mapped_cache.sv`.<br>• Scroll through `always_ff` sequential block and 5-state FSM cases.<br>• Highlight ready/valid handshake signals and counters. | Crisp IDE capture with 125% editor zoom and dark theme. Highlight key lines with mouse cursor. |
| **1:58–2:16** | **Lakshya Bapna** | "In `cache_2way_datapath.sv`, we separate storage from control. Here are the dual-way data arrays: four sets by four words by 32 bits for Way 0 and Way 1. Notice the concurrent tag comparators evaluating both ways simultaneously. The hit signals `hit0` and `hit1` immediately feed our way multiplexer, routing the correct 32-bit word to the output in a single clock cycle without inserting pipeline bubbles." | **Screen Recording (IDE):**<br>• Open `rtl/cache_2way_datapath.sv`.<br>• Show `way0_data` and `way1_data` declarations.<br>• Highlight concurrent comparator assignments: `assign hit0 = valid0_q[set_idx] && (tag0_q[set_idx] == req_tag);` | Cursor points out dual arrays and parallel comparator assignments. |
| **2:16–2:35** | **Satyam Kumar** | "Next, `lru_controller.sv` implements the 1-bit replacement policy across four registers. Look at `cache_2way_controller.sv`: it orchestrates the burst refill sequence, increments hit and miss performance counters, and manages the invalid-first allocation logic. Finally, `cache_2way_top.sv` structurally binds the datapath, controller, and LRU modules into a clean, 17-port interface identical to our direct-mapped baseline." | **Screen Recording (IDE):**<br>• Split editor view: `lru_controller.sv` and `cache_2way_controller.sv`.<br>• Transition to `cache_2way_top.sv` showing module instantiations. | Smooth scroll across structural port mappings in `cache_2way_top.sv`. |
| **2:35–2:50** | **Krishna Verma** | "To ensure deterministic, reproducible benchmarking, `simple_main_memory.sv` models a multi-cycle synchronous RAM with parameterized read latency and backpressure stalls. Main memory data is generated deterministically by XOR-ing a fixed base constant with the word address, allowing our verification testbenches to assert data integrity on every single read transaction." | **Screen Recording (IDE):**<br>• Open `sim/simple_main_memory.sv`.<br>• Highlight `LATENCY_CYCLES = 2` parameter and the memory data function `data = 32'hA5000000 ^ addr`. | Highlight latency counter and deterministic memory data assignment. |
| **2:50–3:15** | **Krishna Verma** | "Let's run the live simulation using Icarus Verilog. We execute our unified comparative testbench, `tb_cache_comparison.sv`. Watch the terminal output as both caches process Scenario 3: the canonical three-address sequence: Address A at 0x00, B at 0x80, A, C at 0x100, A, and B. In the direct-mapped cache, every single access misses because all three addresses compete for line zero. But in our two-way cache, A and B fill Way 0 and Way 1. When C arrives, it evicts least-recently used B, keeping A intact! The next access to A hits immediately, proving our hardware LRU algorithm operates with cycle-accurate precision." | **Terminal Screen Recording (Live Simulation):**<br>• Command executed: `vvp build/tb_cache_comparison.vvp`<br>• Real terminal output scrolling.<br>• Highlight Scenario 3 execution block:<br>`[PASS] Scenario 3: Explicit LRU verified (A stayed hit, C evicted B, final B missed).`<br>`Direct-Mapped: Hits=0, Misses=6 (0.00%)`<br>`Two-Way LRU: Hits=2, Misses=4 (33.33%)` | Zoom into terminal output during Scenario 3. Highlight the `[PASS]` assertion and counter prints. |
| **3:15–3:35** | **Krishna Verma** | "Now let's examine the empirical performance comparison. We run our Python analytics pipeline, which parses `results/results.csv` and renders three publication-grade comparative graphs. First is Cache Hit Rate. In Scenario 1, sequential spatial locality gives both caches an identical 75% hit rate due to 4-word block refills. In Scenario 4, the mixed workload yields a 25% hit rate in both structures due to capacity constraints across active sets." | **Performance Graph 1 on Screen:**<br>• Display `results/hit_rate_comparison.png` full screen.<br>• Callout box over Scenario 1 (75% vs 75%) and Scenario 4 (25% vs 25%). | High-resolution graphic. Subtle animated zoom on Scenario 1 and 4 bars. |
| **3:35–3:58** | **Akshit Vats** | "However, the true advantage of set associativity appears in Scenario 2—our conflict-heavy workload alternating between two addresses sharing the same set. The direct-mapped cache undergoes catastrophic ping-pong thrashing, crashing to a 0.00% hit rate with 32 memory reads and 140 cycles. The two-way set-associative cache retains both addresses simultaneously in Set 0, achieving a 75.00% hit rate, requiring only 8 memory reads, and completing in just 50 cycles!" | **Performance Graph 2 & 3 on Screen:**<br>• Display `results/average_latency_comparison.png` and `results/memory_reads_comparison.png`.<br>• Highlight Scenario 2 metrics side-by-side:<br>- Hit Rate: 0.00% $\to$ 75.00%<br>- Memory Reads: 32 $\to$ 8 (**75.00% reduction**)<br>- Total Cycles: 140 $\to$ 50 (**64.29% reduction**)<br>- Avg Latency: 17.50 $\to$ 6.25 cycles/access | Side-by-side graphic view with highlighted percentage reduction badges in green. |
| **3:58–4:20** | **Akshit Vats** | "This represents a dramatic 75% reduction in off-chip memory traffic and a 64.29% reduction in execution latency. Importantly, our data reveals an essential architectural principle: two-way associativity specifically resolves conflict misses up to degree two, but it does not eliminate capacity misses once the working set exceeds aggregate cache size. Across every benchmark transaction, our hardware counters strictly verified that hits plus misses equaled total completed accesses, and memory reads equaled four times misses." | **Summary Data Table on Screen:**<br>• Formatted comparison table from `results/results.csv` displaying all 4 scenarios.<br>• Equations highlighted:<br>$\text{hits} + \text{misses} == \text{accesses}$<br>$\text{mem\_reads} == 4 \times \text{misses}$ | Display Table III from the IEEE report. Pulse the hardware invariant equations at the bottom. |
| **4:20–4:35** | **Satyam Kumar** | "To summarize: in Phase One of our Modern Computer Architecture project, we successfully designed, modeled, integrated, and verified both a direct-mapped cache and a two-way set-associative cache with 1-bit LRU replacement in synthesizable SystemVerilog. Through cycle-accurate simulation, we demonstrated how set associativity eliminates conflict thrashing, reduces memory bus pressure, and enhances CPU throughput." | **Summary Slide:**<br>• Key Achievements checklist:<br>$\checkmark$ Synthesizable SystemVerilog RTL<br>$\checkmark$ Cycle-accurate Ready/Valid handshakes<br>$\checkmark$ Verified 1-Bit LRU replacement<br>$\checkmark$ Demonstrated 75% memory traffic reduction under conflict thrashing | Clean animated slide ticking off verified milestones. |
| **4:35–4:45** | **Chinmay Soni** | "Please note that RTL simulation and functional verification were completed in this phase; physical FPGA synthesis and board implementation will be executed in Phase Two. All source code, testbenches, and our full IEEE conference report are available on our GitHub repository. Thank you for watching our project demonstration!" | **Closing Slide:**<br>• Project Title & Author Roster.<br>• Institutional Affiliation: *Department of Computer Science & AI, Newton School of Technology*.<br>• GitHub Repository URL: `https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU`<br>• QR code linking directly to the repository. | Elegant closing title screen. Fade to black as closing music resolves at 4:45. |

---

## 2. Complete Final Narration Script (Voiceover Teleprompter)

```text
[0:00 - SATYAM KUMAR]
Hello everyone! Welcome to our Phase One project demonstration for Modern Computer Architecture at Newton School of Technology, Department of Computer Science and Artificial Intelligence.

In modern computing, CPUs operate at speeds far beyond off-chip main memory. If a processor must fetch every single instruction and operand directly from DRAM, high memory access latency throttles overall throughput—a challenge known as the memory wall. Cache memory mitigates this bottleneck by buffering recently accessed data on-chip. In this project, we implement and evaluate two synthesizable hardware architectures in SystemVerilog: an eight-line direct-mapped cache baseline and a four-set, two-way set-associative cache with one-bit LRU replacement.

[0:30 - AKSHIT VATS]
Our development team consists of five student researchers: Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, and Lakshya Bapna. Together, we designed, modeled, and verified both cache architectures under identical, cycle-accurate simulation environments.

Our technical engineering packages were organized into four core hardware modules: Chinmay developed the direct-mapped cache baseline; Lakshya engineered the two-way datapath; Satyam built the LRU replacement controller and top integration; and Krishna developed the main memory model and analytics suite, with joint verification support across the entire team.

[0:55 - CHINMAY SONI]
Let's examine the hardware architecture. Both caches share an identical total data capacity of 128 bytes, a line size of 16 bytes—which is four 32-bit words—and a 32-bit byte-addressed memory interface. In our direct-mapped baseline, the cache contains exactly eight lines. Address bits 6 down to 4 select the line index, bits 3 down to 2 select the word, and bits 31 down to 7 form a 25-bit tag. Because each physical memory block maps to exactly one line, lookup requires only a single comparator, making hit detection exceptionally fast.

[1:10 - LAKSHYA BAPNA]
However, direct-mapped caches suffer from conflict misses when multiple active memory lines hash to the same line index. To solve this, our two-way set-associative cache organizes storage into four sets, with two independent lines or 'ways' per set. Address bits 5 down to 4 select the set index, while bits 31 down to 6 form a 26-bit tag. During lookup, two parallel 26-bit comparators check Way 0 and Way 1 simultaneously. This enables two conflicting memory blocks that map to the same set to coexist on-chip without evicting each other.

[1:25 - SATYAM KUMAR]
To govern replacement when both ways in a set are valid, our design implements a dedicated 1-bit Least Recently Used (LRU) controller. Each of the four sets maintains one LRU state bit. When a set experiences a cache miss, our controller enforces a strict invalid-first priority rule: if any way is unallocated, it is used immediately. Only when both ways are valid does the controller evict the candidate indicated by the LRU bit. Furthermore, every access to Way 0 sets the bit to 1, while every access to Way 1 clears it to 0, protecting the most recently accessed data.

[1:40 - CHINMAY SONI]
Now, let's step into the working implementation in our development workspace. All hardware modules are authored in synthesizable IEEE 1800-2012 SystemVerilog. Here in direct_mapped_cache.sv, we see the synchronous 5-state FSM: IDLE, LOOKUP, MEM_REQ, MEM_WAIT, and RESP. On a miss, the controller issues aligned 4-word burst requests to main memory, updates the internal tag and valid arrays, and holds the response data stable until accepted by the CPU.

[1:58 - LAKSHYA BAPNA]
In cache_2way_datapath.sv, we separate storage from control. Here are the dual-way data arrays: four sets by four words by 32 bits for Way 0 and Way 1. Notice the concurrent tag comparators evaluating both ways simultaneously. The hit signals hit0 and hit1 immediately feed our way multiplexer, routing the correct 32-bit word to the output in a single clock cycle without inserting pipeline bubbles.

[2:16 - SATYAM KUMAR]
Next, lru_controller.sv implements the 1-bit replacement policy across four registers. Look at cache_2way_controller.sv: it orchestrates the burst refill sequence, increments hit and miss performance counters, and manages the invalid-first allocation logic. Finally, cache_2way_top.sv structurally binds the datapath, controller, and LRU modules into a clean, 17-port interface identical to our direct-mapped baseline.

[2:35 - KRISHNA VERMA]
To ensure deterministic, reproducible benchmarking, simple_main_memory.sv models a multi-cycle synchronous RAM with parameterized read latency and backpressure stalls. Main memory data is generated deterministically by XOR-ing a fixed base constant with the word address, allowing our verification testbenches to assert data integrity on every single read transaction.

[2:50 - KRISHNA VERMA]
Let's run the live simulation using Icarus Verilog. We execute our unified comparative testbench, tb_cache_comparison.sv. Watch the terminal output as both caches process Scenario 3: the canonical three-address sequence: Address A at 0x00, B at 0x80, A, C at 0x100, A, and B. In the direct-mapped cache, every single access misses because all three addresses compete for line zero. But in our two-way cache, A and B fill Way 0 and Way 1. When C arrives, it evicts least-recently used B, keeping A intact! The next access to A hits immediately, proving our hardware LRU algorithm operates with cycle-accurate precision.

[3:15 - KRISHNA VERMA]
Now let's examine the empirical performance comparison. We run our Python analytics pipeline, which parses results.csv and renders three publication-grade comparative graphs. First is Cache Hit Rate. In Scenario 1, sequential spatial locality gives both caches an identical 75% hit rate due to 4-word block refills. In Scenario 4, the mixed workload yields a 25% hit rate in both structures due to capacity constraints across active sets.

[3:35 - AKSHIT VATS]
However, the true advantage of set associativity appears in Scenario 2—our conflict-heavy workload alternating between two addresses sharing the same set. The direct-mapped cache undergoes catastrophic ping-pong thrashing, crashing to a 0.00% hit rate with 32 memory reads and 140 cycles. The two-way set-associative cache retains both addresses simultaneously in Set 0, achieving a 75.00% hit rate, requiring only 8 memory reads, and completing in just 50 cycles!

[3:58 - AKSHIT VATS]
This represents a dramatic 75% reduction in off-chip memory traffic and a 64.29% reduction in execution latency. Importantly, our data reveals an essential architectural principle: two-way associativity specifically resolves conflict misses up to degree two, but it does not eliminate capacity misses once the working set exceeds aggregate cache size. Across every benchmark transaction, our hardware counters strictly verified that hits plus misses equaled total completed accesses, and memory reads equaled four times misses.

[4:20 - SATYAM KUMAR]
To summarize: in Phase One of our Modern Computer Architecture project, we successfully designed, modeled, integrated, and verified both a direct-mapped cache and a two-way set-associative cache with 1-bit LRU replacement in synthesizable SystemVerilog. Through cycle-accurate simulation, we demonstrated how set associativity eliminates conflict thrashing, reduces memory bus pressure, and enhances CPU throughput.

[4:35 - CHINMAY SONI]
Please note that RTL simulation and functional verification were completed in this phase; physical FPGA synthesis and board implementation will be executed in Phase Two. All source code, testbenches, and our full IEEE conference report are available on our GitHub repository. Thank you for watching our project demonstration!
```

---

## 3. Screen Recording Action Checklist

Follow this checklist during screen recording to capture seamless footage:

- [ ] **Desktop Resolution**: Set primary recording monitor to 1920x1080 (16:9) at 60 fps.
- [ ] **Terminal Setup**:
  - Font: Fira Code, JetBrains Mono, or Menlo at 15 pt.
  - Background: Clean semi-transparent dark theme.
  - Command 1 ready in history: `iverilog -g2012 -Wall -I rtl -I sim -s tb_cache_comparison -o build/tb_cache_comparison.vvp rtl/cache_pkg.sv rtl/direct_mapped_cache.sv rtl/cache_2way_datapath.sv rtl/lru_controller.sv rtl/cache_2way_controller.sv rtl/cache_2way_top.sv sim/simple_main_memory.sv tb/tb_cache_comparison.sv`
  - Command 2 ready in history: `vvp build/tb_cache_comparison.vvp`
  - Command 3 ready in history: `python3 analysis/analyze_results.py`
- [ ] **IDE Configuration (VS Code / Antigravity)**:
  - Font size: 16 pt for maximum legibility on mobile and desktop screens.
  - Open files in tabs:
    1. `rtl/direct_mapped_cache.sv`
    2. `rtl/cache_2way_datapath.sv`
    3. `rtl/lru_controller.sv`
    4. `rtl/cache_2way_controller.sv`
    5. `rtl/cache_2way_top.sv`
    6. `sim/simple_main_memory.sv`
  - Close sidebar (`Cmd+B`) and hide notification popups.
- [ ] **Image Asset Preparation**:
  - Full-resolution views of `results/hit_rate_comparison.png`, `results/average_latency_comparison.png`, and `results/memory_reads_comparison.png`.
  - Architecture diagrams from `report/ieee_phase1_report.pdf` (Figures 1, 2, 3, and 4).

---

## 4. Required Figures, Diagrams & Graphical Assets

| Asset Name | Repository Location | Presentation Scene |
|---|---|---|
| **System Architectural Block Diagram** | `report/ieee_phase1_report.pdf` (Fig. 1) | Scene 1 & 3 |
| **Address Field Partitioning Comparison** | `report/ieee_phase1_report.pdf` (Fig. 2) / `README.md` | Scene 3 |
| **Two-Way Datapath Circuit Diagram** | `report/ieee_phase1_report.pdf` (Fig. 3) | Scene 3 & 4 |
| **Cache FSM State Transition Graph** | `report/ieee_phase1_report.pdf` (Fig. 4) | Scene 3 & 4 |
| **Hit Rate Comparison Bar Chart** | `results/hit_rate_comparison.png` | Scene 5 |
| **Average Latency Comparison Bar Chart** | `results/average_latency_comparison.png` | Scene 5 |
| **Memory Word Reads Traffic Bar Chart** | `results/memory_reads_comparison.png` | Scene 5 |
| **Summary Benchmark Metrics Table** | `results/results.csv` / Table IV in report | Scene 5 |

---

## 5. Suggested Opening and Closing Titles

### Opening Title (0:00–0:08)
```text
================================================================================
                    NEWTON SCHOOL OF TECHNOLOGY
      DEPARTMENT OF COMPUTER SCIENCE AND ARTIFICIAL INTELLIGENCE

                MODERN COMPUTER ARCHITECTURE (PHASE I)

        DESIGN AND PERFORMANCE ANALYSIS OF A TWO-WAY 
   SET-ASSOCIATIVE CACHE WITH LRU REPLACEMENT COMPARED WITH 
                   A DIRECT-MAPPED CACHE
================================================================================
```

### Team Roster Screen (0:30–0:42)
```text
                          PROJECT INVESTIGATORS
          ----------------------------------------------------
          • Satyam Kumar      — LRU Engine & Top-Level Integration
          • Krishna Verma     — Main Memory & Benchmark Analytics
          • Akshit Vats       — Verification Support & Documentation
          • Chinmay Soni      — Direct-Mapped Baseline & Packaging
          • Lakshya Bapna     — Two-Way Storage Datapath Subsystem
          ----------------------------------------------------
          Department of Computer Science and Artificial Intelligence
```

### Closing Title (4:35–4:45)
```text
================================================================================
                THANK YOU FOR WATCHING OUR DEMONSTRATION!

             Phase I Evaluation — Newton School of Technology

   GitHub Repository:
   https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git

   [QR Code linking directly to repository]
================================================================================
```

---

## 6. Audio, Voiceover & Background Music Guidelines

1. **Vocal Pacing**:
   - Maintain a steady speaking rate of 130–140 words per minute.
   - Pause for half a second before and after changing speakers.
   - Emphasize key technical metrics clearly (e.g., *"75 percent hit rate"*, *"64.29 percent speedup"*).
2. **Microphone Setup**:
   - Use a dedicated cardioid USB or condenser microphone with a pop filter.
   - Keep microphone 15 cm from the mouth to avoid proximity bass distortion.
   - Apply light noise gate and gentle normalization (-1.0 dB true peak) in Audacity / Premiere.
3. **Background Music Recommendations**:
   - Track style: Minimal corporate ambient, gentle electronic underscore, or modern acoustic study beat (tempo 90–110 BPM).
   - Audio Ducking: Keep background music at **-24 dB to -28 dB** under dialogue, swelling to **-16 dB** only during the 5-second intro and outro bumpers.
   - Zero distracting drums or vocal samples in the music track.

---

## 7. Final Video Editing & Quality Checklist

- [ ] **Total Runtime**: Exactly between 4:40 and 4:48 (never exceed 4:50).
- [ ] **Aspect Ratio**: 16:9 widescreen (1920x1080p or 2560x1440p).
- [ ] **Speaker Balance**: Audio levels matched across all 5 recorded voices (consistent volume within $\pm 1$ dB).
- [ ] **Lower Third Overlays**: Add clean name captions whenever a member starts speaking:
  - *Satyam Kumar | LRU Controller & FSM*
  - *Akshit Vats | Verification & Documentation*
  - *Chinmay Soni | Direct-Mapped Baseline*
  - *Lakshya Bapna | Two-Way Datapath Subsystem*
  - *Krishna Verma | Memory Model & Analytics*
- [ ] **Terminal Cuts**: Trim execution lag so terminal commands run cleanly without dead air.
- [ ] **Visual Clarity**: Code text must be sharp and legible even on mobile screens.
- [ ] **No Disclaimers Skipped**: Ensure the Phase I status is noted (RTL simulation complete; FPGA synthesis planned for Phase II).
- [ ] **Export Settings**: H.264 / MP4, High Profile, 20 Mbps CBR/VBR, AAC 320 kbps 48 kHz audio.
