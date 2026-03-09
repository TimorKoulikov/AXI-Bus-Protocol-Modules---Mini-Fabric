
/*=======================
module is reciving data from a specific channel of axi component.
output - the most recent data from axi component
=========================*/

/*TODO:
	1.) check how clk works in reciver
	2.) check if need to add reset
*/

module reciveri(
clk,		//axi component clk
data_in. 	//AXI channel that comes from axi component
data_out,	//data of entering valid and new data.
nsp		//new data pulse (width of signal is 1 clk)
);
//-----imports-----
import ../resources/*
//-----Parameters-----

parameter CHANNEL_TYPE=AW,
BUS_WIDTH=128

//-----Input Ports-----
input AXI_AWdata_in;
//-----Output Ports-----




endmodule
