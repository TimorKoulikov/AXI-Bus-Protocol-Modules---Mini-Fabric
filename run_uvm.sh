#!/bin/bash
# Compile the AXI-only UVM testbench.
# PROJECT_HOME must be set to the UVM/ directory before running.
#
# Example:
#   export PROJECT_HOME=/path/to/project/UVM
#   ./compile_cmd

BUILD_DIR="build"
OUT_DIR="build"

## compile the rtl
vcs -full64 -sverilog -ntb_opts uvm-1.2 -debug_access+all -f build_config.f -l $BUILD_DIR/comp.log -o $BUILD_DIR/simv_uvm \
-Mdir=$BUILD_DIR/csrc -l $OUT_DIR/compile_uvm.log \

## running the simulation
$BUILD_DIR/simv_uvm \
	-l $OUT_DIR/sim_uvm.log \
	+fsdbfile+$OUT_DIR/waves_uvm.fsdb 

mv ./ucli.key $OUT_DIR/ucli_uvm.key 2>/dev/null || true
