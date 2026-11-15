# Project 7 — 2-Way Set-Associative Cache with LRU

A Modern Computer Architecture project implementing and comparing:

1. An 8-line direct-mapped cache.
2. A 4-set, 2-way set-associative cache using LRU replacement.

Both caches have the same data capacity (128 bytes), line size (16 bytes), data width (32 bits), and address width (32 bits). They are evaluated using identical read-only memory traces.

## Team responsibilities

| Member | Files | Responsibility |
|---|---|---|
| 1 | `rtl/cache_pkg.sv`, `rtl/direct_mapped_cache.sv` | Shared constants and direct-mapped baseline |
| 2 | `rtl/cache_2way_datapath.sv` | Two-way storage, parallel tag lookup and data selection |
| 3 | `rtl/lru_controller.sv`, `rtl/cache_2way_controller.sv`, `rtl/cache_2way_top.sv` | LRU, FSM, refill control and integration |
| 4 | `sim/simple_main_memory.sv`, `tb/tb_cache_comparison.sv`, `analysis/analyze_results.py` | Memory model, verification and performance analysis |

See [`docs/architecture.md`](docs/architecture.md) and [`docs/interfaces.md`](docs/interfaces.md) before writing code.

## Agreed configuration

| Parameter | Value |
|---|---:|
| Address width | 32 bits |
| Data width | 32 bits |
| Cache line | 16 bytes = four 32-bit words |
| Total data capacity per cache | 128 bytes |
| Direct-mapped organization | 8 lines × 1 way |
| Two-way organization | 4 sets × 2 ways |
| Two-way replacement | One LRU bit per set |
| Access type | Read-only, word-aligned |
| Outstanding CPU requests | One per cache |

## Repository layout

```text
project-7-cache-lru/
├── rtl/
│   ├── cache_pkg.sv
│   ├── direct_mapped_cache.sv
│   ├── cache_2way_datapath.sv
│   ├── lru_controller.sv
│   ├── cache_2way_controller.sv
│   └── cache_2way_top.sv
├── sim/
│   └── simple_main_memory.sv
├── tb/
│   └── tb_cache_comparison.sv
├── analysis/
│   └── analyze_results.py
├── results/
├── docs/
│   ├── architecture.md
│   └── interfaces.md
└── README.md
```

## Tools

- Icarus Verilog (`iverilog` and `vvp`) for simulation.
- GTKWave for viewing `.vcd` waveforms (optional).
- Python 3 and Matplotlib for graphs.
- Vivado or Yosys for synthesis/resource analysis (optional, depending on available FPGA flow).

## Build and run

Run commands from the repository root after all RTL and testbench files have been added:

```bash
mkdir -p build
iverilog -g2012 -s tb_cache_comparison -o build/cache_sim \
  rtl/cache_pkg.sv \
  rtl/direct_mapped_cache.sv \
  rtl/cache_2way_datapath.sv \
  rtl/lru_controller.sv \
  rtl/cache_2way_controller.sv \
  rtl/cache_2way_top.sv \
  sim/simple_main_memory.sv \
  tb/tb_cache_comparison.sv

vvp build/cache_sim
```

The testbench should write measured data to `results/results.csv` (or another agreed path). Once `analysis/analyze_results.py` is implemented, run:

```bash
python3 analysis/analyze_results.py results/results.csv
```

The exact CSV path and column names must be agreed between Member 4's testbench and analysis script. Do not report made-up measurements.

## Git collaboration workflow

Do not commit directly to `main`. Each member should use a feature branch and open a pull request.

Suggested branches:

- `member-1/direct-mapped`
- `member-2/datapath`
- `member-3/controller-lru`
- `member-4/verification`

Typical commands:

```bash
git switch main
git pull origin main
git switch -c member-1/direct-mapped
# edit and test your assigned files
git add rtl/cache_pkg.sv rtl/direct_mapped_cache.sv
git commit -m "Add direct-mapped cache baseline"
git push -u origin member-1/direct-mapped
```

Then open a pull request on GitHub from your branch into `main`. Replace the branch name and file paths for your role. Before starting a new task, update your local `main` and merge/rebase the latest `main` into your feature branch.

## Definition of done

- All modules compile together with Icarus Verilog.
- Both caches receive the same ordered address traces.
- Returned data is checked against the memory model.
- Cold misses, repeated hits, conflict misses and LRU replacement are tested.
- Counters are checked against expected counts for deterministic traces.
- Hit rate, miss rate, memory reads and average latency are calculated from actual simulation output.
- Synthesis results are recorded only if a synthesis tool/target is available.

## Important design rules

1. Do not change agreed module names or port names without updating `docs/interfaces.md` and notifying all members.
2. A valid/ready transfer occurs only on a rising clock edge where both `valid` and `ready` are high.
3. Hold a response's `valid` and payload stable until the receiver accepts it.
4. Check invalid ways before evicting a valid line. Use LRU only when both ways in the selected set are valid.
5. Count one cache hit or miss per CPU request, not per refill word.
6. Count one memory word read per accepted memory request.
7. The memory model and testbench are simulation-only; keep them separate from synthesizable cache RTL.
