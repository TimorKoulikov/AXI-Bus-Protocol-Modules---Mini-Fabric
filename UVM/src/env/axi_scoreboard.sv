//------------------------------------------------------------------------------
// AXI Scoreboard (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Collects observed AXI transactions from the monitor and checks that the
//   DUT behaved correctly.
//
// Current state:
//   Skeleton scoreboard  wires the AXI analysis stream into an internal FIFO
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

     // Exports for Master and Slave side monitors
     uvm_analysis_export #(axi_seq_item)     axi_mst_export[`NUM_OF_MASTERS];
     uvm_analysis_export #(axi_seq_item)     axi_slv_export[`NUM_OF_SLAVES];

     // Internal FIFOs buffer transactions
     uvm_tlm_analysis_fifo #(axi_seq_item)   axi_mst_fifo[`NUM_OF_MASTERS];
     uvm_tlm_analysis_fifo #(axi_seq_item)   axi_slv_fifo[`NUM_OF_SLAVES];

     // Symmetric Queues and Semaphore (for thread safety)
     axi_seq_item mst_q[$];
     axi_seq_item slv_q[$];
     semaphore    q_sem;

     function new(string name = "axi_scoreboard", uvm_component parent = null);
          super.new(name, parent);
          
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               axi_mst_export[i] = new($sformatf("axi_mst_export_%0d", i), this);
               axi_mst_fifo[i]   = new($sformatf("axi_mst_fifo_%0d", i), this);
          end
          
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               axi_slv_export[i] = new($sformatf("axi_slv_export_%0d", i), this);
               axi_slv_fifo[i]   = new($sformatf("axi_slv_fifo_%0d", i), this);
          end
          
          q_sem = new(1);
     endfunction

     function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               axi_mst_export[i].connect(axi_mst_fifo[i].analysis_export);
          end
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               axi_slv_export[i].connect(axi_slv_fifo[i].analysis_export);
          end
     endfunction

     task run_phase(uvm_phase phase);
          // Spawn a monitoring thread for each Master
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               automatic int mst_idx = i;
               fork
                    begin
                         axi_seq_item mst_tr;
                         forever begin
                              axi_mst_fifo[mst_idx].get(mst_tr);
                              `uvm_info("SCOREBOARD", $sformatf("[MASTER %0d] TXN in: addr=0x%0h data=0x%0h", mst_idx, mst_tr.addr, mst_tr.data), UVM_LOW)
                              
                              q_sem.get(1);
                              mst_q.push_back(mst_tr);
                              q_sem.put(1);
                         end
                    end
               join_none
          end

          // Spawn a checking thread for each Slave
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               automatic int slv_idx = i;
               fork
                    begin
                         axi_seq_item slv_tr;
                         forever begin
                              axi_slv_fifo[slv_idx].get(slv_tr);
                              `uvm_info("SCOREBOARD", $sformatf("[SLAVE %0d] TXN out: addr=0x%0h data=0x%0h", slv_idx, slv_tr.addr, slv_tr.data), UVM_LOW)
                              
                              q_sem.get(1);
                              slv_q.push_back(slv_tr);
                              q_sem.put(1);
                         end
                    end
               join_none
          end
     endtask

     function void check_phase(uvm_phase phase);
          int match_idx;
          int dropped_count = 0;
          
          super.check_phase(phase);
          
          `uvm_info("SCOREBOARD", "--- Starting Scoreboard Checks ---", UVM_LOW)
          
          // Check every Master transaction that went IN
          foreach (mst_q[i]) begin
               match_idx = -1;
               
               // Search the Slave outputs for a match
               for (int j = 0; j < slv_q.size(); j++) begin
                    if (slv_q[j].addr == mst_q[i].addr && slv_q[j].data == mst_q[i].data) begin
                         match_idx = j;
                         break;
                    end
               end
               
               if (match_idx != -1) begin
                    `uvm_info("SCOREBOARD", $sformatf("MATCH PASS! Master transaction (addr=0x%0h data=0x%0h) successfully came out of a Slave.", mst_q[i].addr, mst_q[i].data), UVM_LOW)
                    slv_q.delete(match_idx); // Remove from slave queue so we don't double-match
               end else begin
                    `uvm_error("SCOREBOARD", $sformatf("DROPPED DATA FAIL! Master transaction (addr=0x%0h data=0x%0h) entered the fabric but NEVER came out!", mst_q[i].addr, mst_q[i].data))
                    dropped_count++;
               end
          end
          
          // Any remaining items in the Slave queue are ghost transactions!
          if (slv_q.size() > 0) begin
               foreach (slv_q[j]) begin
                    `uvm_error("SCOREBOARD", $sformatf("GHOST DATA FAIL! Slave output unexpected data (addr=0x%0h data=0x%0h). We never sent this! (Possible double-pulsing bug in DUT)", slv_q[j].addr, slv_q[j].data))
               end
          end
          
          if (dropped_count == 0 && slv_q.size() == 0 && mst_q.size() > 0) begin
               `uvm_info("SCOREBOARD", "PERFECT MATCH! All transactions successfully routed through the fabric.", UVM_LOW)
          end else if (mst_q.size() == 0 && slv_q.size() == 0) begin
               `uvm_warning("SCOREBOARD", "NO TRANSACTIONS CAPTURED! The queues are empty.")
          end
          
          `uvm_info("SCOREBOARD", "--- Scoreboard Checks Complete ---", UVM_LOW)
     endfunction

endclass
