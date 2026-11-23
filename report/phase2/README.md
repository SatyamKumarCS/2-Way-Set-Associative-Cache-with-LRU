# Modern Computer Architecture — Phase II Final Academic Report

**Project Title:** Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache  
**Institution:** Department of Computer Science and Artificial Intelligence, Newton School of Technology  
**Authors:** Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, Lakshya Bapna  
**Repository:** https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git  

---

## 1. Directory Overview

This directory (`report/phase2/`) contains the complete, standalone **Phase II Final Academic Project Report** formatted in the official IEEE Conference template (`IEEEtran`).

| File | Description |
|---|---|
| [`ieee_phase2_final_report.tex`](ieee_phase2_final_report.tex) | Complete Phase II LaTeX source code conforming to two-column IEEE Conference format. |
| [`ieee_phase2_final_report.pdf`](ieee_phase2_final_report.pdf) | Compiled Phase II final academic paper with circuit diagrams, FSM transition graphs, and performance charts. |
| [`references_phase2.bib`](references_phase2.bib) | BibTeX database containing peer-reviewed, authentic computer architecture literature. |
| [`README.md`](README.md) | This Phase II documentation and compilation guide. |

> **Note on Academic Records:**  
> The Phase I academic submission remains completely intact and unmodified in the parent directory (`report/ieee_phase1_report.tex`, `report/ieee_phase1_report.pdf`, and `report/references.bib`). Phase I and Phase II are maintained as two independent reports.

---

## 2. Phase II Report Structure and Content

The Phase II final report covers all mandatory academic sections:

1. **Abstract & Index Terms**: Comprehensive summary of the microarchitectures, methodology, and empirical speedup under conflict-heavy access patterns.
2. **Section I — Introduction**: Theoretical motivation, the "memory wall", and Hill & Smith's 3C miss taxonomy (Compulsory, Capacity, Conflict).
3. **Section II — Related Work and Literature Review**: Classical literature review (Smith 1982, Hill & Smith 1989, Jouppi 1990, Smith & Goodman 1983, Hennessy & Patterson).
4. **Section III — Proposed Solution and Hardware Architecture**: Subsystem block diagrams, 32-bit address mapping (Tag/Index/Word/Byte), dual parallel 26-bit comparators, way multiplexing, and 1-bit LRU array.
5. **Section IV — Implementation Details**: Five-state Mealy/Moore cache FSM (`IDLE`, `LOOKUP`, `MEM_REQ`, `MEM_WAIT`, `RESP`), 4-word burst refill logic, synchronous memory model, and module inventory.
6. **Section V — Results and Discussion**: Detailed quantitative performance metrics from cycle-accurate RTL simulation across all four benchmark scenarios (Table II), 3-panel comparative performance charts (Fig. 5), cycle-by-cycle LRU trace table (Table III), and structural hardware comparison (Table IV).
7. **Section VI — Team Member Roles and Individual Engineering Contributions**: Detailed engineering responsibilities and verified artifacts for all five students.
8. **Section VII — Conclusion and Future Work**: Summary of findings and technical roadmap (Write policies, MSHRs, 4-way tree-PLRU, and physical FPGA synthesis on AMD/Xilinx Artix-7).
9. **References**: Six canonical, authentic peer-reviewed references with valid DOIs.

---

## 3. Key Technical Clarifications in Phase II

In accordance with rigorous academic standards, the Phase II report incorporates the following exact technical precision:

1. **Deterministic LRU Trace State Correction**:
   - In Scenario 3 ($A \to B \to A \to C \to A \to B$), at Step 6 accessing $B$ causes a miss.
   - Because Step 5 was a hit to Way 0 ($A$), the LRU bit pointed to Way 1 ($C$) as the replacement candidate.
   - Therefore, $B$ is refilled into Way 1, evicting $C$.
   - **Corrected Final State**: Way 0 contains $A$, Way 1 contains $B$, with $C$ evicted. Block $A$ remains resident throughout.
2. **Simulation Boundary vs. Physical Hardware**:
   - The report explicitly documents that **cycle-accurate RTL simulation was performed using Icarus Verilog (v12.0)**.
   - FPGA synthesis, placement, routing, and physical board programming were not performed in this phase.
3. **Simulated Memory Reads**:
   - Memory operations are described as **simulated main-memory word reads** from the synchronous memory simulation model (`sim/simple_main_memory.sv`), avoiding misleading claims of measured physical DRAM traffic.
4. **Execution Latency & Speedup Ratio**:
   - The metric of **64.29%** is precisely defined as a **reduction in measured execution latency** (140 cycles reduced to 50 cycles under conflict thrashing).
   - The corresponding speedup ratio is accurately stated as $\mathbf{2.80\times}$ ($140 / 50 = 2.80$).
5. **Scope of Set Associativity**:
   - The report precisely notes that two-way set associativity eliminates conflict misses between up to two concurrent memory blocks per set, but does not eliminate all conflict misses when three or more active lines compete for the same set, nor does it eliminate capacity misses.
6. **Structural Hardware Resources**:
   - Hardware comparisons are strictly grounded in structural RTL components (25-bit vs. 26-bit comparators, 200 vs. 208 tag bits, 0 vs. 4 replacement bits, multiplexer topology).

---

## 4. Compilation Instructions

The Phase II report can be recompiled using either `tectonic` or `pdflatex`:

### Option A: Using Tectonic (Recommended)
```bash
cd report/phase2
tectonic ieee_phase2_final_report.tex
```

### Option B: Using TeX Live / MacTeX (pdflatex + bibtex)
```bash
cd report/phase2
pdflatex -interaction=nonstopmode ieee_phase2_final_report.tex
bibtex ieee_phase2_final_report
pdflatex -interaction=nonstopmode ieee_phase2_final_report.tex
pdflatex -interaction=nonstopmode ieee_phase2_final_report.tex
```
