#!/bin/bash

# ==========================================
# Simple UVM Test Launcher
# ==========================================

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
SIMV="$SCRIPT_DIR/build/simv_uvm"
TESTNAME="axi_test_trace" # Change this if you name your test differently
LOGFILE="$SCRIPT_DIR/build/sim_trace.log"
VERBOSITY=UVM_HIGH

# Optional: Accept a trace file as an argument (e.g., ./reg_lunch.sh my_trace.txt)
TRACE_FILE=${1:-"UVM/traces/sanity_write.txt"}

echo "==========================================================="
echo " STARTING UVM TEST"
echo "==========================================================="
echo " Test Name  : $TESTNAME"
echo " Trace File : $TRACE_FILE"
echo " Log File   : $LOGFILE"
echo "==========================================================="

# Check if simv exists
if [ ! -f "$SIMV" ]; then
    echo "? ERROR: $SIMV not found! Please compile your project first."
    exit 1
fi

# Run the simulation
# We pass +TRACE_FILE=... so the SystemVerilog code knows which file to read!
$SIMV +UVM_TESTNAME=$TESTNAME +TRACE_FILE=$TRACE_FILE -l $LOGFILE \
	+fsdbfile+$BUILD_DIR/waves_uvm.fsdb  +UVM_VERBOSITY=$VERBOSITY

# Clean up generated files into the build directory
mv -f ucli.key tr_db.log axi_memory_dump.hex "$BUILD_DIR/" 2>/dev/null || true

# Check the log file for UVM_ERROR or UVM_FATAL where the count is >= 1
echo ""
echo "==========================================================="
if grep -qE "UVM_ERROR\s*:\s*[1-9]|UVM_FATAL\s*:\s*[1-9]" "$LOGFILE"; then
    echo " ? TEST FAILED (Found UVM_ERROR or UVM_FATAL in log)"
    echo "==========================================================="
    exit 1
else
    echo " TEST PASSED"
    echo "==========================================================="
    exit 0
fi
