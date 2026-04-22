//------------------------------------------------------------------------------
// AXI Scoreboard (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Collects observed AXI transactions from the monitor and checks that the
//   DUT behaved correctly.
//
// Current state:
//   Skeleton scoreboard — wires the AXI analysis stream into an internal FIFO
//   and prints captured transactions. Add matching/data-checking logic here.
//
// How to turn this into a real checker:
//   1) Compare write data with a reference memory model expectation.
//   2) Check read data matches what was previously written (per address / ID).
//   3) Verify AXI response codes (BRESP/RRESP).
//   4) Add watchdog timeouts for unacknowledged transactions.
//------------------------------------------------------------------------------

class axi_scoreboard extends uvm_component;

     `uvm_component_utils(axi_scoreboard)

     // Export is the "input" of the scoreboard: AXI monitor connects here.
     uvm_analysis_export #(axi_seq_item)     axi_export;

     // Internal FIFO buffers transactions so checking logic runs at its own pace.
     uvm_tlm_analysis_fifo #(axi_seq_item)   axi_fifo;

     function new(string name = "axi_scoreboard", uvm_component parent = null);

          super.new(name, parent);

          axi_export                         = new("axi_export", this);
          axi_fifo                           = new("axi_fifo", this);

     endfunction

     function void connect_phase(uvm_phase phase);

          super.connect_phase(phase);

          // Route incoming transactions into the internal FIFO.
          axi_export.connect(axi_fifo.analysis_export);

     endfunction

     task run_phase(uvm_phase phase);

          axi_seq_item axi_tr;

          forever begin

               // Non-blocking poll: avoids deadlock if the bus is temporarily quiet.
               // Replace with blocking get + timeout for a production scoreboard.
               if (axi_fifo.try_get(axi_tr))
                    `uvm_info("SCOREBOARD", $sformatf("AXI TXN captured: %s", axi_tr.convert2string()), apb2axi_verbosity)

               // Small delay prevents a zero-time busy loop.
               #1ns;
          end
     endtask

endclass
