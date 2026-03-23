/*------------------------------------------------------------------------------
 	module recives axi data and patch additional data
 *------------------------------------------------------------------------------*/

module patcher_ax(
aclk,		//axi global clock signal
aresetn,	//global reset signal. active low
data_in,	//AXI channel that comes from axi component
ready_out,	//valid signal the patcher sends for the data_in
data_out,	//data of entering valid and new data
ready_in,	//ready siganl patcher gets foDW_asymfifo_s1_dfr the data_out
patch_out,	//patched data of the patcher add
cfg,		//cfe from the arbitrer
cfg_en		//signal rise when new cfg data is in	
);


//-----imports-----
import axi_datatypes::*;



//-----parameters-----
parameter type BUS_TYPE = aw_bus;
//parameter width = $bits(BUS_TYPE);
//parameter depth = 1;
parameter master_id=1;
parameter NUM_OF_SLAVES=4;


//----- Input Ports-----
input aclk;
input aresetn;
input BUS_TYPE data_in;
input ready_in;
input [NUM_OF_SLAVES-1:0][1:0][ADDR_WIDTH:1] cfg;
input cfg_en;
//----- Output Ports -----
output BUS_TYPE data_out;
output logic ready_out;
output logic [2:0] patch_out;
//----- logic ------

//cfg file
reg [NUM_OF_SLAVES-1:0][1:0][ADDR_WIDTH:1] cfg_reg;
always @(posedge cfg_en) begin
	cfg_reg<=cfg;
end

integer slave;
always_comb begin
	slave=0;
	for(int i=0;i<NUM_OF_SLAVES;i=i+1) 
	begin
		if(cfg_reg[i][0]<data_in.addr && cfg_reg[i][1]>data_in.addr) 
		begin
			slave=i;
		end
	end
end

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
			patch_out <={slave,master_id,1'b0};
		end
		
	end
end

endmodule