#!/bin/bash
# run wave log

# the sim and log output directory
OUT_DIR="build"

# --- Argument Parsing ---
TARGET_TEST=""
for arg in "$@"; do
    case $arg in
        -test=*)
            TARGET_TEST="${arg#*=}"
            # Ensure it ends with _test to match the simv filename
            [[ ! "$TARGET_TEST" == *"_test" ]] && TARGET_TEST="${TARGET_TEST}_test"
            ;;
    esac
done
SIMV_EXE="./$OUT_DIR/simv_$TARGET_TEST"

export NOVAS_RC=$OUT_DIR/novas.rc
export NOVAS_CONF=$OUT_DIR/novas.conf
#create if doesnt exist
mkdir -p $OUT_DIR

#open verdi
$SIMV_EXE -gui \
	-l $OUT_DIR/sim_run.log \
	+fsdbfile+$OUT_DIR/inter.fsdb \
	+verdi_dir+$OUT_DIR/verdiLog \ 
#move the ucli.key to the build dirctory
mv ./ucli.key $OUT_DIR
mv ./novas* $OUT_DIR
