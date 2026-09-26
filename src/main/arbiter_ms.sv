/*------------------------------------------------------------------------------
top block of arbiter_ms
*------------------------------------------------------------------------------*/

module arbiter_ms #(

	parameter master_id     = 0,
	parameter NUM_OF_SLAVES = 3

)
(
aclk,               //axi clk
aresetn,            //axi resetn

// B channel
b_data_in,          //b data channel from slave_router
b_ready_in,         //axi bready signal from master
b_ready_out,        //bready signal to slave_router
b_data_out,         //axi b data channel to master

// R channel
r_data_in,          //r data channel from slave_router
r_ready_in,         //axi rready signal from master
r_ready_out,        //rready signal to slave_router
r_data_out,         //axi r data channel to master

// from arbiter engine
grant               //grant signal from arbiter_engine
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;
input b_bus [NUM_OF_SLAVES - 1 : 0] b_data_in;
input r_bus [NUM_OF_SLAVES - 1 : 0] r_data_in;
input b_ready_in;
input r_ready_in;
input [1:0] grant;

//-----outputs-----
output logic [NUM_OF_SLAVES - 1 : 0] b_ready_out;
output logic [NUM_OF_SLAVES - 1 : 0] r_ready_out;
output b_bus b_data_out;
output r_bus r_data_out;

//----- B -----
//ROB

//ROB -> outputB


//----- R -----
//ROB

//ROB -> outputR


endmodule