# ==========================================================
#  AXI-Only UVM Testbench Filelist
# ==========================================================
#
# Usage:
#   vcs -full64 -sverilog -ntb_opts uvm-1.2 -debug_access+all -f filelist.f -l comp.log -o simv
#
# What to update per project:
#   - $PROJECT_HOME must point at the UVM/ directory root.
#   - Uncomment the DUT RTL section and add your design files.
#   - Adjust the DesignWare path if not used / path differs.
# ==========================================================

# === Global timescale ===
-timescale=1ns/1ps

# === Include Directories ===
+incdir+$UVM_HOME
+incdir+$PROJECT_HOME/tb
+incdir+$PROJECT_HOME/tb/pkg
+incdir+$PROJECT_HOME/tb/if
+incdir+$PROJECT_HOME/tb/env
+incdir+$PROJECT_HOME/tb/agent
+incdir+$PROJECT_HOME/tb/seq
+incdir+$PROJECT_HOME/tb/seq_item
+incdir+$PROJECT_HOME/tb/tests

# === DesignWare simulation models (remove if not needed) ===
-y /eda/synopsys/2024-25/RHELx86/SYN_2024.09-SP2/dw/sim_ver
+libext+.v

# ============================================================
# DUT / Design files  (uncomment and fill in for your project)
# ============================================================
// $PROJECT_HOME/../design/<your_dut_pkg>.sv
// $PROJECT_HOME/../design/<your_dut>.sv

# === AXI Interface ===
$PROJECT_HOME/tb/if/axi_if.sv

# === TB Package (includes all TB classes) ===
$PROJECT_HOME/tb/bfm/apb2axi_memory_pkg.sv
$PROJECT_HOME/tb/pkg/axi_tb_pkg.sv

# === Top ===
$PROJECT_HOME/tb/tb_top.sv
