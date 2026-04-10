/* --------- Cheat-sheet for SV --------- */

//IMPORTANT: we use a backtick (`) for "include", "define", "timescale"


/*	1)  --------------- Instantiation: [Design & Verification] ---------------
		- instantiation example using existing module
		- assume library module half_adder has 4 ports:
		  a,b,hcarry,hsum and has a parameter ha_latency

*/
// 1.1) lets create a full-adder using two half-adders

module full_adder(
	input logic  in1,		//regular input1
	input logic  in2,		//regular input2
	input logic  c_in,		//carry input
	output logic fsum,		//sum to output
	output logic c_out		//carry output
);
	//-----parameters-----
	parameter fa_latency=5;

	//----- helper wires ------
	// we need them for future connections between the two half-adders
	logic w_sum;
	logic w_carry1;
	logic w_carry2;

	//----- logic ------

	//first ha instance with overriding its latency parameter
	half_adder #(.ha_latency(2)) ha_inst1 (
								.a(in1),
								.b(in2),
								.hcarry(w_carry1),
								.hsum(w_sum) 
	);

	//second ha instance
	half_adder #(.ha_latency(1)) ha_inst2 (
								.a(w_sum),
								.b(c_in),
								.hcarry(w_carry2),
								.hsum(fsum)
	);

	assign c_out = w_carry1 | w_carry2;

endmodule



/* 1.2) Implicit Port Connections (Shortcuts)
		If a module's port names exactly match the signal names in your parent module, 
		you can use implicit connections to save typing. 
		!!! This only works on user-defined modules, not built-in gates like 'nand' !!!
*/

// The Wildcard (.*)
// Connects ALL ports to signals with the exact same name automatically.
my_custom_module my_inst_1 (.*); 

// We can also mix wildcards with explicit connections. 
my_custom_module my_inst_2 (.*, .out_port(z_signal)); 





/*	2)  --------------- always_comb: [Strictly Design] ---------------
		- Combinational logic also know as asynchronous logic --> always_comb
		- Builds physical gates
		- In the old Verilog days, engineers used "always @(in1 or in2 or sel)"
		- If they forgot any signal, the hardware synthesized incorrectly. 
		- The entire reason SystemVerilog invented the always_comb keyword was to
		  force the compiler to ***automatically look inside the block and 
		  figure out the sensitivity list for us***. 
		- Adding @(...) next to always_comb is technically a syntax error in many
		  strict industry compilers.
*/
// 2.1) Lets implement a mux2to1
module mux2to1(
	input  logic in1,
	input  logic in2,
	input  logic sel,
	output logic out 
);

	//----- logic ------
	always_comb begin
		if(sel==0) begin
			out=in1;
		end else begin
			out=in2;
		end
	end
	

/* 2.2.1) 2nd approach "continuous logic assignment" using ternary operator
		  Note: It's forbidden to use assign inside a procedural block. 
				We can only use "assign" in the open space of the module.
*/
	assign out = sel ? in2 : in1;

/* 2.2.2) Pro-Tip: We can also use the ternary operator INSIDE a procedural block 
		  to save space, but we MUST drop the 'assign' keyword as explained before.
*/
	always_comb begin
		out = sel ? in2 : in1; // Valid procedural assignment
	end

endmodule



/* 2.3) IMPORTANT NOTE: "Unintended Latch" or "Inferred Latch" problem -----
	- If we forget to assign a value to "out" in any possible path of the code, 
	  the compiler will infer that we want to "remember" the last value of "out" 
	  whenever we hit that path. This causes the compiler to build a physical latch 
	  in silicon, which is almost always a bug.
	- When we use always_comb, we are explicitly telling the compiler, 
	  "I only want combinational gates here. DO NOT build memory." If we accidentally 
	  write an incomplete "if/else" inside an "always_comb" block, the synthesizer will 
	  immediately realize we broke our own rule. It will throw a massive warning or 
	  fatal error ("Latch inferred in always_comb") and refuse to compile. 
	  This saves us from discovering the broken chip weeks later!
	- There are 2 industry standards to prevent this problem:
*/

