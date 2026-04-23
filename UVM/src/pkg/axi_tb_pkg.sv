//------------------------------------------------------------------------------
// Package: axi_tb_pkg
//------------------------------------------------------------------------------
// Purpose:
//   Central compilation/namespace package for the AXI-only UVM testbench.
//   Include order matters: items → agents → env → sequences → tests.
//------------------------------------------------------------------------------

package axi_tb_pkg;
	
	import uvm_pkg::*;
	import apb2axi_memory_pkg::*;
     // -------------------------------------------------------------------------
     // Project-wide verbosity control
     // -------------------------------------------------------------------------
     int unsigned apb2axi_verbosity = UVM_DEBUG;

     `include "uvm_macros.svh"
     `include "pkg/defines.svh"

     function void axi_configure_verbosity();
          if ($test$plusargs("AXI_DEBUG")) begin
               apb2axi_verbosity = UVM_NONE;
               `uvm_info("AXI_TB_PKG", "AXI_DEBUG flag detected → quiet mode (UVM_NONE)", UVM_NONE);
          end
          else begin
               apb2axi_verbosity = UVM_DEBUG;
               `uvm_info("AXI_TB_PKG", "Defaulting to verbose mode (UVM_DEBUG)", UVM_DEBUG);
          end
     endfunction

     // ======================================================
     //  Sequence items  (referenced by everything below)
     // ======================================================
     `include "seq_item/axi_seq_item.sv"
	 
     // ======================================================
     //  AXI Agent
     // ======================================================
     `include "axi_driver.sv"
     `include "axi_monitor.sv"
     `include "axi_sequencer.sv"
     `include "axi_agent.sv"

     // ======================================================
     //  Environment
     // ======================================================
     `include "bfm/axi3_slave_bfm.sv"
     `include "axi_scoreboard.sv"
     `include "axi_env.sv"

     // ======================================================
     //  Sequences
     // ======================================================
     `include "axi_write_seq.sv"
     `include "axi_read_seq.sv"
     // --------------- ADD YOUR NEW SEQUENCES HERE ---------------

     // ======================================================
     //  Tests
     // ======================================================
     `include "axi_base_test.sv"
     `include "axi_test.sv"

endpackage
