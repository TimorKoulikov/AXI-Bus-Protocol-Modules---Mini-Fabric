/*------------------------------------------------------------------------------
 top block of rounter_ms
 
 TODO: after ROB is implemented we can finish the router
 *------------------------------------------------------------------------------*/

module router_ms(
aclk,				//axi clk
aresetn,			//axi resetn
aw_data_channel,	//axi aw data channel
aw_ready_out,		//axi awready signal to master
ar_ready_out,		//axi arready signal to master
w_ready_out,		//axi wready signal to master
ar_data_channel,	//axi ar data channel
w_data_channel,		//axi w data channel
cfg,				//cfg to patcher_ax
cfg_en,				//cfg enable signal
start_transaction,
end_transaction,
token_allocation,
bw,
is_urgent,
aw_data_out,		//aw data channel to slave_arbiter
ar_data_out,		//ar data channel to slave_arbiter
w_data_out			//w data channel to slave_arbiter
);

//-----imports-----
import axi_datatypes::*;
import fabric_datatypes::*;
//----- parameters-----
parameter master_id=0;
parameter NUM_OF_SLAVES=3;
parameter token_width=30;
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

//-----outputs-----
output aw_ready_out;
output ar_ready_out;
output w_ready_out;
output aw_bus [NUM_OF_SLAVES -1 : 0]  aw_data_out;
output ar_bus [NUM_OF_SLAVES -1 : 0]  ar_data_out;
output w_bus [NUM_OF_SLAVES -1 : 0] w_data_out;
output [2:0] end_transaction ;
output [2:0] is_urgent;
output [2:0][token_width -1 :0]  bw;

//router_contorl
router_control #(.NUM_OF_CHANNEL(3)) u_router_control (
	.aclk             (aclk             ),
	.aresetn          (aresetn          ),
	.start_transaction(start_transaction),
	.end_transaction  (end_transaction  ),
	.token_allocation (token_allocation ),
	.bw               (bw               ),
	.push             (push             ),
	.pop              (pop              ),
	.is_urgent_in     (is_urgent_in     ),
	.full             (full             ),
	.empty            (empty            ),
	.is_stream        (is_stream        ),
	.is_urgent_out    (is_urgent_out    )
);
//----- AW ------
patcher_ax #(.master_id(master_id), .NUM_OF_SLAVES(NUM_OF_SLAVES)) pathcer_aw(
	.aclk     (aclk     ),
	.aresetn  (aresetn  ),
	.data_in  (aw_data_channel ),
	.ready_out(aw_ready_out),
	.data_out (data_out ),
	.ready_in (ready_in ),
	.patch_out(patch_out),
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
.data_out (data_out ),
.ready_in (ready_in ),
.patch_out(patch_out),
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
.data_out (data_out ),
.ready_in (ready_in ),
.patch_out(patch_out)
);

// rob #() rob_w

endmodule