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
// TODO : shuold to move it. i dont want multiple definitions in the project
`define AXI_ADDR_WIDTH 32
`define AXI_DATA_WIDTH 64
`define NUM_OF_MASTERS 4
`define NUM_OF_SLAVES 3

`endif
