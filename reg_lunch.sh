#!/bin/bash

# ==========================================
# Simple UVM Test Launcher
# ==========================================

# Variables
SIMV="./simv"
TESTNAME="axi_test" # Change this if you name your test differently
LOGFILE="sim_trace.log"

# Optional: Accept a trace file as an argument (e.g., ./reg_lunch.sh my_trace.txt)
TRACE_FILE=${1:-"trace.txt"}

echo "==========================================================="
echo " ?? STARTING UVM TEST"
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
$SIMV +UVM_TESTNAME=$TESTNAME +TRACE_FILE=$TRACE_FILE -l $LOGFILE

# Check the log file for UVM_ERROR or UVM_FATAL where the count is >= 1
echo ""
echo "==========================================================="
if grep -qE "UVM_ERROR\s*:\s*[1-9]|UVM_FATAL\s*:\s*[1-9]" "$LOGFILE"; then
    echo " ? TEST FAILED (Found UVM_ERROR or UVM_FATAL in log)"
    echo "==========================================================="
    exit 1
else
    echo " ? TEST PASSED"
    echo "==========================================================="
    exit 0
fi
