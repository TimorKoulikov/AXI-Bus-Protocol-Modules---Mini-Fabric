#!/bin/bash

# ==============================================================================
# AXI Fabric Regression Runner
# ==============================================================================
# Runs all traces in UVM/traces/ one by one using reg_lunch.sh.
# Displays an initial table with '?', updates the table after each run (PASS/FAIL),
# and prints a final summary of all pass/fail traces.
# Each trace has its own log file (build/sim_<name>.log) and waveform (build/waves_<name>.fsdb).
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACES_DIR="$SCRIPT_DIR/UVM/traces"
REG_LUNCH="$SCRIPT_DIR/reg_lunch.sh"
BUILD_DIR="$SCRIPT_DIR/build"
SIMV="$BUILD_DIR/simv_uvm"

# Options
QUIET=0
CLEAN_SCREEN=0

for arg in "$@"; do
    case "$arg" in
        -q|--quiet)   QUIET=1 ;;
        -c|--clear)   CLEAN_SCREEN=1 ;;
        -h|--help)
            echo "Usage: ./run_regression.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -q, --quiet      Suppress live simulation output from reg_lunch"
            echo "  -c, --clear      Clear screen between table updates"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
    esac
done

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if reg_lunch.sh exists
if [[ ! -f "$REG_LUNCH" ]]; then
    echo -e "${RED}[ERROR] reg_lunch.sh not found at: $REG_LUNCH${NC}"
    exit 1
fi

# Check if simv exists
if [[ ! -f "$SIMV" ]]; then
    echo -e "${RED}[ERROR] $SIMV not found! Please run ./compile_uvm.sh first.${NC}"
    exit 1
fi

