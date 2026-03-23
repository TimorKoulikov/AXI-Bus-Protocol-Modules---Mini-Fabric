package fabric_datatypes;
	
	import axi_datatypes::*;
	
	
	typedef struct packed {
		logic [ADDR_WIDTH -1 : 0] low_addr ;
		logic [ADDR_WIDTH -1 : 0] high_addr;		
	} cfg;
	
endpackage