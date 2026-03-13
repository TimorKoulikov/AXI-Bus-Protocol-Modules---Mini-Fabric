#!/bin/bash

# the sim and log output directory
OUT_DIR="build"

#create if doesnt exist
mkdir -p $OUT_DIR

#run simulation
vcs -kdb -debug_access+all -full64\
	 -f build_config.f \
	-Mdir=$OUT_DIR/csrc \
	-o $OUT_DIR/simv \
	-l $OUT_DIR/compile.log


#open verdi
./$OUT_DIR/simv \
	-l $OUT_DIR/sim_run.log \
	+fsdbfile+$OUT_DIR/inter.fsdb \
	+verdi_dir+$OUT_DIR/verdiLog 

#move the ucli.key to the build dirctory
mv ./ucli.key $OUT_DIR
