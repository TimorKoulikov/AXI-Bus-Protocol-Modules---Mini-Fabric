# AXI-Bus-Protocol-Modules---Mini-Fabric
this is undargratuate project. we are implementing simple fabric with Arbitration and QoS that supports AXI3 protocol

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

build_config.f        — file list of all units to compile and configuations
sim_exc.sh            — script to run and simulate the test_bench
run_verdi.sh          — script to run verdi and display the waveforms

```

## UVM enviroment
first of all thanks for @nirmiller31 for sharing with us his uvm setup.
go to https://github.com/nirmiller31/Project_A_apb2axi for his AXI project and his UVM.

[PLACE HOLDER IN THE FUTURE FOR HOW TO RUN SCRIPT]


## Progress

| Module         | Design | Validation | 
|----------------|--------|------------|
| ROB            |   alex |            | 
| receiver       |  DONE  |    DONE    |
| transmitter    |  DONE  |    DONE    | 
| patcher_ax     |  DONE  |    DONE    |
| patcher_x      |        |            |
| router_control |  DONE  |    DONE    | 
| arbiter_engine |  DONE  |    DONE    |
| router_ms      |  WIP   |    WIP     |
