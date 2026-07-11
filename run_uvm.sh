#!/bin/bash
# Compile the AXI-only UVM testbench.
# PROJECT_HOME must be set to the UVM/ directory before running.
#
# Example:
#   export PROJECT_HOME=/path/to/project/UVM
#   ./compile_cmd

BUILD_DIR="build"
vcs -full64 -sverilog -ntb_opts uvm-1.2 -debug_access+all -f build_config.f -l $BUILD_DIR/comp.log -o $BUILD_DIR/simv_uvm \
-Mdir=$BUILD_DIR/csrc
