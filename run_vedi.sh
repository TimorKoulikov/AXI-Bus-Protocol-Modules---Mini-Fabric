#!/bin/bash

# the sim and log output directory
OUT_DIR="build"

export NOVAS_RC=$OUT_DIR/novas.rc
export NOVAS_CONF=$OUT_DIR/novas.conf
#create if doesnt exist
mkdir -p $OUT_DIR

#open verdi
./$OUT_DIR/simv -gui \
	-l $OUT_DIR/sim_run.log \
	+fsdbfile+$OUT_DIR/inter.fsdb \
	+verdi_dir+$OUT_DIR/verdiLog \ 
#move the ucli.key to the build dirctory
mv ./ucli.key $OUT_DIR
mv ./novas* $OUT_DIR
