# IEEE Conference Project Report (Phase I Evaluation)

This directory contains the academic project report for the **Phase I evaluation** of our Modern Computer Architecture project:

> **"Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache"**

* **Official Authors**: Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, Lakshya Bapna  
* **Affiliation**: Department of Computer Science and Artificial Intelligence, Newton School of Technology  
* **GitHub Repository**: [https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git](https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git)

---

## 1. Directory Inventory & Deliverables

| File Name | Format | Role and Content Description |
|---|---|---|
| [`ieee_phase1_report.pdf`](ieee_phase1_report.pdf) | PDF (9 pages) | The final compiled academic report formatted in standard two-column IEEE Conference style (`IEEEtran`), incorporating system architecture diagrams, TikZ FSM diagrams, performance data tables, empirical comparison plots, and authentic citations. |
| [`ieee_phase1_report.tex`](ieee_phase1_report.tex) | LaTeX Source | The complete LaTeX source document containing all mathematical derivations, architectural descriptions, table formatting, and cross-references. |
| [`references.bib`](references.bib) | BibTeX Database | Verified bibliographic entries covering seminal computer architecture literature (Hennessy & Patterson, A. J. Smith, M. D. Hill, N. P. Jouppi, J. E. Smith). |
| [`README.md`](README.md) | Markdown | This guide: toolchain compilation instructions, confirmed author information, document architecture, and relationship between source files. |

---

## 2. Relationship Between Source Files and the Compiled PDF

```text
                  +--------------------------+
                  |  ieee_phase1_report.tex  |
                  |     (Document Logic)     |
                  +------------+-------------+
                               |
                               |  \bibliography{references}
                               v
                  +--------------------------+
                  |      references.bib      |
                  |  (Authentic Citations)   |
                  +------------+-------------+
                               |
                               |  \includegraphics{...}
                               v
                  +--------------------------+
                  |      results/*.png       |
                  |   (Performance Plots)    |
                  +------------+-------------+
                               |
        Tectonic / XeTeX / pdflatex + BibTeX Engine Passes
                               |
                               v
                  +--------------------------+
                  |  ieee_phase1_report.pdf  |
                  |   (IEEE Conference PDF)  |
                  +--------------------------+
```

1. **`ieee_phase1_report.tex`** defines the document class (`\documentclass[conference]{IEEEtran}`), packages (`amsmath`, `booktabs`, `tabularx`, `tikz`, `graphicx`, `url`), the 5-author header block, 6 structured sections, tables, and algorithmic state transitions.
2. **`references.bib`** provides authentic bibliographic metadata cited via `\cite{...}` commands in the `.tex` file. The BibTeX engine matches citation keys (`hennessy2017computer`, `smith1982cache`, `hill1989evaluating`, `jouppi1990improving`, `patterson2020riscv`, `smith1983instruction`) and renders numbered IEEE references (`[1]`, `[2]`, `[3]`, etc.).
3. **`results/*.png`** are dynamically pulled from `../results/` and embedded into the 3-panel comparative performance dashboard (Fig. 5).
4. **`ieee_phase1_report.pdf`** is the resulting publication-ready artifact.

---

## 3. Toolchain & Compilation Instructions

### Primary Method: Tectonic (Recommended)
**Tectonic** is an automated, modern TeX engine that resolves dependencies, downloads required packages on the fly, and automatically executes the requisite TeX and BibTeX passes:

```bash
# Execute from the repository root:
cd "/Users/chinmaysoni/MCA_project "

# Compile the document directly:
tectonic report/ieee_phase1_report.tex -o report/
```

### Alternative Method: `latexmk` (TeX Live / MacTeX)
If you have a full TeX Live or MacTeX installation installed locally:

```bash
cd report/
latexmk -pdf ieee_phase1_report.tex
latexmk -c  # Cleans temporary intermediate files
```

### Alternative Method: Manual Multi-Pass `pdflatex` + `bibtex`
```bash
cd report/
pdflatex ieee_phase1_report.tex
bibtex ieee_phase1_report
pdflatex ieee_phase1_report.tex
pdflatex ieee_phase1_report.tex
```

---

## 4. Confirmed Author Information & Engineering Responsibilities

### Official Authors & Institutional Affiliation
* **Authors**:
  1. Satyam Kumar
  2. Krishna Verma
  3. Akshit Vats
  4. Chinmay Soni
  5. Lakshya Bapna
* **Institution**: Department of Computer Science and Artificial Intelligence, Newton School of Technology

### Work Package Allocation (Verified from Git Repository Records)
The five authors collaborate across four primary technical RTL/simulation work packages alongside cross-functional verification and reporting:

