# AXI-Bus-Protocol-Modules---Mini-Fabric
this is undargratuate project. we are implementing simple fabric with Arbitration and QoS that supports AXI3 protocol

## Repository Structure

```
src/
├── main/             — core SystemVerilog design files 
├── resources/        — third-party resources
└── test/             — modules' testbenches 

build_config.f        — file list of all units to compile and configuations
sim_exc.sh            — script to run and simulate the test_bench
run_verdi.sh          — script to run verdi and display the waveforms

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
