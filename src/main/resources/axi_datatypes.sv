package axi_datatypes;

typedef enum {AW,AR,W,R,B} axiChannelTypes;

struct {
	wire clk,
	wire [2:0] BURST,
} aw_bus;


endpackage : axi_datatypes
