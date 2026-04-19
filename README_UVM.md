# ITA UVM Testbench with Coverage and Assertions

## Overview

This document describes the Universal Verification Methodology (UVM) testbench for the ITA (Transformer Accelerator) design, including comprehensive functional coverage and SystemVerilog assertions for thorough verification.

## Architecture

The UVM testbench follows a modular architecture with the following components:

### Testbench Components

- **`ita_uvm_pkg.sv`**: Main UVM package containing all testbench components
- **`ita_uvm_types.sv`**: Transaction classes for AXI4-Lite, AXI4, and ITA control transactions
- **`ita_uvm_config.sv`**: Configuration class managing virtual interfaces and test parameters
- **`ita_uvm_sequences.sv`**: Test sequences for control register writes, memory operations, and main ITA test flow
- **`ita_uvm_agents.sv`**: Complete AXI4-Lite and AXI4 agent implementations with drivers, monitors, and sequencers
- **`ita_uvm_env.sv`**: UVM environment coordinating the AXI agents
- **`ita_uvm_test.sv`**: Base and simple test classes
- **`ita_uvm_tb_module.sv`**: Top-level testbench module with DUT instantiation
- **`ita_coverage_assertions.sv`**: Functional coverage groups and SystemVerilog assertions

### Coverage Points

The testbench includes comprehensive functional coverage for:

#### State Machine Coverage (`cg_state_machine`)
- All state transitions (Idle → Q/K/V/QK/AV/OW/F1/F2/MatMul)
- State machine execution paths

#### Layer and Activation Coverage (`cg_layer_activation`)
- All layer types: Attention, Feedforward, Linear, SingleAttention
- All activation functions: Identity, Gelu, Relu
- Cross coverage between layers and activations

#### FIFO Usage Coverage (`cg_fifo_usage`)
- FIFO level coverage (empty, low, mid, high, full)
- FIFO full/empty state transitions
- FIFO mutex conditions

#### AXI4-Lite Protocol Coverage (`cg_axil_protocol`)
- Handshake coverage (valid/ready combinations)
- Response type coverage (OKAY, EXOKAY, SLVERR, DECERR)
- Address/data stability during stalls

#### AXI4 Memory Protocol Coverage (`cg_axi4_protocol`)
- Burst type coverage (FIXED, INCR, WRAP)
- Burst length coverage (1-255)
- Transfer size coverage (1-128 bytes)
- Response type coverage

#### Data Flow Coverage (`cg_data_flow`)
- Calculation enable coverage
- Tile boundary coverage (first/last inner tiles)
- Handshake coverage for all interfaces
- Busy/idle state coverage

### Assertions

The testbench includes SystemVerilog assertions for:

#### AXI4-Lite Protocol Assertions
- Address/data stability during stalls
- Valid response values
- Handshake protocol compliance

#### AXI4 Protocol Assertions
- Valid burst types and sizes
- WLAST timing for burst transfers
- RLAST timing for burst transfers

#### State Machine Assertions
- Valid state transitions
- No illegal state combinations
- Proper sequencing

#### FIFO Assertions
- No overflow/underflow conditions
- Full/empty mutex
- Proper usage bounds

#### Data Flow Assertions
- Input validity when calc_en is asserted
- Busy state implications
- Pipeline timing constraints

## Running the Testbench

### Prerequisites

- SystemVerilog simulator with UVM support (QuestaSim/ModelSim)
- UVM library installed and accessible

### Simulation Commands

```bash
# Set environment variables
export UVM_HOME=/path/to/uvm
export MODELSIM_DIR=/path/to/modelsim

# Make script executable and run
chmod +x run_uvm_tb.sh
./run_uvm_tb.sh
```

### Manual Simulation

```bash
# Create work library
vlib work
vmap work work

# Compile UVM
vlog -sv $UVM_HOME/src/uvm_pkg.sv +incdir+$UVM_HOME/src

# Compile design
vlog -sv src/ita_package.sv
vlog -sv src/ita*.sv

# Compile testbench
vlog -sv +incdir+src/tb +incdir+src +define+UVM src/tb/ita_uvm_pkg.sv
vlog -sv src/tb/ita_uvm_tb_module.sv

# Run simulation
vsim -c ita_uvm_tb +UVM_TESTNAME=ita_simple_test -do "run -all; quit"
```

## Coverage Analysis

After simulation, coverage results can be analyzed using the simulator's coverage tools:

```bash
# View coverage report
vsim -viewcov coverage.db
```

Key coverage metrics to monitor:
- State machine transitions: >90% coverage
- Layer/activation combinations: 100% coverage
- AXI protocol compliance: >95% coverage
- FIFO usage scenarios: >80% coverage
- Data flow paths: >85% coverage

## Assertions Monitoring

Assertions are automatically checked during simulation. Failed assertions will:
1. Generate error messages in the simulation log
2. Stop simulation (for fatal assertions) or continue with warnings
3. Provide detailed information about the failure condition

## Test Classes

### `ita_simple_test`
- Basic functionality test
- Configures ITA for a simple attention operation
- Verifies basic data flow and state transitions

### `ita_config_test`
- Configuration parameter validation
- Tests different tile sizes and layer configurations

### `ita_memory_test`
- Memory interface validation
- Tests AXI4 protocol compliance
- Validates data integrity through memory operations

## Extending the Testbench

### Adding New Tests
1. Create a new test class extending `ita_base_test`
2. Override `run_test_sequence()` method
3. Implement test-specific sequences in `ita_uvm_sequences.sv`

### Adding New Coverage
1. Define new covergroups in `ita_coverage_assertions.sv`
2. Sample coverage in appropriate clock domains
3. Add coverage sampling logic

### Adding New Assertions
1. Add assertion properties in `ita_coverage_assertions.sv`
2. Use appropriate assertion types (assert, assume, cover)
3. Ensure proper disable conditions for reset

## Files Structure

```
src/tb/
├── ita_uvm_pkg.sv              # Main package
├── ita_uvm_types.sv            # Transaction classes
├── ita_uvm_config.sv           # Configuration class
├── ita_uvm_sequences.sv        # Test sequences
├── ita_uvm_agents.sv           # AXI agents
├── ita_uvm_env.sv              # UVM environment
├── ita_uvm_test.sv             # Test classes
├── ita_uvm_tb_module.sv        # Top-level module
├── ita_coverage_assertions.sv  # Coverage & assertions
└── axi_memory.sv               # AXI memory model
```

## Troubleshooting

### Common Issues

1. **UVM Library Not Found**
   - Verify `UVM_HOME` environment variable
   - Check UVM installation

2. **Compilation Errors**
   - Ensure all source files are included
   - Check include paths

3. **Coverage Not Collected**
   - Enable coverage in simulation options
   - Check coverage database generation

4. **Assertions Not Triggering**
   - Verify reset conditions
   - Check clock domain alignment

### Debug Tips

- Use `+UVM_VERBOSITY=UVM_HIGH` for detailed logging
- Enable waveform dumping for signal analysis
- Use `vsim -gui` for interactive debugging</content>
<parameter name="filePath">d:\MSc\Purdue\69500\Project\ITA\src\tb\ita_uvm_tb_top.sv