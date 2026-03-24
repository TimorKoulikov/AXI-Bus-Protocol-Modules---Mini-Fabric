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
parameter MAX_TOKEN=8;
parameter rate_leak=2;

//-----inputs-----
logic aclk;
logic aresetn;
logic [width -1 : 0] data;
logic loadn;

//-----outputs-----
logic [width -1 : 0] count;
logic [width -1 : 0] tercent;

//-----Initialization-----

leaky_bucket #(.width(width),.MAX_TOKEN(MAX_TOKEN),.rate_leak(rate_leak))
		bucket_no_leak_dut (
		.aclk(aclk),
		.aresetn(aresetn),
		.data(data),
		.loadn(loadn),
		.count(count),
		.tercent(tercent)
);

int curr;
int time_to_wait;
//-----testbanch-----
initial
begin
	$display("init leaky_bucket_test");
	aclk=1'b0;
	aresetn=1'b1;
	data='0;
	loadn=1'b1;
	#10
	//---------------------------------------
	$display("test_1: adding tokens");
	aresetn=1'b0;
	#10
	aresetn=1'b1;
	#30
	assert(count == 3) begin
		$display("test_1: PASS");
	end else begin
		$display("test_1: FAIL %d",count);
	end
	
	#10
	//---------------------------------------
	$display("test_2: checking leak rate");
	curr=count;
	
	time_to_wait=rate_leak*10;
	#time_to_wait
	assert( count == curr + rate_leak -1) begin
		$display("test_2: PASS %d %d",curr, count);
	end else begin
		$display("test_2: FAIL %d %d",curr, count);
	end
	
	//---------------------------------------
	$display("test_3: check MAX_BW ");
	
	fork : wait_with_timeout
	begin
		wait(tercent === 1'b1);
		$display("test_3: PASS");
	end
		begin
			#10000;
			if(tercent ==1'b0) begin
				$display("test_3: FAIL");
			end
		end
	join_any
	disable fork; // Kill the branch that is still running
	$finish;
end

always #5 aclk=~aclk;

endmodule