/*------------------------------------------------------------------------------
 * File          : leaky_bucket_test.sv.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module leaky_bucket_test();

//-----parameters-----
parameter width=32;
parameter MAX_TOKEN=100;
parameter rate_leak=1;

//-----inputs-----
logic aclk;
logic aresetn;
logic [width -1 : 0] data;
logic load;

//-----outputs-----
logic [width -1 : 0] count;
logic [width -1 : 0] tercent;

//-----Initialization-----

leaky_bucket #(.width(width),.MAX_TOKEN(MAX_TOKEN),.rate_leak(rate_leak))
		bucket_dut (
		.aclk(aclk),
		.aresetn(aresetn),
		.data(data),
		.load(load),
		.count(count),
		.tercent(tercent)
);


//-----testbanch-----
initial
begin
	$display("init leaky_bucket_test");
	aclk=1'b0;
	aresetn=1'b1;
	data='0;
	load=1'b0;
	#10
	
	//---------------------------------------
	$display("test_1: adding tokens");
	#10
	
	//---------------------------------------
	$display("test_2: checking leak rate");
	#10
	
	//---------------------------------------
	$display("test_3: check MAX_BW ");
	
	$finish;
end

always #5 aclk=~aclk;

endmodule