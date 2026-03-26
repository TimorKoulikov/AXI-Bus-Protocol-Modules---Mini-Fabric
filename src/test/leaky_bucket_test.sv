/*------------------------------------------------------------------------------
 * File          : leaky_bucket_test.sv.sv
 * Project       : Fabric
 * Author        : epagtk
 * Creation date : Mar 24, 2026
 * Description   :
 *------------------------------------------------------------------------------*/

module leaky_bucket_test();

//-----parameters-----
parameter width=30;
parameter MAX_TOKEN=100;

//-----inputs-----
logic aclk;
logic aresetn;
logic [width -1 : 0] data;
logic loadn;
logic leak;

//-----outputs-----
logic [width -1 : 0] count;
logic [width -1 : 0] tercent;

//-----Initialization-----

leaky_bucket #(.width(width),.MAX_TOKEN(MAX_TOKEN))
		leaky_bucket_uut (
		.aclk(aclk),
		.aresetn(aresetn),
		.data(data),
		.loadn(loadn),
		.count(count),
		.tercent(tercent),
		.leak(leak)
);

int curr;
int time_to_wait;
int num_of_leak;
//-----testbanch-----
initial
begin
	$display("init leaky_bucket_test");
	aclk=1'b0;
	aresetn=1'b1;
	data='0;
	loadn=1'b1;
	leak=1'b1;
	aresetn=1'b0;
	#10
	aresetn=1'b1;
	#10
	//---------------------------------------
	$display("test_1: adding tokens");
	data=$random();
	loadn=1'b0;
	#10
	loadn=1'b1;
	assert(count == data) begin
		$display("test_1: PASS");
	end else begin
		$display("test_1: FAIL %d",count);
	end
	
	#10
	//---------------------------------------
	$display("test_2: checking leakag");
	curr=count;
	leak=1'b1;
	num_of_leak=7;
	time_to_wait=10*num_of_leak;
	#time_to_wait
	leak=1'b0;
	assert( count == curr - num_of_leak) begin
		$display("test_2: PASS %d %d",curr, count);
	end else begin
		$display("test_2: FAIL %d %d",curr, count);
	end
	$finish;
end

always #5 aclk=~aclk;

endmodule