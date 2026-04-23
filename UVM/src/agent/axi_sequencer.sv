//------------------------------------------------------------------------------
// AXI Sequencer (UVM)
//------------------------------------------------------------------------------
// Purpose:
//   Standard UVM sequencer for `axi_seq_item` transactions.
//   It arbitrates between sequences that want to generate AXI traffic and
//   provides items to `axi_driver`.
//
// Why this stays minimal:
//   - Keeping the sequencer “thin” makes it reusable across projects.
//   - AXI protocol behavior belongs in the driver/monitor (timing/handshakes),
//     while high-level traffic patterns belong in sequences.
//
// What you might change in other projects (only if needed):
//   1) Add configuration handles / knobs:
//      - e.g., memory model handle, max outstanding, response policy, delays.
//      - This is useful when sequences need read-only access to those knobs.
//   2) Arbitration / priorities:
//      - If you have multiple traffic sources (read/write stress + directed),
//        you can implement custom arbitration here.
//   3) Different transaction type:
//      - If you replace `axi_seq_item` (e.g., AXI4-Lite item), update the
//        parameter and factory registration accordingly.
//------------------------------------------------------------------------------

class axi_sequencer extends uvm_sequencer #(axi_seq_item);

     `uvm_component_utils(axi_sequencer)

     function new(string name = "axi_seqr", uvm_component parent=null);
          super.new(name, parent);
     endfunction

endclass