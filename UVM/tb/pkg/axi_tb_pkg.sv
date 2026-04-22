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
     `include "tb/pkg/defines.svh"

     function void axi_configure_verbosity();
          if ($test$plusargs("AXI_DEBUG")) begin
               apb2axi_verbosity = UVM_NONE;
               `uvm_info("AXI_TB_PKG", "AXI_DEBUG flag detected → quiet mode (UVM_NONE)", UVM_NONE)
          end
          else begin
               apb2axi_verbosity = UVM_DEBUG;
               `uvm_info("AXI_TB_PKG", "Defaulting to verbose mode (UVM_DEBUG)", UVM_DEBUG)
          end
     endfunction

     // ======================================================
     //  Sequence items  (referenced by everything below)
     // ======================================================
     `include "tb/seq_item/axi_seq_item.sv"

     // ======================================================
     //  AXI Agent
     // ======================================================
     `include "tb/agent/axi_driver.sv"
     `include "tb/agent/axi_monitor.sv"
     `include "tb/agent/axi_sequencer.sv"
     `include "tb/agent/axi_agent.sv"

     // ======================================================
     //  Environment
     // ======================================================
     `include "tb/bfm/axi3_slave_bfm.sv"
     `include "tb/env/axi_scoreboard.sv"
     `include "tb/env/axi_env.sv"

     // ======================================================
     //  Sequences
     // ======================================================
     `include "tb/seq/axi_write_seq.sv"
     `include "tb/seq/axi_read_seq.sv"
     // --------------- ADD YOUR NEW SEQUENCES HERE ---------------

     // ======================================================
     //  Tests
     // ======================================================
     `include "tb/tests/axi_base_test.sv"
     `include "tb/tests/axi_test.sv"

endpackage
