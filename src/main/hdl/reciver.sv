
/*===============================================================
module is reciving data from a specific channel of axi component.
output - the most recent data from axi component
=================================================================*/

/*TODO:
*/

module reciveri(
aclk,		//axi global clock signal
aresetn,	//global reset signal. active low
data_in,	//AXI channel that comes from axi component
data_out,	//data of entering valid and new data.
valido		//new data pulse (width of signal is 1 clk)
);
//----- imports-----
import ../resources/axi_datatypes::*
//----- Parameters-----

parameter CHANNEL_TYPE=AW,
BUS_WIDTH=128;

//----- Input Ports-----
input aclk;
input aresetn
input aw_bus data_in;
//----- Output Ports -----
output datao;
output valido;

//----- logic ------

always @(posedge aclk) begin
	if(valid)
		data_out <= data_in;
		valid_out <=1'b1;
	end
	else begin
		valid_out >=1'b0;
	end
end

endmodule
