/*------------------------------------------------------------------------------
 * File          : top_block.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Apr 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/


module top_block #(
	parameter NUM_OF_MASTERS=3,
	parameter NUM_OF_SLAVES=4
)
(
	input aclk,				//axi clk
	input aresetn,			//axi resetn
	axi_if.slave_if			slaves[NUM_OF_SLAVES],
	axi_if.master_if		masters[NUM_OF_MASTERS]
);

endmodule