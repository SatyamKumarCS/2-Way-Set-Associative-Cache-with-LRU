# 5-Person Project Demonstration Video Script
**Modern Computer Architecture — Phase I Project**

- **Project Title:** Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache
- **Institution:** Department of Computer Science and Artificial Intelligence, Newton School of Technology
- **Repository:** https://github.com/chinmay7980/2-Way-Set-Associative-Cache-with-LRU.git
- **Target Duration:** ~4 minutes 45 seconds (approx. 50–55 seconds per speaker)

---

### Person 1: Satyam Kumar
**Topic:** Project Overview, Team Introduction & Architectural Problem Statement

"Hello everyone. I am Satyam Kumar, representing our team from the Department of Computer Science and Artificial Intelligence at Newton School of Technology. Alongside my teammates Chinmay Soni, Lakshya Bapna, Krishna Verma, and Akshit Vats, I am presenting our Modern Computer Architecture Phase I project: *Design and Performance Analysis of a Two-Way Set-Associative Cache with LRU Replacement Compared with a Direct-Mapped Cache*. As modern processor clock rates outpace off-chip DRAM access times, the memory wall becomes the primary bottleneck in system throughput. Caches bridge this gap using spatial and temporal locality. While direct-mapped caches offer minimal latency and simple hardware, they suffer severely from conflict thrashing. To evaluate and quantify this tradeoff, we designed, integrated, and verified both a direct-mapped baseline and a 2-way set-associative cache with 1-bit Least Recently Used replacement using cycle-accurate SystemVerilog RTL."

---

### Person 2: Chinmay Soni
**Topic:** Direct-Mapped Baseline Architecture & Conflict Miss Vulnerability

"Hello, I am Chinmay Soni. I implemented the direct-mapped cache baseline and the unified system package `cache_pkg.sv`. Our baseline cache has a total capacity of 128 bytes organized into 8 cache lines, with 4 words—or 16 bytes—per block. For any 32-bit CPU byte address, the lower 2 bits serve as byte offsets, bits 3 down to 2 select the word, bits 6 down to 4 index one of the 8 lines, and the upper 25 bits form the tag. During a lookup, the indexed line's valid bit and stored tag are evaluated with a single 25-bit comparator. On a hit, data is returned to the CPU in a single clock cycle. On a miss, our blocking FSM coordinates a 4-word burst refill from main memory. Although this architecture requires minimal silicon area, any two active addresses mapping to the identical 3-bit index repeatedly overwrite each other, causing destructive ping-pong conflict misses."

---

### Person 3: Lakshya Bapna
**Topic:** 2-Way Set-Associative Datapath & 1-Bit LRU Replacement Policy

"Hello, I am Lakshya Bapna. To solve this conflict thrashing problem, I designed the datapath and replacement logic for our 2-way set-associative cache. Maintaining an identical 128-byte total capacity and 16-byte line size, we restructured the storage into 4 sets with 2 ways per set. Here, bits 5 down to 4 select the set, while the upper 26 bits serve as the tag. During lookup, two parallel 26-bit comparators simultaneously check Way 0 and Way 1, enabling two different cache lines with conflicting set indexes to reside in memory at the same time. On a hit, a multiplexer selects the winning way and updates our 1-bit LRU tracking bit for that set. On a miss, our controller prioritizes empty invalid ways first; if both ways are valid, the line pointed to by the LRU bit is evicted. This maintains critical working sets in cache without increasing total capacity."

---

### Person 4: Krishna Verma
**Topic:** Verification Environment, Memory Model & Cycle-Accurate Trace Walkthrough

"Hello, I am Krishna Verma. I developed the deterministic main memory model and our cycle-accurate comparative testbench, `tb_cache_comparison.sv`. Because both caches share identical CPU and memory handshake interfaces, we execute identical instruction traces in parallel against both architectures in Icarus Verilog. Main memory features realistic multi-cycle latencies, taking 5 cycles for the initial access and 2 cycles for each subsequent burst word. In our dedicated LRU validation test—accessing memory blocks A, B, A, C, A, and B—blocks A and B initially occupy Way 0 and Way 1. When address C arrives, it maps to the same set. Because block A was just accessed, our LRU controller correctly identifies block B as the least recently used, evicting B while preserving A. Consequently, the subsequent access to A hits instantly, demonstrating exact, cycle-accurate LRU behavior."

---

### Person 5: Akshit Vats
**Topic:** Empirical Benchmark Analysis, Phase I Status & Conclusion

"Hello, I am Akshit Vats. I analyzed the empirical simulation metrics exported to our results CSV and generated the comparative performance charts. For sequential streaming access, both caches achieved an identical 75% hit rate across 27 clock cycles. However, under alternating conflict access patterns, the direct-mapped cache suffered complete thrashing with a 0% hit rate, requiring 32 memory reads and 140 cycles. In stark contrast, the 2-way set-associative cache achieved a 75% hit rate, taking only 50 cycles. This delivers a massive 75% reduction in off-chip memory traffic and a 64.29% reduction in total execution latency. For Phase I, we completed RTL functional verification and testbench validation; physical FPGA synthesis remains planned for Phase II. All source code and documentation are available on our GitHub repository. Thank you!"
