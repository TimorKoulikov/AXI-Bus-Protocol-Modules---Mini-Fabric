`ifndef AXI_REFERENCE_MODEL_SV
`define AXI_REFERENCE_MODEL_SV

class axi_reference_model extends uvm_component;

     `uvm_component_utils(axi_reference_model)

     // Monitor inputs (will receive all channels, but we filter for STIMULUS)
     uvm_analysis_export #(axi_seq_item)     mst_export[`NUM_OF_MASTERS];
     uvm_analysis_export #(axi_seq_item)     slv_export[`NUM_OF_SLAVES];

     uvm_tlm_analysis_fifo #(axi_seq_item)   mst_fifo[`NUM_OF_MASTERS];
     uvm_tlm_analysis_fifo #(axi_seq_item)   slv_fifo[`NUM_OF_SLAVES];

     // Output predictions to the scoreboard per-port
     uvm_analysis_port #(axi_seq_item)       ref_mst_ap[`NUM_OF_MASTERS];
     uvm_analysis_port #(axi_seq_item)       ref_slv_ap[`NUM_OF_SLAVES];

     function new(string name = "axi_reference_model", uvm_component parent = null);
          super.new(name, parent);
          
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               mst_export[i] = new($sformatf("mst_export_%0d", i), this);
               mst_fifo[i]   = new($sformatf("mst_fifo_%0d", i), this);
               ref_mst_ap[i] = new($sformatf("ref_mst_ap_%0d", i), this);
          end
          
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               slv_export[i] = new($sformatf("slv_export_%0d", i), this);
               slv_fifo[i]   = new($sformatf("slv_fifo_%0d", i), this);
               ref_slv_ap[i] = new($sformatf("ref_slv_ap_%0d", i), this);
          end
     endfunction

     function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               mst_export[i].connect(mst_fifo[i].analysis_export);
          end
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               slv_export[i].connect(slv_fifo[i].analysis_export);
          end
     endfunction

     task run_phase(uvm_phase phase);
          
          // Master side stimulus: AW, W, AR going INTO the fabric
          for (int i = 0; i < `NUM_OF_MASTERS; i++) begin
               automatic int mst_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              mst_fifo[mst_idx].get(tr);
                              if (tr.ch_type == AW || tr.ch_type == W || tr.ch_type == AR) begin
                                   int target_slave = 0; // TODO: Use cfg_t(tr.addr) to calculate real target slave!
                                   `uvm_info("REF_MODEL", $sformatf("Predicting Master %0d %s beat to emerge from Slave %0d", mst_idx, tr.ch_type.name(), target_slave), UVM_HIGH)
                                   ref_slv_ap[target_slave].write(tr);
                              end
                         end
                    end
               join_none
          end

          // Slave side stimulus: B, R going INTO the fabric (responses)
          for (int i = 0; i < `NUM_OF_SLAVES; i++) begin
               automatic int slv_idx = i;
               fork
                    begin
                         axi_seq_item tr;
                         forever begin
                              slv_fifo[slv_idx].get(tr);
                              if (tr.ch_type == B || tr.ch_type == R) begin
                                   int target_master = 0; // TODO: Need tracking logic to know which master requested this ID!
                                   `uvm_info("REF_MODEL", $sformatf("Predicting Slave %0d %s response to emerge from Master %0d", slv_idx, tr.ch_type.name(), target_master), UVM_HIGH)
                                   ref_mst_ap[target_master].write(tr);
                              end
                         end
                    end
               join_none
          end
          
     endtask

endclass

`endif
