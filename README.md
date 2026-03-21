# AXI-Bus-Protocol-Modules---Mini-Fabric
this is undargratuate project. we are implementing simple fabric with Arbitration and QoS that supports AXI3 protocol

## Repository Structure

```
src/
├── main/
│   ├── hdl/          — core Verilog/SystemVerilog design files
│   └── resources/    — build scripts and third-party resources
└── test/
    ├── hdl/          — SystemVerilog testbench files
    └── resources/    — simulation scripts and supporting files
sim_exc.sh            - script to run and simulate the test_bench
build_config.f        - file list of all units to compile and configuations

```

## Progress

| Module | Design | Validation | 
|---|---|---|
| ROB | | | 
| receiver |DONE| DONE|
| transmitter |DONE | DONE| 
| patcher_ax | WIP |WIP |
| patcher_x | | 
| ms_controller | | | 
| sl_controller | | | 
| arbiter_engine | | | 
