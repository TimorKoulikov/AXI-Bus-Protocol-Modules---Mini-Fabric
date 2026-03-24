/*------------------------------------------------------------------------------
 * File          : leaky_bucket.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module leaky_bucket(
aclk,		//axi global clk
aresetn,	//axi global reset
data,		//how many token to add
loadn,		//enable adding tokens
count,		//output of counter of leaky bucket
tercent		//the bucket is full
);

//-----parameters-----
parameter width=30;
parameter MAX_TOKEN=8;
parameter rate_leak=1;

//-----inputs-----
input aclk;
input aresetn;
input [width -1 : 0] data;
input loadn;

//-----outputs-----
output [width -1 : 0] count;
output [width -1 : 0] tercent;

//-----logic-----
wire t,tn;
assign tn=~t;
DW03_bictr_scnto #(.width(10),.count_to(rate_leak)) 
leak_counter (
.data('0),
.up_dn(1'b1),
.load(tn),
.cen(1'b1),
.clk(aclk),
.reset(aresetn),
.count(dbg_count),
.tercnt(t)

);

DW03_bictr_scnto #(.width(width), .count_to(MAX_TOKEN))
bucket ( .data(data), .up_dn(tn), .load(loadn),
.cen(1'b1), .clk(aclk), .reset(aresetn),
.count(count), .tercnt(tercent) );

endmodule