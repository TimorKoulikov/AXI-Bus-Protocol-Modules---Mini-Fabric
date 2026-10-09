# AXI-Bus-Protocol-Modules---Mini-Fabric
This is an undergraduate project. 
We are implementing a simple fabric with Arbitration and QoS that supports AXI3 protocol

## Repository Structure

```
src/
├── main/             — core SystemVerilog design files 
├── resources/        — third-party resources
└── test/             — modules' testbenches 

UVM/		      — folder with all RTL, scripts for UVM environment 
├── src/	      — all RTL code
├── scripts/
└── tb_top.sv         — the TOP rtl block with monitors, driver and the FABRIC for testing

build_config.f        — file list of all units to compile and configurations
sim_exc.sh            — script to run and simulate the test_bench
run_verdi.sh          — script to run verdi and display the waveforms

```

## UVM enviroment
First of all thanks to @nirmiller31 for sharing with us his uvm setup.
Go to https://github.com/nirmiller31/Project_A_apb2axi for his AXI project and his UVM.

[PLACE HOLDER IN THE FUTURE FOR HOW TO RUN SCRIPT]


## uArch Progress

| Module          | Design | Testbench | 
|-----------------|--------|-----------|
| arbiter_control |not need|     -     |
| arbiter_engine  |   V    |     V     | 
| arbiter_ms      |   V    |     -     | 
| arbiter_rr      |   V    |     V     | 
| arbiter_sl      |   V    |     -     | 
| needy           |   V    |     V     | 
| patcher_ax      |   V    |     V     |
| patcher_w       |   V    |     V     |
| rob             |   V    |     V     | 
| router_control  |   V    |     V     | 
| router_ms       |   V    |     -     |
| router_sl       |   V    |     -     |
| token_counter   |   V    |     -     |


