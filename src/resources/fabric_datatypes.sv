package fabric_datatypes;
	
import axi_datatypes::*;

// types and defines
localparam NUM_OF_SLAVES=3;	
localparam NUM_OF_MASTERS = 4;

// for every slave we have to define address space it is working on
// the address space is low_addr - high_addr inclusively 
typedef struct packed {
		logic [ADDR_WIDTH -1 : 0] low_addr ;
		logic [ADDR_WIDTH -1 : 0] high_addr;		
} cfg_row;

// cfg_t[.] - 
typedef cfg_row [NUM_OF_SLAVES-1 : 0] cfg_t ;   //usage: cfg_t[0].low_addr = 0x0000000

typedef struct packed {
	logic [31:0] slave_id;
	logic [31:0] master_id;
	logic urgent;
	logic stream;
} patch_t;
	

class RAND_CFG;
	rand cfg_t random_cfg_data;
	
	constraint c_cfg_t {
		// assumption - mapping from 0x0 address
		// continuous mapping until the highest address (0xFFFFFFFF)
		random_cfg_data[0].low_addr == '0;
		random_cfg_data[NUM_OF_SLAVES - 1].high_addr =='1;
		foreach(random_cfg_data[i]) {
			random_cfg_data[i].low_addr < random_cfg_data[i].high_addr;
			if (i >0){
				random_cfg_data[i].low_addr == random_cfg_data[i-1].high_addr + 1;
			}
		}
	}
	
	function cfg_t get_random();
		this.randomize();
		return this.random_cfg_data;
	endfunction
endclass

endpackage