
/*===============================================================
module is reciving data from a specific channel of axi component.
output - the most recent data from axi component
=================================================================*/

/*TODO:
*/

module reciver(
aclk,		//axi global clock signal
aresetn,	//global reset signal. active low
data_in,	//AXI channel that comes from axi component
data_out,	//data of entering valid and new data.
valid_out	//new data pulse (width of signal is 1 clk)
);
//----- imports-----
import axi_datatypes::*;

//----- Parameters-----

parameter BUS_TYPE="aw",
BUS_WIDTH=128;
		

//----- Input Ports-----
input aclk;
input aresetn;
input data_in;
//----- Output Ports -----
output reg data_out;
output reg valid_out;

//----- logic ------

always_ff @(posedge aclk) begin
	if(valid_out) begin
		data_out <= data_in;
		valid_out <=1'b1;
	end
	else begin
		valid_out <= 1'b0;
	end
end

endmodule
