/*------------------------------------------------------------------------------
top block of arbiter_sl
*------------------------------------------------------------------------------*/

module arbiter_sl#(

	parameter slave_id       = 0,
	parameter NUM_OF_MASTERS = 4

)
(
aclk,               //axi clk
aresetn,            //axi resetn

// AW channel
aw_data_in,         //aw data channel from router_ms
aw_ready_in,        //axi awready signal from slave
aw_ready_out,       //awready signal to router_ms
aw_data_out,        //axi aw data channel to slave

// AR channel
ar_data_in,         //ar data channel from router_ms
ar_ready_in,        //axi arready signal from slave
ar_ready_out,       //arready signal to router_ms
ar_data_out,        //axi ar data channel to slave

// W channel
w_data_in,          //w data channel from router_ms
w_ready_in,         //axi wready signal from slave
w_ready_out,        //wready signal to router_ms
w_data_out,         //axi w data channel to slave

// from arbiter engine
grant               //grant signal from arbiter_engine
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;
input aw_bus [NUM_OF_MASTERS - 1 : 0] aw_data_in;
input ar_bus [NUM_OF_MASTERS - 1 : 0] ar_data_in;
input w_bus  [NUM_OF_MASTERS - 1 : 0] w_data_in;
input aw_ready_in;
input ar_ready_in;
input w_ready_in;
input [2:0][NUM_OF_MASTERS - 1 : 0] grant;

//-----outputs-----
output logic [NUM_OF_MASTERS - 1 : 0] aw_ready_out;
output logic [NUM_OF_MASTERS - 1 : 0] ar_ready_out;
output logic [NUM_OF_MASTERS - 1 : 0] w_ready_out;
output aw_bus aw_data_out;
output ar_bus ar_data_out;
output w_bus  w_data_out;


//----- AW -----
//ROB

//ROB -> outputAW

//----- AR -----
//ROB

//ROB -> outputAR


//----- W -----
//ROB

//ROB -> outputW


endmodule