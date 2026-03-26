/*------------------------------------------------------------------------------
 * File          : leaky_bucket.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module leaky_bucket(
aclk,		// axi global clk
aresetn,	// axi global reset
data,		// what value to load
loadn,		// enable adding tokens
count,		// current bucket value
tercent,	// the bucket is full
leak
);

//-----parameters-----
parameter width = 30;	//DW03 max width
parameter MAX_TOKEN = 100;


//-----inputs-----
input logic aclk;
input logic aresetn;
input logic [width -1 : 0] data;
input logic loadn;
input leak;

//-----outputs-----
output logic [width -1 : 0] count;
output logic [width -1 : 0] tercent;

//-----logic-----
/*
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
*/

DW03_bictr_scnto #(.width(width), .count_to(MAX_TOKEN))
bucket ( .data(data), .up_dn(~leak), .load(loadn),
.cen(leak), .clk(aclk), .reset(aresetn),
.count(count), .tercnt(tercent) );

endmodule