/*	2.3.1) The "Default Assignment" Trick - Highly Recommended
		   Instead of trying to make sure every single if, else if, and else has 
		   every variable mapped out perfectly, we just assign a "default" value 
		   to everything at the very top of our always_comb block.
*/
always_comb begin
	out = in1; //default assignment

	// the logic
	if (sel == 1'b1) begin
		out = in2;
	end
	// Note: there is no 'else' here! But because 'out' already has a default 
	// assignment, no latches will be created!
end


/* 	2.3.2) The default keyword in Case Statements
		   If you are building an FSM or a decoder using a case statement, we must 
		   explicitly cover every possible binary combination. If we are using a 2-bit 
		   state machine, there are 4 possible states. If we only write cases for 3 of them, 
		   the 4th state will infer a latch. To prevent this, you must include the 
		   default: keyword at the bottom of a case statement.
*/
always_comb begin
	case (current_state)
		STATE_IDLE: next_state = STATE_WORK;
		STATE_WORK: next_state = STATE_DONE;
		STATE_DONE: next_state = STATE_IDLE;
		
		// CATCH-ALL (Prevents Latches!)
		default: next_state = STATE_IDLE; 
	endcase
end


/* 2.4) - Giving an always_comb block name is a good practice for readability and debugging.
		- Especially when we have multiple always_comb block within the module, or
		  when we want to put a block inside another block.
*/
always_comb begin : adder
	sum = a + b;
end




/*	3)  --------------- always_ff: [Strictly Design] ---------------
		- Sequential logic also know as synchronous logic --> always_ff
		- Builds physical flip-flops
*/
// 3.1) Let's implement a flip-flop with enable and asynchronous reset

module ff_en_res(
	input  logic d,
	input  logic en,
	input  logic rstn,
	input  logic clk,
	output logic q
);

	//----- logic ------
	always_ff @(posedge clk or negedge rstn) begin : ff_logic
		if(rstn==0) begin
			q<=0;
		end 
		else if(en==1) begin
			q<=d;
		end
	end
endmodule
/*	Note: If we implement a synchronous reset, it will change the q state to 0
		when clk posedge rises! 
		i.e. the sensitivity list of always_ff is "posedge clk" only
*/


// 3.2) e.g.2: synchronous adder with asynchronous reset

always_ff @(posedge clk or negedge rstn) 
begin : adder_ff
	if(rstn==0) begin
		sum <= 0;
		parity_even <= 0;
		// $display("Reset is active, sum and parity are reset to 0");

		// the line above "display" is not recommended in RTL writing
		// it will spam the console as long as the reset is active
	end else begin
		sum <= a + b;
		parity_even <= ^(a+b); // parity is even if the number of 1's in sum is even
	end
end



/*	4)  --------------- Functions: [Design & Verification] ---------------
		- Synthesizable if they have no time delays. Heavily used in both.
		- Are defined inside the module where are also implemented.
		- Assume we implement a function in "my_func.sv" file and we want to use 
		  it in "any_module.sv" file.
*/
// 4.1) definition
function logic my_func(input logic a,b,c);
	return (a+b) & c;
endfunction

/*  instead of "logic" we can use any type that we want to return
	e.g.:   bus - "logic [31:0]"    or    "logic [N-1:0]"
			void, int, struct, class, enum, etc...
*/

// 4.2) calling the function
module any_module(
	input  logic in1,in2,in3,
	output logic out
);
	//----- logic ------
	`include "my_func.sv" 
	assign out = my_func(in1,in2,in3) ? 0 : 1;
endmodule

//IMPORTANT: we use a Backtick (`) for "include", "define", "timescale"



/* 5)  --------------- Tasks: [Strictly Verification] ---------------
		- Because they contain time delays like # and @, they cannot be synthesized 
		  into silicon
		- Task is a subroutine that can contain timing control statements 
		  (like #, @, wait) and can return multiple values through output arguments.
		- In contrast to functions, tasks do not return a value directly. 
		  Instead, they can have output arguments that allow them to return multiple values.
*/

// Modern SV uses ANSI-style ports (just like modules and functions)
// BEST PRACTICE: Add the 'automatic' keyword

// 5.1) definition
task automatic convert_temp(
	input  logic [7:0] temp_c, // Celsius
	output logic [7:0] temp_f  // Fahrenheit
);
	//----- logic ------
	temp_f = (temp_c * 9) / 5 + 32; // convert Celsius to Fahrenheit
