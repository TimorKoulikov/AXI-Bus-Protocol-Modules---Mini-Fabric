//------------------------------------------------------------------------------
// AXI Sequence Item (axi_seq_item)
//------------------------------------------------------------------------------
// Purpose:
//   Represents a *single logical AXI transaction* at the transaction level.
//   This is the common currency between AXI sequences, driver, monitor,
//   and scoreboard.
//
// Design intent:
//   - Abstracts away AXI’s multi-channel, multi-cycle nature.
//   - Collects all information needed to describe an AXI request and its result
//     in one object.
//   - Serves as the bridge between low-level protocol activity and high-level
//     functional checking.
//
// Important assumptions in the current project:
//   - This item models **one AXI transaction** with:
//       • one address phase (AW or AR)
//       • one data beat (even though LEN exists)
//   - Bursts are *described* but not fully *consumed* in current driver/monitor.
//     (LEN/SIZE/BURST are carried for future extensibility.)
//
// How this is used:
//   - Sequences / builders: populate addr, write, id, len, size, burst, data
//   - Driver:
//       • consumes request fields to drive AXI signals
//       • fills back `resp` and (for reads) `data`
//   - Monitor:
//       • reconstructs fields from observed bus activity
//       • publishes completed transactions to the scoreboard
//   - Scoreboard:
//       • correlates AXI effects with APB intent or memory model expectations
//
// How to adapt for other projects:
//   1) Width control:
//      - `AXI_ADDR_WIDTH` / `AXI_DATA_WIDTH` are macros.
//        For better reuse, consider replacing macros with parameters or typedefs
//        in a shared package.
//   2) True burst support:
//      - Replace `data` with an array/queue for multi-beat transfers.
//      - Add fields like `beats[]`, `last_seen`, or `byte_enables[]`.
//   3) Response richness:
//      - For stricter checking, keep per-beat RRESP/BRESP history instead of a
//        single `resp`.
//   4) Direction semantics:
//      - `write` determines whether this represents an AW/W/B or AR/R flow.
//        If you split read/write items, this field can go away.
//------------------------------------------------------------------------------


class axi_seq_item extends uvm_sequence_item;
	 
     `uvm_object_utils(axi_seq_item)

     rand bit [`AXI_ADDR_WIDTH-1 : 0]   addr;
     rand bit [`AXI_DATA_WIDTH-1 : 0]   data;
     rand bit                           write;         // write=1, read=0
     bit [1:0]                          resp;          // AXI response (OKAY, EXOKAY, SLVERR, DECERR)
     rand bit [3:0]                     id;            // AXI ID
     rand bit [7:0]                     len;           // Burst Length
     rand bit [2:0]                     size;          // Transfer Size
     rand bit [1:0]                     burst;         // Burst Type (FIXED, INCR, WRAP)

     function new(string name = "axi_seq_item");
          super.new(name);
     endfunction

     function string convert2string();
          return $sformatf("AXI_SEQUENCE_ITEM: axi_id=%0d, addr=0x%0h, data=0x%0h, type=%s, resp=%0b", id, addr, data, write ? "WRITE" : "READ", resp);
     endfunction

endclass