# Discover all .txt trace files
TRACE_FILES=()
for f in "$TRACES_DIR"/*.txt; do
    [[ -f "$f" ]] && TRACE_FILES+=("$f")
done

if [[ ${#TRACE_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] No .txt trace files found in $TRACES_DIR${NC}"
    exit 1
fi

# Initialize test tracking arrays
TRACE_NAMES=()
TRACE_STATUSES=()
TRACE_LOGS=()
TRACE_WAVES=()

for f in "${TRACE_FILES[@]}"; do
    name=$(basename "$f" .txt)
    TRACE_NAMES+=("$name")
    TRACE_STATUSES+=("?")
    TRACE_LOGS+=("build/sim_${name}.log")
    TRACE_WAVES+=("build/waves_${name}.fsdb")
done

# Function to render the regression table
print_table() {
    local title="$1"

    if [[ $CLEAN_SCREEN -eq 1 ]]; then
        clear
    fi

    echo ""
    echo -e "${BOLD}====================================================${NC}"
    printf "  ${CYAN}%s${NC}\n" "$title"
    echo -e "${BOLD}====================================================${NC}"
    printf "| %-4s | %-30s | %-8s |\n" "#" "Trace Name" "Status"
    echo "+------+--------------------------------+----------+"

    for i in "${!TRACE_NAMES[@]}"; do
        local idx=$((i + 1))
        local name="${TRACE_NAMES[$i]}"
        local st="${TRACE_STATUSES[$i]}"

        printf "| %-4d | %-30s | " "$idx" "$name"

        if [[ "$st" == "PASS" ]]; then
            printf "${GREEN}%-8s${NC}" "PASS"
        elif [[ "$st" == "FAIL" ]]; then
            printf "${RED}%-8s${NC}" "FAIL"
        elif [[ "$st" == "RUN" ]]; then
            printf "${YELLOW}%-8s${NC}" "RUN..."
        else
            printf "${YELLOW}%-8s${NC}" "?"
        fi

        printf " |\n"
    done

    echo "+------+--------------------------------+----------+"
    echo ""
}

# 1. Print initial table with '?'
print_table "REGRESSION TEST PLAN (${#TRACE_NAMES[@]} TRACES)"

PASS_COUNT=0
FAIL_COUNT=0

# 2. Run each test one by one
for i in "${!TRACE_FILES[@]}"; do
    trace="${TRACE_FILES[$i]}"
    name="${TRACE_NAMES[$i]}"
    log="${TRACE_LOGS[$i]}"

    TRACE_STATUSES[$i]="RUN"
    echo -e "${BOLD}>>> [Test $((i + 1))/${#TRACE_FILES[@]}] Running: ${CYAN}${name}${NC}...${NC}"

    # Run reg_lunch.sh (shows output by default)
    if [[ $QUIET -eq 1 ]]; then
        bash "$REG_LUNCH" "$trace" > /dev/null 2>&1
        rc=$?
    else
        bash "$REG_LUNCH" "$trace"
        rc=$?
    fi

    # If reg_lunch.sh wrote to sim_trace.log instead of sim_${name}.log, copy it so each trace has its own log
    if [[ ! -f "$SCRIPT_DIR/$log" && -f "$BUILD_DIR/sim_trace.log" ]]; then
        cp -f "$BUILD_DIR/sim_trace.log" "$SCRIPT_DIR/$log"
    fi

    # Determine status:
    # reg_lunch.sh returns exit code 0 on PASS, 1 on FAIL.
    is_pass=0
    if [[ $rc -eq 0 ]]; then
        if [[ -f "$SCRIPT_DIR/$log" ]]; then
            if ! grep -qE "UVM_ERROR\s*:\s*[1-9]|UVM_FATAL\s*:\s*[1-9]" "$SCRIPT_DIR/$log"; then
                is_pass=1
            fi
        else
            is_pass=1
        fi
    fi

    if [[ $is_pass -eq 1 ]]; then
        TRACE_STATUSES[$i]="PASS"
        ((PASS_COUNT++))
        echo -e "    Result: ${GREEN}PASS${NC}"
    else
        TRACE_STATUSES[$i]="FAIL"
        ((FAIL_COUNT++))
        echo -e "    Result: ${RED}FAIL${NC}"
        # Print error summary from log if available
        if [[ -f "$SCRIPT_DIR/$log" ]]; then
            echo -e "    ${RED}Failure snippet from $log:${NC}"
            grep -E "UVM_ERROR|UVM_FATAL" "$SCRIPT_DIR/$log" | head -n 3 | sed 's/^/      /' || true
        fi
    fi

    # Re-print the table with updated status
    print_table "REGRESSION PROGRESS (COMPLETED $((i + 1))/${#TRACE_FILES[@]})"
done

# 3. Final Summary
echo -e "${BOLD}====================================================${NC}"
echo -e "  ${BOLD}FINAL REGRESSION REPORT${NC}"
echo -e "${BOLD}====================================================${NC}"
printf "  Total Tests Run : %d\n" "${#TRACE_NAMES[@]}"
printf "  ${GREEN}Passed${NC}          : %d\n" "$PASS_COUNT"
printf "  ${RED}Failed${NC}          : %d\n" "$FAIL_COUNT"
echo -e "${BOLD}====================================================${NC}"
echo ""

echo -e "${BOLD}Logs & Waveforms:${NC}"
for i in "${!TRACE_NAMES[@]}"; do
    tname="${TRACE_NAMES[$i]}"
    echo -e "  Logs of ${CYAN}${tname}${NC} can be found in ${BOLD}build/sim_${tname}.log${NC}"
    echo -e "  FSDB of ${CYAN}${tname}${NC} can be found in ${BOLD}build/waves_${tname}.fsdb${NC}"
done
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}${BOLD}FAILED TRACES:${NC}"
    for i in "${!TRACE_NAMES[@]}"; do
        if [[ "${TRACE_STATUSES[$i]}" == "FAIL" ]]; then
            echo -e "  - ${RED}${TRACE_NAMES[$i]}${NC} -> build/sim_${TRACE_NAMES[$i]}.log"
        fi
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}${BOLD}ALL TRACES PASSED SUCCESSFULLY!${NC}"
    echo ""
    exit 0
fi