endtask

/*
	By adding the word automatic (task automatic convert_temp), we tell the simulator: 
	"Every single time this task is called, create a brand new, temporary copy of its 
	variables in memory, and destroy them when the task finishes." 
	This makes our tasks 100% "thread-safe" and is a mandatory best practice in modern 
	verification.
*/

// 5.2) Calling the task
// Tasks are called as standalone statements, not inside assignments!
module task_caller;
	logic [7:0] current_c, current_f;

	initial begin
		current_c = 8'd100; // Set current_c to 100 degrees Celsius
		// Correct way to call a task and catch its output
		convert_temp(current_c, current_f);
		$display("Temperature in F is: %0d", current_f);
	end
endmodule





/*	6)  --------------- Loops [Design & Verification] ---------------
		Note: loops must be placed inside the procedural block (always, initial)
		4 kinds of loops: while, do while, for, repeat
		- while, do-while, repeat are not synthesisable and are used for testbenches
		- for loops are highly synthesizable and are actually a good practice for 
		  writing scalable RTL.
*/

// 6.1) while loop [Strictly Verification]
int a=0;
while(a<10) begin
	$display("Current value a=%g",a);
	a++;
end 

// 6.2) do-while loop [Strictly Verification]
int a=0;
do begin
	$display("Current value a=%g",a);
	a++;
end while(a<10);


// 6.3) for loop [Design] (Synthesizer unrolls them into physical gates)
for(int a=0; a<10; a++) begin
	$display("Current value a=%g",a);
end

// 6.4) repeat loop - better for testbenches [Strictly Verification]
// it repeats the code inside it for a specific number of times
int a=0;
repeat(10) begin
	$display("Current value a=%0d",a);
	a++;
end



/*	7)  --------------- fork-join: [Strictly Verification] ---------------
		- Physical hardware is already naturally parallel; fork-join is a software 
		  trick to simulate hardware parallelism in your testbench
		- "fork" - causes to split to parallelism
				i.e every line after fork and before join, will happen in parallel
		- "join" - there are 3 kinds: 
			   - "join" [all] - waits until all lines between the fork-join are
								procedured and only after we go on for the remain code
			   - "join_any"   - wait until any of the lines will finish
			   - "join_none"  - don't wait, just continue to the remain code

		Note: It's very common to use this pattern for bus verification
*/

// let's look at the next example

// 1. WITHOUT fork-join (Sequential Execution)
initial begin
	a=0; b=0;
	#2 a=1; // 'a' rises at absolute time t=2 
	#1 b=1; /* 1 time unit after the previous line finishes, 'b' will rise.
			   So it actually happens at absolute time t=3 */ 
end

// 2. WITH fork-join (Parallel Execution)
initial begin
	a=0; b=0; 
	fork
		#2 a=1; // Thread 1: 'a' rises at absolute time t=2
		#1 b=1; // Thread 2: 'b' rises at absolute time *** t=1 ***
	join
	
	/* Because we used 'join' (all), the compiler waits until t=2 
	   (when the longest thread finishes) before executing anything down here. */
end


/*	8)  --------------- generate, genvar [Strictly Design] ---------------
		- A compiler script used to stamp out massive amounts of physical hardware
		- "genvar"   - variables of this type exist at compile-time only
		- "generate" - duplicates all the code we have between generate-endgenerate
		
		Note: It's helpful to think of generate not as a loop that runs on the chip, 
			  but as a script that writes SV code for you
			  e.g: If the SIZE was 4, the compiler literally reads your generate 
			  block and writes this out behind the scenes on the next way:
				assign gray[2] = bin[3] ^ bin[2];
				assign gray[1] = bin[2] ^ bin[1];
				assign gray[0] = bin[1] ^ bin[0];
*/

module bin2gray #(
	parameter SIZE=32 //default number of bits
)(
	input  logic [SIZE-1:0] bin,
	output logic [SIZE-1:0] gray
);

	//----- logic ------
	assign gray[SIZE-1] = bin[SIZE-1]; //The MSB bit is the same

	genvar i; //genvar variable exist at compile time only
	generate 
		for(i=SIZE-2;i>=0;i--) begin : gen_gray_xor // gen_gray_xor is a block name
			assign gray[i] = bin[i+1] ^ bin[i];
		end //for
	endgenerate 