| Author | Role Identifier | Assigned Module / Focus | Verified Git Deliverables |
|---|---|---|---|
| **Chinmay Soni** | Member 1 | Direct-Mapped Cache Baseline & Common Package | `rtl/cache_pkg.sv`, `rtl/direct_mapped_cache.sv`, `tb/tb_direct_mapped.sv` |
| **Lakshya Bapna** | Member 2 | Two-Way Datapath Subsystem & Verification | `rtl/cache_2way_datapath.sv`, `tb/tb_cache_2way_datapath.sv` |
| **Satyam Kumar** | Member 3 | LRU Controller, Cache FSM & Top Integration | `rtl/lru_controller.sv`, `rtl/cache_2way_controller.sv`, `rtl/cache_2way_top.sv`, `tb/tb_lru_controller.sv`, `tb/tb_cache_2way_smoke.sv` |
| **Krishna Verma** | Member 4 | Memory Model, Comparison TB & Analytics | `sim/simple_main_memory.sv`, `tb/tb_cache_comparison.sv`, `analysis/analyze_results.py`, `results/results.csv`, `results/*.png` |
| **Akshit Vats** | Member 5 | Verification Support & Documentation | Synthetic benchmark validation, hardware invariant verification, results auditing, and IEEE report preparation (subject to human team confirmation) |

---

## 5. Report Document Architecture

The compiled report spans **9 pages** and is organized into the following sections:

1. **Title & Abstract (Page 1)**:
   - High-density abstract outlining the memory wall problem, architectural configuration (128B, 16B lines, 32b words), and key quantitative results (75% hit rate vs 0% on thrashing, 75% memory traffic reduction, 64.3% latency reduction).
   - Author block: Satyam Kumar, Krishna Verma, Akshit Vats, Chinmay Soni, and Lakshya Bapna (Department of Computer Science and Artificial Intelligence, Newton School of Technology).
   - Index terms: *Cache memory, set-associative cache, direct-mapped cache, least recently used (LRU) replacement, conflict misses, cache thrashing, memory hierarchy, SystemVerilog RTL.*
2. **Section I: Introduction (Pages 1–2)**:
   - Memory wall background and principle of locality.
   - The 3C model: Compulsory (cold), Capacity, and Conflict misses.
   - Architectural trade-offs between direct-mapped simplicity and set-associative conflict resistance.
   - Open-source repository link: `https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git`.
3. **Section II: Related Work & Literature Review (Page 2)**:
   - Foundational literature survey: Alan J. Smith (1982), Hill & Smith (1989), Jouppi (1990), Patterson & Hennessy (2020), Smith & Goodman (1983).
4. **Section III: Proposed Hardware Architecture & Implementation (Pages 2–5)**:
   - **Fig. 1**: End-to-end system architectural block diagram.
   - **Table I**: Comprehensive microarchitectural parameter comparison.
   - **Fig. 2**: 32-bit address field decomposition comparison.
   - **Fig. 3**: 2-Way set-associative datapath microarchitecture with parallel comparators and multiplexing.
   - **1-Bit LRU Replacement**: Mathematical formulation, 0/1 candidate convention, and invalid-first priority.
   - **Fig. 4**: 5-state cache control FSM state transition diagram.
   - **Table II**: SystemVerilog module inventory.
5. **Section IV: Team Member Roles & Individual Contributions (Pages 5–6)**:
   - **Table III**: Detailed technical responsibilities, deliverables, and verified artifacts across all five team members.
6. **Section V: Experimental Results & Comparative Performance Analysis (Pages 6–8)**:
   - **Fig. 5**: 3-panel comparative performance charts (Hit Rate, Average Access Latency, Total Memory Reads).
   - **Table IV**: Measured simulation metrics across all 4 synthetic benchmarks from `results/results.csv`.
   - In-depth scenario analyses: Sequential Locality, Conflict Thrashing Elimination, Deterministic LRU Eviction Proof ($A \to B \to A \to C \to A \to B$), and Mixed Workload.
   - **Table V**: Cycle-by-cycle trace of Scenario 3 LRU eviction dynamics.
   - **Table VI & Implementation Note**: Hardware complexity breakdown (comparators, multiplexers, flip-flops) and explicit note stating that RTL simulation was completed while physical FPGA synthesis was not performed.
7. **Section VI: Conclusion & Phase II Roadmap (Pages 8–9)**:
   - Summary of Phase I findings.
   - Technical roadmap: Write-through/write-back policies, dirty bits, non-blocking MSHR support, and Artix-7 FPGA synthesis.
8. **References (Page 9)**:
   - Six verified academic references rendered in standard IEEE format.
