# Define tools
IVERILOG = iverilog
GTKWAVE = gtkwave

# Define output files
SIM_EXE = memory_controller_sim
WAVEFORM_VCD = waveforms.vcd

# Define source files
RTL_DIR = rtl
TESTBENCH_DIR = testbench

RTL_FILES = $(RTL_DIR)/MEMORY_CONTROLLER.v

TESTBENCH_FILES = $(TESTBENCH_DIR)/tb_MEMORY_CONTROLLER.v

# Define simulation flags (optional)
SIM_FLAGS = -o $(WAVEFORM_VCD)

# Default target
all: sim

# Simulation target
sim: $(SIM_EXE)
        ./$(SIM_EXE) $(SIM_FLAGS)
        $(GTKWAVE) $(WAVEFORM_VCD)

# Compilation target
$(SIM_EXE): $(RTL_FILES) $(TESTBENCH_FILES)
        $(IVERILOG) -o $(SIM_EXE) -I $(RTL_DIR) $(RTL_FILES) $(TESTBENCH_FILES)

# Clean target (removes generated files)
clean:
        rm -f $(SIM_EXE) $(WAVEFORM_VCD)

.PHONY: all sim clean
