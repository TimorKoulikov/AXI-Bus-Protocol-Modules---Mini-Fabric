#!/bin/bash
# compile rtl and run the tests
OUT_DIR="build"
CONFIG_FILE="build_config.f"
TESTLIST="src/tb_list.f"
RTLLIST="src/rtl_list.f"
mkdir -p $OUT_DIR

#check if FILELIST exists
if [ ! -f "$TESTLIST" ]; then
	echo "ERROR: $TESTLIST not found."
	exit 1
fi

# Parse arguments for Verbose (-v) and Specific Test (-t / --test)
VERBOSE=0
SPECIFIC_TEST=""

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -v                  Enable verbose compilation/output"
    echo "  -t, --test NAME     Run a specific test"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                  Run all tests"
    echo "  $0 -v               Run all tests with verbose output"
    echo "  $0 -t axi_test      Run only axi_test"
}

VERBOSE=0
SPECIFIC_TEST=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v)
            VERBOSE=1
            ;;
        -t|--test)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a test name."
                usage
                exit 1
            fi
            SPECIFIC_TEST="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            echo
            usage
            exit 1
            ;;
    esac
    shift
done

# Filter the test list
if [ -n "$SPECIFIC_TEST" ]; then
    # Look for the specific test file in the tb_list.f
    TESTS=$(grep -E "${SPECIFIC_TEST}\.sv" $TESTLIST )
    if [ -z "$TESTS" ]; then
        echo "Error: Test '${SPECIFIC_TEST}.sv' not found in $TESTLIST"
        exit 1
    fi
else
    # Default behavior: run all tests
    TESTS=$(grep -E "_(test|tb)\.sv" $TESTLIST ) 
fi

if [ -z "$TESTS" ]; then
    echo "Error: No testbench files (*_test.sv) found in $CONFIG_FILE"
    exit 1
fi

for TEST_TOP in $TESTS
do
	TEST_TOP=$(basename "$TEST_TOP" .sv)

    	echo "========================================"
	echo " STARTING TEST: $TEST_TOP"
	echo "========================================"
    
    if [ $VERBOSE -eq 1 ]; then
        # Verbose Mode: No -q, output to terminal
        vcs -full64 -sverilog -kdb -debug_access+all \
            -f $RTLLIST \
            -f $TESTLIST \
            -top $TEST_TOP \
            -Mdir=$OUT_DIR/csrc_$TEST_TOP \
            -o $OUT_DIR/simv_$TEST_TOP \
            -l $OUT_DIR/compile_$TEST_TOP.log \
	    +lint=TFIPC-L
    else
        # Quiet Mode: Uses -q and silences terminal output
        vcs -q -full64 -sverilog -kdb -debug_access+all \
            -f $RTLLIST \
	        -f $TESTLIST \
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
            +fsdbfile+$OUT_DIR/$TEST_TOP.fsdb \
	    
		
 
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
	else
    		echo "========================================"
    		echo " TEST PASSED"
    		echo "========================================"
	fi

    # Suppress errors if ucli.key isn't generated
    mv ./ucli.key $OUT_DIR/ucli_$TEST_TOP.key 2>/dev/null || true
done
