//------------------------------------------------------------------------------
// File: defines.svh
//------------------------------------------------------------------------------
// Purpose:
//   Central place for testbench-wide AXI width definitions shared by sequence
//   items, interfaces, and BFMs.
//
// How to adapt:
//   - Match AXI_ADDR_WIDTH / AXI_DATA_WIDTH to your DUT configuration.
//   - These values MUST match the DUT's actual bus widths.
//------------------------------------------------------------------------------

`ifndef AXI_DEFINES_SVH
`define AXI_DEFINES_SVH

// AXI bus widths
`define AXI_ADDR_WIDTH 32
`define AXI_DATA_WIDTH 64

`endif