endmodule

/* Note about "begin : gen_gray_xor" 
	When the synthesis tool unrolls this loop to create the physical XOR 
	gates, it needs a way to name every single gate's instance in the hierarchy 
	for debugging and simulation. If you don't name the block, the compiler
	will automatically assign it a random, ugly name (like genblk_01), 
	making it a nightmare to find signals in a waveform viewer.
*/


/* 9) --------------- testbenches --------------- 
		- testbenches are used to verify the functionality of the module we implemented
		- they are not synthesisable and are only used for simulation
		- they are implemented in a separate file with the name "<module_name>_tb.sv"
		- they are implemented as a module without ports with the "initial" block 
		  or "always" block to generate the stimulus and check the results
*/

// a good practice of a testbench is as follows:
module alex_module_tb; //Note: no ports, no parameters
	//imports
	//parameters
	//signals initialization
	//instantiation of the module under test (UUT):
	alex_module #(
		.<modules_parameter_name>(<value>)
	) alex_module_uut (
		.in1(in1),
		.in2(in2),
		.out(out)
	);
	//initial or always block to generate stimulus and check results
endmodule

/* 9.1) --------------- initial [Strictly Verification] --------------- 
		- the code inside "initial" is not synthesisable and is only used for simulation
		- compared to "always" block, the code is executed only once at the 
		  beginning of the simulation, and then it stops. 
		- so it is useful for generating specific values to signals and variables 
		  at the start of the simulation.

		Note: DON'T FORGET TO STOP THE SIMULATION USING $finish; 
*/

//e.g:
logic clk;
initial begin
	clk=0;
end

//always #5 clk=~clk; //a one-liner is also good practice

always begin
	#5 clk=~clk; //generate a clock with period of 10 time units
end


/* 9.2) --------------- basic printing ---------------
		- we can use $display, $monitor, $strobe to print values of signals and variables
		- $display - prints only once when it is called
		- $monitor - prints whenever any of the signals in its argument list changes
		- $strobe  - prints at the end of the current time step, after all events have been processed
	flags:
		- %t - we can display the current sim_time using $time
		- %d - decimal. Used to print integer values in decimal format.
		- %b - binary
		- %h - hexadecimal
		- %g - general format (automatically chooses the most compact representation)
*/

//lets look at the next example
module print_table_test;
	logic clk=0, enable=0;
	int counter=0;

	initial begin
		$display("time    clk    enable    counter");
		$monitor("%4t     %b       %b      %5d", $time, clk, enable, counter);	
		#3 enable=1;
		
		repeat(10) begin
			@(posedge clk) counter++;
		end
		
		// Optional: Stop the simulation after the loop finishes
		#10 $finish;
	end

	always #5 clk=~clk;

endmodule

//it prints us the following table:
/*
time    clk    enable    counter
   0     0       0          0
   3     0       1          0
   5     1       1          1
  10     0       1          1
  15     1       1          2
  20     0       1          2
  25     1       1          3
  30     0       1          3
  35     1       1          4
  40     0       1          4
  45     1       1          5
  50     0       1          5
  55     1       1          6
  60     0       1          6
  65     1       1          7
  70     0       1          7
  75     1       1          8
  80     0       1          8
  85     1       1          9
  90     0       1          9
  95     1       1         10
 100     0       1         10

*/


/* 9.3) ----------- example of a module and its tb ----------- */

//module arbiter_2inpt_lowprior - an arbiter with 2 inputs and low id priority
module arbiter_2inpt_lowprior(
	input  logic clk,
	input  logic rstn,
	input  logic req0,
	input  logic req1,
	output logic grant0,
	output logic grant1
);

always_ff @(posedge clk or negedge rstn) begin
	if(!rstn) begin
		grant0 <= 0;
		grant1 <= 0;
	end else begin 
		// PREVENT STICKY MEMORY (Default assignments)
		grant0 <= 0; 
		grant1 <= 0;
	end

	//------ logics ------
	/*  give the grant by lowest id priority, so if both req0 and req1 are high 
		grant0 will be high and grant1 will be low */

	if(req0) begin
		grant0 <= 1;
	end else if(req1) begin
		grant1 <= 1;
	end
