module reciver_test;

logic aclk,aresetn,datain,dataout,valid_out;
reciver  rc(aclk,aresetn,datain,dataout,valid_out);

initial
begin
	aclk = 1'b0; datain=1'b0;
	aresetn=1'b1;
	#10000 $finish;
end

always #100 aclk = ~aclk;
always #300 datain = ~datain;

endmodule