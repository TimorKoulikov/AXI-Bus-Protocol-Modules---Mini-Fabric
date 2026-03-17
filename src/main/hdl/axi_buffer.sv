/*===============================================================
module is reciving data from a specific channel of axi component.
output - the most recent data from axi component
=================================================================*/

module axi_buffer(
aclk,		//axi global clock signal
aresetn,	//global reset signal. active low
data_in,	//AXI channel that comes from axi component
ready_out,	//ready signal the reciver sends for the data_in
data_out,	//data of entering valid and new data
ready_in,	//ready siganl reciver gets for the data_out
);

//----- imports-----
import axi_datatypes::*;

//----- Parameters-----
		
parameter type BUS_TYPE = aw_bus;
		
//----- Input Ports-----
input aclk;
input aresetn;
input BUS_TYPE data_in;
input logic ready_in;

//----- Output Ports -----
output BUS_TYPE data_out;
output logic ready_out;
//----- logic ------

always_ff @(posedge aclk or negedge aresetn) begin
	//reset the module
	if(!aresetn) begin
		data_out <= '0;
		ready_out<= 1'b0;
	end else begin
		ready_out<=1'b1;
		if(ready_in==1'b0) begin
			ready_out<=1'b0;
		end
		if(data_in.valid==1'b1) begin
			data_out<=data_in;
		end
		
	end
end

endmodule