end

endmodule

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

// the table is as follows:
/*
time  req0  req1   grant0   grant1
   0   0     0       x        x
   5   0     0       0        0
  35   1     0       1        0
  45   0     0       0        0
  55   0     1       0        1
  65   1     1       1        0
  75   0     0       0        0
*/







/* ---------------------- Other Syntax Keywords in SV ---------------------- */


/*	10)  --------------- typedef: [Design & Verification] ---------------
		- "typedef" is used to create new data types in SV. 
		- It can be used to create structs, enums, unions, etc...
*/
typedef int myint_t; //myint_T is now a new data type that is equivalent to int
myint_t a=0;



/*	11)  --------------- enum: [Design & Verification] ---------------
		- The absolute best way to build physical FSM states in a readable and safe way
		- "enum" is used to create a new variable that can take a finite set of values.
		- SV enums are "strongly typed. Once we declare a variable as an enum, 
		  the compiler builds a protective wall around it. We are no longer allowed 
		  to assign raw binary numbers to it, and we can only assign it 
		  the specific names we defined in the list.
*/
enum {red, green, yellow} color;

/* 11.1) When the compiler sees this, it does two things:
		- It automatically assigns values: red = 0, green = 1, yellow = 2 by order.
		- The Trap: Because we didn't tell it how many bits to use, SV defaults 
		  to making color a 32-bit signed integer (int).
		- To represent 3 color we can use 2 bits, so we can specify the size 
		  of the enum as follows:
*/
enum logic [1:0] {red, green, yellow} color; 
// now "color" is a 2-bit variable that can take the values 00, 01, 10


// 11.2) We can also assign specific values to the enum members as follows:
enum logic [1:0] {red=2'b00, green=2'b10, yellow=2'b01} color;
// in this case, red is 0, yellow is 1, and green is 2. 


/* 11.3) - Unlike in C, we cannot assign raw numbers to an enum variable, 
		   ***even if those numbers are valid***. WE must use the names defined in 
		   the enum list.
		 - This is a safety feature that prevents us from accidentally assigning an 
		   invalid value to the enum variable.

	- ILLEGAL: color <= 2'b11; (Error: Cannot assign a packed type to an enum type)
	- ILLEGAL: color <= 2'b00; (Error: Even though 00 is valid, we cannot use the raw number!)
	- LEGAL: color <= red; (The compiler translates 'red' to 00 for us under the hood)
*/



/* 11.4) --------------- typedef enum ---------------
		- It is a common pattern to create a new type for the enum and then 
		  declare variables of that type.
*/
typedef enum logic [1:0] {red=0, green=1, yellow=2} colors_t;

// now we can declare variables of type colors_t by using:
colors_t traffic_light_color;
/*  where traffic_light_color can only take the values red, green, or yellow, 
	and cannot be assigned raw numbers like 00, 01, or 10 directly. */





/*	12) --------------- struct: [Design & Verification] ---------------
		- "struct" is a container of variables that we can group together to create a new variable.
		- It is similar to a "class" in OOP, but without methods and inheritance.
		- It is a good practice to use struct for grouping related signals together, 
		  such as the signals of a bus or the state variables of an FSM.
		
		NOTE: Assigning values to a struct variable can be done only within procedural blocks
			  (initial, always, etc.). We cannot leave them floating in the open space of a module. 
*/

// 12.1) definition and declaration of a struct variable
struct { 
	int a;
	int unsigned b; // Note: 'unsigned int' is usually written 'int unsigned' in SV
	logic c;
} my_struct_var; //my_struct_var is a new variable of type struct that contains 3 members: a, b, c

// 12.2) assigning values to a single var inside the struct
my_struct_var.c = 1'b0;

// 12.3) assigning values to all the members of the struct at once - 3 methods:

	/*  Method 1: By Name (BEST PRACTICE)
		Safest method because it won't break if you reorder the variables later. */
	my_struct_var = '{a: 5, b: 10, c: 1'b1}; 
	//NOTE: we use an apostrophe before the curly brace '{

	/*  Method 2: By Position (The Shortcut)
		Maps values strictly top-to-bottom based on how the struct was defined. */
	my_struct_var = '{5, 10, 1'b1};

	/*  Method 3: The 'default' Keyword (The Reset Trick)
		The fastest way to set absolutely everything inside the struct to 0.
		This is incredible for resetting massive buses in one line of code! */
	my_struct_var = '{default: 0};


