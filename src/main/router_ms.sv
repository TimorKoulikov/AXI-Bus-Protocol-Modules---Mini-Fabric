/*------------------------------------------------------------------------------
 top block of rounter_ms
 *------------------------------------------------------------------------------*/


module router_ms#(
	parameter master_id=0,
	parameter NUM_OF_SLAVES=3,
	parameter token_width=30,
	parameter [token_width -1 : 0] TOKEN_LOW_THRESHOLD = 8
)
(
	aclk,				//axi clk
	aresetn,			//axi resetn
	
	// AW channel
	aw_data_channel,	//axi aw data channel
	aw_ready_out,		//axi awready signal to master
	aw_data_out,		//aw data channel to slave_arbiter
	aw_ready_in,		//aw ready to slave		
	
	// AR channel
	ar_data_channel,	//axi ar data channel
	ar_ready_out,		//axi arready signal to master
	ar_data_out,		//ar data channel to slave_arbiter
	ar_ready_in,		//ar ready to slave	
	
	// W channel
	w_data_channel,		//axi w data channel
	w_ready_out,		//axi wready signal to master
	w_data_out,			//w data channel to slave_arbiter
	w_ready_in,			//w ready to slave	

	// from arbiter_engine
	cfg,				//cfg to patcher_ax
	cfg_en,				//cfg enable signal
	start_transaction,
	end_transaction,
	token_allocation,
	num_tokens,
	is_urgent,
	needy_level
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;

//-----inputs-----
input aclk;
input aresetn;
input aw_bus aw_data_channel;
input ar_bus ar_data_channel;
input w_bus w_data_channel;
input cfg_t cfg;
input cfg_en;
input [2:0] start_transaction;
input [2 : 0][token_width -1 :0] token_allocation;
input aw_ready_in;
input ar_ready_in;
input w_ready_in;

//-----outputs-----
output aw_ready_out;
output ar_ready_out;
output w_ready_out;
output aw_bus [NUM_OF_SLAVES -1 : 0]  aw_data_out;
output ar_bus [NUM_OF_SLAVES -1 : 0]  ar_data_out;
output w_bus [NUM_OF_SLAVES -1 : 0] w_data_out;
output [2:0] end_transaction ;
output [2:0] is_urgent;
output [2:0][token_width -1 :0]  num_tokens;

//logic
output logic [2: 0][2:0] needy_level; 	//[num_of_channel:0][needy_num_of_bits] 
wire [2 : 0] full; 						//[num_of_channel:0]
wire [2 : 0] empty; 					//[num_of_channel:0]
wire patch_t aw_patch_out;
wire patch_t ar_patch_out;
wire patch_t w_patch_out;

//router_contorl
router_control #(.NUM_OF_CHANNEL(3)) u_router_control (
	.aclk             (aclk             ),
	.aresetn          (aresetn          ),
	.start_transaction(start_transaction),
	.end_transaction  (end_transaction  ),
	.token_allocation (token_allocation ),
	.num_tokens       (num_tokens       ),
	.pop              (pop              ),
	.full             (full             ),
	.empty            (empty            ),
	.mode			  (needy_level)
);
// needy
needy #(.NUM_OF_CHANNEL(3), .token_width(token_width), .TOKEN_LOW_THRESHOLD(TOKEN_LOW_THRESHOLD)) u_needy (
	.token_allocation(token_allocation),
	.full            (full            ),
	.empty           (empty           ),
	.needy           (needy_level           )
);
//----- AW ------
patcher_ax #(.master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES)) pathcer_aw(
	.aclk     (aclk     ),
	.aresetn  (aresetn  ),
	.data_in  (aw_data_channel ),
	.ready_out(aw_ready_out),
	.data_out (aw_data_out ),
	.ready_in (aw_ready_in ),
	.patch_out(aw_patch_out),
	.cfg      (cfg      ),
	.cfg_en   (cfg_en   )
);
// rob #() rob_aw

//----- AR -----
patcher_ax #(.master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES),.BUS_TYPE(ar_bus)) pathcer_ar(
.aclk     (aclk     ),
.aresetn  (aresetn  ),
.data_in  (ar_data_channel),
.ready_out(ar_ready_out),
.data_out (ar_data_out ),
.ready_in (ar_ready_in ),
.patch_out(ar_patch_out),
.cfg      (cfg      ),
.cfg_en   (cfg_en   )
);
// rob #() rob_ar

//----- W -----

patcher_w #(.master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES)) pathcer_w(
.aclk     (aclk     ),
.aresetn  (aresetn  ),
.data_in  (w_data_channel ),
.ready_out(w_ready_out),
.data_out (w_data_out ),
.ready_in (w_ready_in ),
.patch_out(w_patch_out)
);

// rob #() rob_w

endmodule