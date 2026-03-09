
/*TODO:
	1.) check how clk works in reciver
	2.) check if need to add reset
*/
module reciveri(
clk,		//axi component clk
data_in. 	//AXI channel that comes from axi component

data_out,	//
nsp		//new data pulse (width of signal is 1 clk)
);
//-----Parameters-----
parameter CHANNEL_TYPE="AW",
BUS_WIDTH=128

//-----Input Ports-----
input AXI_AWdata_in;
//-----Output Ports-----




endmodule
