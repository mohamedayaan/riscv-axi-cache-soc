# RISC-V AXI Cache SoC

Simulation-only Mini SoC in Verilog — RISC-V Core + L1 Cache + AXI4 Interconnect + Memory.

## Team
| Member | Responsibility |
|--------|---------------|
| Member A | RISC-V Core + L1 Cache |
| Member B (Ayaan) | AXI4 Interconnect + Memory + Integration |

## Architecture
RISC-V Core → Cache (I/D/D
/D) → AXI4 Master → AXI4 Slave → Memory (16KB)
## Memory Map
| Region | Address | Size |
|--------|---------|------|
| Instruction | 0x0000_0000 – 0x0000_3FFF | 16KB |
| Data | 0x0000_4000 – 0x0000_7FFF | 16KB |
| Out of bounds | above 0x7FFF | SLVERR |

## How to Run

**AXI Unit Tests:**
```bash
iverilog -o sim/tb_axi.out rtl/axi/axi_master.v rtl/axi/axi_slave.v rtl/memory/mem_model.v rtl/soc_top/soc_top.v tb/axi/tb_axi.v
vvp sim/tb_axi.out
```

**Integration Test:**
```bash
iverilog -o sim/tb_soc.out rtl/axi/axi_master.v rtl/axi/axi_slave.v rtl/memory/mem_model.v rtl/cache/icache.v rtl/cache/dcache.v rtl/cache/cache_arbiter.v rtl/cache/cache_subsystem.v rtl/soc_top/soc_top.v tb/soc/tb_soc.v
vvp sim/tb_soc.out
```

**View Waveform:**
```bash
surfer sim/tb_soc.vcd
```

## Results
| Testbench | Tests | Result |
|-----------|-------|--------|
| tb_axi.v | 6 | ✅ 6/6 PASSED |
| tb_slverr.v | 2 | ✅ SLVERR working |
| tb_soc.v | 5 | ✅ 5/5 PASSED |

## Tools
- Icarus Verilog — simulation
- Surfer — waveform viewer
- Git — version control
