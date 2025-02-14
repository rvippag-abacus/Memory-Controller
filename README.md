# Memory Controller

## Overview
This repository contains a **Memory Controller** design implemented in Verilog. The controller is responsible for managing memory transactions efficiently, ensuring proper read/write operations, and handling requests effectively.

## Features
- Supports basic memory read and write operations
- Implements an arbitration mechanism for handling multiple requests
- Designed for simulation and verification using **Icarus Verilog (iverilog)**
- Modular and scalable architecture for future enhancements

## Repository Structure
```
Memory-Controller/
│-- MEMORY_CONTROLLER.v   # Verilog implementation of the Memory Controller
│-- tb_MEMORY_CONTROLLER.v  # Testbench for verifying functionality
│-- README.md  # Documentation and instructions
│-- Makefile (optional)  # For automated compilation and simulation
```

## Installation & Setup
### **Dependencies**
Ensure you have the following installed:
- **Icarus Verilog (iverilog)** for simulation
- **GTKWave** (optional) for waveform viewing

### **Compilation & Simulation**
Run the following commands to compile and simulate the design:
```sh
# Compile the design and testbench
iverilog -o memory_controller_sim MEMORY_CONTROLLER.v tb_MEMORY_CONTROLLER.v

# Run the simulation
vvp memory_controller_sim

# View waveform (if dumped using $dumpfile)
gtkwave dumpfile.vcd
```

## Future Enhancements
- **L2 Cache Integration**: Implement a two-level caching system to optimize memory accesses.
- **HBM (High Bandwidth Memory) Support**: Extend the controller to work with **HBM-based architectures**.
- **AXI Interface**: Modify the controller to support **AXI transactions** for high-performance applications.

## Contributions
Contributions are welcome! Feel free to submit pull requests or report issues.

## Author
**rvippag-abacus** ([GitHub Profile](https://github.com/rvippag-abacus))

## License
Copyright (C) 2020-2025 Abacus Semiconductor Corporation.

