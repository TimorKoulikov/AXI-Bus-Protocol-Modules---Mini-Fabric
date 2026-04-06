//another file - arbiter_2inpt_lowprior_tb.sv
module arbiter_2inpt_lowprior_tb;

logic clk=0, rstn=1, req0=0, req1=0;
logic grant0, grant1;

//instantiation of the module under test (UUT)
arbiter_2inpt_lowprior arbiter_uut (
	.clk(clk),
	.rstn(rstn),
	.req0(req0),
	.req1(req1),
	.grant0(grant0),
	.grant1(grant1)
);

always #5 clk=~clk;

initial begin
	$display("time  req0  req1   grant0   grant1");
	$monitor("%4t   %b     %b       %b        %b", $time, req0, req1, grant0, grant1);
	#10 rstn=0; 
	#15 rstn=1; //release reset at t=25
	#10 req0=1; //req0 rises at t=35, grant0 should rise and grant1 should be 0
	#10 req0=0; //req0 falls at t=45, grant0 should fall as well
	#10 req1=1; //req1 rises at t=55, grant1 should rise and grant0 should be 0
	#10 req0=1; //req0 rises at t=65 while req1 is still high so at t=65 both req0 and req1 are high. 
				//grant0 should rise and grant1 should be 0 because of the low id priority
	#10 {req0, req1} = 2'b00; //both req0 and req1 fall at t=65, grant0 and grant1 should fall as well
	#10 $finish;
end

endmodule