/* 12.4) -------- typedef struct --------
		- It is a common pattern to create a new type for the struct and then 
		  declare variables of that type.
*/
typedef struct {
	int a;
	int unsigned b; 
	logic c;
} my_struct_t;

// now we can declare variables of type my_struct_t by using:
my_struct_t bus_signals;
// where bus_signals is a new variable of type my_struct_t with 3 members: a, b, c.



/* 13) --------------- Classes (OOP): [Strictly Verification] ---------------
		- The backbone of modern UVM testbenches. Absolutely zero silicon equivalence
		- A class is a dynamic blueprint used almost exclusively in Testbenches.
		- Unlike a struct (which just holds data), a class holds data AND the 
		  functions/tasks (methods) that operate on that data.
*/

// 13.1) definition of a class using PascalCase - Highly Recommended
class NetworkPacket; 
	// Properties (Variables)
	int address;
	logic [63:0] data;
	shortint crc;
endclass : NetworkPacket // Best practice: naming the endclass makes large files readable

// 13.2) creating an instance of the class using lowercase / snake_case
NetworkPacket pkt_1; // Declares a variable pkt_1 of type NetworkPacket (but it's not an object yet)

initial begin
	// Construct the object in memory using new(). Must be inside a procedural block!
	pkt_1 = new(); 
	// We can now access the properties using the dot (.)
	pkt_1.address = 32'hA000; 
end

/* 13.3) Pro-Tip (The Shortcut): Modern SystemVerilog does allow you to declare 
		 and construct the object on the exact same line. 
		 If you do it this way, you are allowed to put it outside an initial block:
*/
NetworkPacket pkt_1 = new(); // Declares and constructs in one line!


/*  ---------- DIFFERENCE BETWEEN STRUCTS AND CLASSES ----------
	- Structs are Hardware (Static): When you declare a struct, the compiler physically
	  builds those wires and flip-flops in silicon. They exist from the moment the power turns on.
	- Classes are Software (Dynamic): Classes are used in testbenches. They do not 
	  represent physical hardware. They are software objects created and destroyed 
	  on the fly in your computer's RAM while the simulation runs.
*/




/* 14) --------------- packages: [Design & Verification] ---------------
		- The best place to store shared typedefs and enums so both our chip 
		  and our testbench agree on the definitions.
		- A package is a container for reusable code elements (typedefs, 
		  constants, functions, tasks, classes).
		- IMPORTANT: packages cannot contain hardware blocks (like modules or interfaces).
*/

// 14.1) Defining the Package
package my_package;
	typedef struct {
		int a;
		int unsigned b; 
		logic c;
	} my_struct_t;

	// BEST PRACTICE: Use 'automatic' for functions in packages too!
	function automatic int add(int x, int y);
		return x + y;
	endfunction

	task automatic print_struct(my_struct_t s);
		$display("a: %0d, b: %0d, c: %b", s.a, s.b, s.c);
	endtask : print_struct

endpackage : my_package


// 14.2) Using the Package (Importing)
module my_testbench;

	// Method 1: The Wildcard Import (Most Common)
	// Brings EVERYTHING from the package into this module
	import my_package::*; 

	// Method 2: Explicit Import (For strict namespaces)
	// Brings ONLY the specific item you ask for
	// import my_package::my_struct_t;

	my_struct_t test_var;

	initial begin
		test_var = '{10, 0, 1'b1};
		test_var.b = add(test_var.a, 5); // We can use the function directly because we imported it!
		print_struct(test_var); // We can use the task directly because we imported it!
	end

endmodule




/* 15)  --------------- arrays [Design & Verification] ---------------
		There are 2 types of arrays in SV: 
		- Packed arrays: arrays of 1 bit variables (like a bus or a vector).
		  Declaration: the size !!! before !!! the variable name.
		  Hardware: Built as one single, continuous, fat wire.
		- Unpacked arrays: used for creating arrays of variables (like an array of structs or classes).
		  Declaration: the size !!! after !!! the variable name.
		  Hardware: Built as separate, distinct registers.
*/

