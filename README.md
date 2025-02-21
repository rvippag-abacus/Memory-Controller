# L1 and L2 Cache Controller

This repository contains a Verilog implementation of an L1 and L2 cache controller. It is designed to be simulated using Icarus Verilog (iverilog) and GTKWave.

## Overview

This project implements a two-level cache system (L1 and L2) to improve memory access performance. The cache controller handles memory requests from the CPU, managing data storage and retrieval in the caches. It supports both read and write operations and implements a **write-back policy** for L1 and a **write-through policy** for L2. A **round-robin replacement policy** is used for both L1 and L2.

## Features

- **Two-Level Cache Hierarchy:** Implements both L1 and L2 caches for improved performance.
- **Write-Back Policy (L1):** Modifications to data in L1 are initially written only to L1. Updates to main memory are delayed until the block is evicted.
- **Write-Through Policy (L2):** Writes to L2 are immediately propagated to main memory.
- **Round-Robin Replacement Policy:** A simple and efficient replacement policy for selecting blocks to evict.
- **Byte-Addressable:** Supports byte-level access to data within the cache blocks.
- **Verilog HDL:** Implemented in synthesizable Verilog for hardware implementation.
- **Simulation with Icarus Verilog and GTKWave:** Includes scripts and instructions for simulation and waveform viewing.

## Repository Structure

```
L1-L2-Cache-Controller/
├── rtl/                # Verilog RTL source files
│   ├── l1_cache.v
│   ├── l2_cache.v
│   ├── cache_controller.v
│   └── ... other Verilog files
├── testbench/           # Testbench files
│   ├── cache_testbench.v
│   └── ... other testbench files
├── sim/                 # Simulation scripts and output
│   ├── run_simulation.sh  # Script to run iverilog and generate waveforms
│   ├── waveforms.vcd     # Waveform dump file (generated after simulation)
│   └── ... other simulation related files
├── Makefile             # Makefile for easier compilation and simulation
└── README.md            # This file
```

## Prerequisites

- **Icarus Verilog (iverilog):** A Verilog simulator. Install it using your system's package manager:

  ```bash
  sudo apt-get install iverilog   # Debian/Ubuntu
  brew install icarus-verilog     # macOS
  ```

- **GTKWave:** A waveform viewer. Install it similarly:

  ```bash
  sudo apt-get install gtkwave   # Debian/Ubuntu
  brew install gtkwave           # macOS
  ```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/devadutt-github/L1-L2-Cache-Controller.git
cd L1-L2-Cache-Controller
```

### 2. Run Simulation

```bash
cd sim
./run_simulation.sh
```

### 3. View Waveforms

```bash
gtkwave waveforms.vcd
```

## Usage

The testbench (`testbench/cache_testbench.v`) provides examples of how to interact with the cache controller. You can modify this testbench to create your own test scenarios. The Makefile provides targets for running specific test scenarios if you create them.

## TODOs

- Implement a more sophisticated replacement policy (e.g., LRU).
- Add support for different cache sizes and block sizes (configurable parameters).
- Implement a bus interface.
- Implement cache coherence for multi-core.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

MIT License

## Author

**Devadutt** ([devadutt-github](https://github.com/devadutt-github))

