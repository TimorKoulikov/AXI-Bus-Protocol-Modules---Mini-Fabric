/*--------------------------------------------------------------------------------
 	module that receives axi data from AW or AR channel and patches additional data
 *---------------------------------------------------------------------------------*/

module patcher_ax(
	aclk,		// axi global clock signal
	aresetn,	// global reset signal. active low
	data_in,	// AXI bus (AW/AR) that comes from axi component
	ready_in,	// ready signal the patcher receives from the downstream ROB (for data_out)
	cfg,		// slaves addresses config from the arbiter_engine
	cfg_en,		// signal rise when new cfg data is in	
	
	data_out,	// outgoing AXI bus payload (including the valid bit) sent downstream to the ROB/FIFO
	ready_out,	// ready signal the patcher sends to master (ready for data_in)
	patch_out,	// patched data the patcher added
);


//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;


// TODO : think we have to move these to external file
//-----parameters-----
parameter type BUS_TYPE = aw_bus; // setting the default
parameter master_id=1;
parameter NUM_OF_SLAVES=4;


//----- Input Ports-----
input aclk;
input aresetn;
input BUS_TYPE data_in; 
input ready_in;
input cfg_t cfg;
input cfg_en;

//----- Output Ports -----
output BUS_TYPE data_out;
output logic ready_out;
output patch_t patch_out;


//----- logic ------
//cfg file
cfg_t cfg_reg;
logic is_urgent;
logic is_stream;

always @(posedge cfg_en) begin
	cfg_reg<=cfg;
end

//calculate slave_id
integer slave;
always_comb begin
	is_urgent=1'b0;
	is_stream=1'b0;
	slave=0;
	for(int i=0;i<NUM_OF_SLAVES;i=i+1) 
	begin
		if(cfg_reg[i].low_addr<data_in.addr && cfg_reg[i].high_addr>data_in.addr) 
		begin
			slave=i;
		end
	end
	
	
	if(data_in.qos == 2'b11) begin
		is_urgent = 1'b1;
	end
	if(data_in.qos == 2'b10) begin
		is_stream = 1'b1;
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
			patch_out <={slave,master_id,is_urgent,is_stream};
		end else begin
			data_out.valid <=1'b0;
		end
		
	end
end

endmodule