// 15.1) Packed array example (a 16-bit bus)
logic [15:0] bus = 16'h00AB; // bus[15] is the MSB 

// 15.2) Unpacked array example (an array of 4 integers)
int unpacked_array_1 [3:0] = '{3,2,1,0}; // left -> right is last_element -> first_element

/*  Note: The order of elements in the initializer list corresponds to the array indices,
	So for unpacked arrays we can go as follows: */
int unpacked_array_2 [0:3] = '{0,1,2,3}; // better practice to declare [lowest:highest] indices

/* 15.3) Multi-dimensional arrays
		 For example a packed array that creates a single 8-bit bus, 
		 divided logically into two 4-bit chunks*/ 
logic [1:0][3:0] packed_arr_2D = {4'hB,4'h0}; // 1011 0000

// 15.4) The same for unpacked multi-dimensional arrays
int unpacked_arr_2D [0:1][0:3] = '{'{0,1,2,4}, '{4,5,6,7}};


/* 15.5) Mixed packed and unpacked arrays.
		 We can combine packed and unpacked dimensions in the same declaration. 
		 When building FIFOs or RAM, we combine packed (width) and unpacked (depth).
		 Rule: Packed dimensions come first, Unpacked dimensions come last.
*/
// Creates a memory with 256 slots (unpacked), where each slot is 32 bits wide (packed).
logic [31:0] memory_buffer [0:255]='{default:0}; // 256 32-bit words initialized to 0



// 15.6) printing  arrays
initial begin

	// 1. Packed Arrays
	// To print a packed array, we can directly use $display with the %b flag
	$display("Packed Array (bus) = %b", bus); 
	// prints: Packed Array (bus) = 0000000010101011

	// Printing a multi-dimensional packed array (2D array)
	$display("2D Packed Array = %b", packed_arr_2D);
	//prints: 2D Packed Array = 10110000

	// 2. Unpacked Arrays
	// OLD WAY: To print an unpacked array, we need to loop through its elements
	for(int i=0;i<4;i++) begin
		$display("unpacked_array_1[%0d]:\tdecimal=%0d\tbinary=%2b", i, unpacked_array_1[i], unpacked_array_1[i]);
	end
	/*	prints:
			unpacked_array_1[0]:	decimal=0	binary=00
			unpacked_array_1[1]:	decimal=1	binary=01
			unpacked_array_1[2]:	decimal=2	binary=10
			unpacked_array_1[3]:	decimal=3	binary=11		
	*/

	// Modern SV: use the '%p' (pattern) flag to print unpacked array or a struct!
	$display("unpacked_array_2 = %p", unpacked_array_2);
	// NOTE: it prints:       unpacked_array_2 = '{0, 1, 2, 3} 

	// 3. Mixed Packed and Unpacked Arrays
	memory_buffer[0] = 32'hBEEF0000; // First lets assign a value (only within procedural block)
	$display("memory_buffer[0] = %h", memory_buffer[0]);
	//prints: memory_buffer[0] = beef0000

end

// 15.7) other mixed examples:

// Example A: 2D unpacked array of 8-bit packed elements
logic [7:0] mem1 [0:1][0:3] = '{
	'{8'h00, 8'h01, 8'h02, 8'h03}, // Unpacked row 0
	'{8'h04, 8'h05, 8'h06, 8'h07}  // Unpacked row 1
}; 

// Example B: 1D unpacked array of 2D packed elements
// Note: we use standard { } for the inner packed blocks, and '{ } for the outer unpacked array.
logic [3:0][7:0] mem2 [0:1] = '{
	{8'h00, 8'h01, 8'h02, 8'h03}, // Packed block 0
	{8'h04, 8'h05, 8'h06, 8'h07}  // Packed block 1
}; 

// Example C: The Ultimate Indexing Rule
// Assume the next array:
logic [2:0][7:0] mem3[3:0][4:0];

// we can access the single bit by:
initial begin
	// RULE: [Unpacked L->R] then [Packed L->R]
	logic single_bit = mem3[0][0][0][0]; // mem3[1st_unp][2nd_unp][1st_p][2nd_p]
end



