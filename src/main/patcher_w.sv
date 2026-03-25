/*------------------------------------------------------------------------------
module that receives axi data from W channel and patches additional data
*------------------------------------------------------------------------------*/

module patcher_w (
aclk,				//axi global clock signal
aresetn,			//global reset signal. active low
data_in,			//AXI channel that comes from axi component
ready_out,			//valid signal the patcher sends for the data_in
data_out,			//data of entering valid and new data
ready_in,			//ready signal patcher gets foDW_asymfifo_s1_dfr the data_out
slave_target,		//target do patch
slave_target_push,	//signal for new target to push
patch_out,			//patched data of the patcher add
);


//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----parameters-----
parameter type BUS_TYPE = w_bus;
parameter master_id=1;
parameter NUM_OF_SLAVES=4;

//----- Input Ports-----
input aclk;
input aresetn;
input BUS_TYPE data_in;
input ready_in;
input [ADDR_WIDTH -1 : 0] slave_target;
input slave_target_push;

//----- Output Ports -----
output BUS_TYPE data_out;
output logic ready_out;
output patch_t patch_out;


//logic for slave target_push


//logic for buffer
		
		
endmodule