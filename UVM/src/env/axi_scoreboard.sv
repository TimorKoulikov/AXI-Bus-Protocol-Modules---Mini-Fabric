//------------------------------------------------------------------------------
// AXI Scoreboard (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Collects observed AXI transactions from the monitor and checks that the
//   DUT behaved correctly.
//
// Current state:
//   Skeleton scoreboard ? wires the AXI analysis stream into an internal FIFO
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

     // REF inputs from Reference Model per-port
     uvm_analysis_export #(axi_seq_item)     ref_mst_export[`NUM_OF_MASTERS];
     uvm_analysis_export #(axi_seq_item)     ref_slv_export[`NUM_OF_SLAVES];
     uvm_tlm_analysis_fifo #(axi_seq_item)   ref_mst_fifo[`NUM_OF_MASTERS];
     uvm_tlm_analysis_fifo #(axi_seq_item)   ref_slv_fifo[`NUM_OF_SLAVES];

     // DUT inputs from all monitors per-port
     uvm_analysis_export #(axi_seq_item)     mst_export[`NUM_OF_MASTERS];
     uvm_analysis_export #(axi_seq_item)     slv_export[`NUM_OF_SLAVES];
     uvm_tlm_analysis_fifo #(axi_seq_item)   mst_fifo[`NUM_OF_MASTERS];
     uvm_tlm_analysis_fifo #(axi_seq_item)   slv_fifo[`NUM_OF_SLAVES];

     // Queues for final checking
     axi_seq_item ref_mst_q[`NUM_OF_MASTERS][$];
     axi_seq_item dut_mst_q[`NUM_OF_MASTERS][$];
     axi_seq_item ref_slv_q[`NUM_OF_SLAVES][$];
     axi_seq_item dut_slv_q[`NUM_OF_SLAVES][$];
     semaphore    q_sem;

     function new(string name = "axi_scoreboard", uvm_component parent = null);
          super.new(name, parent);
          
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               ref_mst_export[i] = new($sformatf("ref_mst_export_%0d", i), this);
               ref_mst_fifo[i]   = new($sformatf("ref_mst_fifo_%0d", i), this);
               mst_export[i]     = new($sformatf("mst_export_%0d", i), this);
               mst_fifo[i]       = new($sformatf("mst_fifo_%0d", i), this);
          end
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               ref_slv_export[i] = new($sformatf("ref_slv_export_%0d", i), this);
               ref_slv_fifo[i]   = new($sformatf("ref_slv_fifo_%0d", i), this);
               slv_export[i]     = new($sformatf("slv_export_%0d", i), this);
               slv_fifo[i]       = new($sformatf("slv_fifo_%0d", i), this);
          end
          
          q_sem = new(1);
     endfunction

     function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               ref_mst_export[i].connect(ref_mst_fifo[i].analysis_export);
               mst_export[i].connect(mst_fifo[i].analysis_export);
          end
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               ref_slv_export[i].connect(ref_slv_fifo[i].analysis_export);
               slv_export[i].connect(slv_fifo[i].analysis_export);
          end
     endfunction

     task run_phase(uvm_phase phase);
          
          // Threads: Collect expected outputs from Master ports
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               automatic int mst_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              ref_mst_fifo[mst_idx].get(tr);
                              `uvm_info("SCOREBOARD", $sformatf("[REF MASTER %0d] Expected TXN in: %s beat", mst_idx, tr.ch_type.name()), UVM_LOW)
                              q_sem.get(1);
                              ref_mst_q[mst_idx].push_back(tr);
                              q_sem.put(1);
                         end
                    end
               join_none
          end

          // Threads: Collect expected outputs from Slave ports
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               automatic int slv_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              ref_slv_fifo[slv_idx].get(tr);
                              `uvm_info("SCOREBOARD", $sformatf("[REF SLAVE %0d] Expected TXN in: %s beat", slv_idx, tr.ch_type.name()), UVM_LOW)
                              q_sem.get(1);
                              ref_slv_q[slv_idx].push_back(tr);
                              q_sem.put(1);
                         end
                    end
               join_none
          end

          // Threads: Collect actual DUT outputs from Master ports (B, R)
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               automatic int mst_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              mst_fifo[mst_idx].get(tr);
                              if (tr.ch_type == B || tr.ch_type == R) begin
                                   `uvm_info("SCOREBOARD", $sformatf("[DUT MASTER %0d] TXN out: %s beat", mst_idx, tr.ch_type.name()), UVM_LOW)
                                   q_sem.get(1);
                                   dut_mst_q[mst_idx].push_back(tr);
                                   q_sem.put(1);
                              end
                         end
                    end
               join_none
          end

          // Threads: Collect actual DUT outputs from Slave ports (AW, W, AR)
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               automatic int slv_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              slv_fifo[slv_idx].get(tr);
                              if (tr.ch_type == AW || tr.ch_type == W || tr.ch_type == AR) begin
                                   `uvm_info("SCOREBOARD", $sformatf("[DUT SLAVE %0d] TXN out: %s beat", slv_idx, tr.ch_type.name()), UVM_LOW)
                                   q_sem.get(1);
                                   dut_slv_q[slv_idx].push_back(tr);
                                   q_sem.put(1);
                              end
                         end
                    end
               join_none
          end
     endtask

     function void check_phase(uvm_phase phase);
          int match_idx;
          int dropped_count = 0;
          int ghost_count = 0;
          
          super.check_phase(phase);
          `uvm_info("SCOREBOARD", "--- Starting Scoreboard REF vs DUT Strict Port Checks ---", UVM_LOW)
          
          // Check SLAVE ports
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               foreach (ref_slv_q[i][k]) begin
                    match_idx = -1;
                    for (int j = 0; j < dut_slv_q[i].size(); j++) begin
                         if (dut_slv_q[i][j].ch_type == ref_slv_q[i][k].ch_type && 
                             dut_slv_q[i][j].addr == ref_slv_q[i][k].addr && 
                             dut_slv_q[i][j].data == ref_slv_q[i][k].data && 
                             dut_slv_q[i][j].id == ref_slv_q[i][k].id) begin
                              match_idx = j;
                              break;
                         end
                    end
                    if (match_idx != -1) begin
                         `uvm_info("SCOREBOARD", $sformatf("MATCH PASS! Slave %0d correctly output %s beat (id=%0d)", i, ref_slv_q[i][k].ch_type.name(), ref_slv_q[i][k].id), UVM_LOW)
                         dut_slv_q[i].delete(match_idx); 
                    end else begin
                         `uvm_error("SCOREBOARD", $sformatf("DROPPED DATA FAIL! Slave %0d was expected to output %s beat (id=%0d) but didn't!", i, ref_slv_q[i][k].ch_type.name(), ref_slv_q[i][k].id))
                         dropped_count++;
                    end
               end
               if (dut_slv_q[i].size() > 0) begin
                    foreach (dut_slv_q[i][j]) begin
                         `uvm_error("SCOREBOARD", $sformatf("GHOST DATA FAIL! Slave %0d generated unexpected %s beat (id=%0d).", i, dut_slv_q[i][j].ch_type.name(), dut_slv_q[i][j].id))
                         ghost_count++;
                    end
               end
          end
          
          // Check MASTER ports
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               foreach (ref_mst_q[i][k]) begin
                    match_idx = -1;
                    for (int j = 0; j < dut_mst_q[i].size(); j++) begin
                         if (dut_mst_q[i][j].ch_type == ref_mst_q[i][k].ch_type && 
                             dut_mst_q[i][j].addr == ref_mst_q[i][k].addr && 
                             dut_mst_q[i][j].data == ref_mst_q[i][k].data && 
                             dut_mst_q[i][j].id == ref_mst_q[i][k].id) begin
                              match_idx = j;
                              break;
                         end
                    end
                    if (match_idx != -1) begin
                         `uvm_info("SCOREBOARD", $sformatf("MATCH PASS! Master %0d correctly output %s beat (id=%0d)", i, ref_mst_q[i][k].ch_type.name(), ref_mst_q[i][k].id), UVM_LOW)
                         dut_mst_q[i].delete(match_idx); 
                    end else begin
                         `uvm_error("SCOREBOARD", $sformatf("DROPPED DATA FAIL! Master %0d was expected to output %s beat (id=%0d) but didn't!", i, ref_mst_q[i][k].ch_type.name(), ref_mst_q[i][k].id))
                         dropped_count++;
                    end
               end
               if (dut_mst_q[i].size() > 0) begin
                    foreach (dut_mst_q[i][j]) begin
                         `uvm_error("SCOREBOARD", $sformatf("GHOST DATA FAIL! Master %0d generated unexpected %s beat (id=%0d).", i, dut_mst_q[i][j].ch_type.name(), dut_mst_q[i][j].id))
                         ghost_count++;
                    end
               end
          end
          
          if (dropped_count == 0 && ghost_count == 0) begin
               `uvm_info("SCOREBOARD", "PERFECT MATCH! All channel beats successfully routed to their precise destination ports.", UVM_LOW)
          end
          
          `uvm_info("SCOREBOARD", "--- Scoreboard Checks Complete ---", UVM_LOW)
     endfunction

endclass
