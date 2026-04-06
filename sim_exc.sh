#!/bin/bash

OUT_DIR="build"
CONFIG_FILE="build_config.f"
mkdir -p $OUT_DIR

TESTS=$(grep -E "_(test|tb)\.sv" $CONFIG_FILE | sed 's/.*\/\(.*\)\.sv/\1/')

if [ -z "$TESTS" ]; then
    echo "Error: No testbench files (*_test.sv) found in $CONFIG_FILE"
    exit 1
fi

# Check for verbose flag
VERBOSE=0
if [[ "$1" == "-v" ]]; then
    VERBOSE=1
fi

for TEST_TOP in $TESTS
do
	echo "========================================"
    echo " STARTING TEST: $TEST_TOP"
    echo "========================================"
    
    if [ $VERBOSE -eq 1 ]; then
        # Verbose Mode: No -q, output to terminal
        vcs -full64 -sverilog -kdb -debug_access+all \
            -f $CONFIG_FILE \
            -top $TEST_TOP \
            -Mdir=$OUT_DIR/csrc_$TEST_TOP \
            -o $OUT_DIR/simv_$TEST_TOP \
            -l $OUT_DIR/compile_$TEST_TOP.log
    else
        # Quiet Mode: Uses -q and silences terminal output
        vcs -q -full64 -sverilog -kdb -debug_access+all \
            -f $CONFIG_FILE \
            -top $TEST_TOP \
            -Mdir=$OUT_DIR/csrc_$TEST_TOP \
            -o $OUT_DIR/simv_$TEST_TOP \
            -l $OUT_DIR/compile_$TEST_TOP.log &> /dev/null
    fi
    
    if [ $? -ne 0 ]; then
        echo "Compilation failed for $TEST_TOP"
        continue
    fi

    if [ $VERBOSE -eq 1 ]; then
        # Verbose Simulation
        ./$OUT_DIR/simv_$TEST_TOP \
            -l $OUT_DIR/sim_$TEST_TOP.log \
            +fsdbfile+$OUT_DIR/$TEST_TOP.fsdb 
    else
        # Quiet Simulation
        ./$OUT_DIR/simv_$TEST_TOP -q \
            -l $OUT_DIR/sim_$TEST_TOP.log \
            +fsdbfile+$OUT_DIR/$TEST_TOP.fsdb 
    fi
    
    grep -qEi "ERROR| FAIL" $OUT_DIR/sim_$TEST_TOP.log
	if [ $? -eq 0 ]; then
    	echo "========================================"
    	echo " TEST FAILED"
    	echo "========================================"
	fi

    mv ./ucli.key $OUT_DIR/ucli_$TEST_TOP.key
done