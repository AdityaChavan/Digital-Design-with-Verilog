`timescale 1ns/1ps

/*
************************************************************
*	Engineer: 	Brothers, Timothy
*	Module:		simpleFIFO
*	Functionality:
*					this is a simple RAM based fifo.
*	Version History:
*		0.1		2017.03.03 T. Brothers
				File Create
************************************************************
*/

module simpleFIFO (
input	clk      	, // Clock input
input	reset    	, // Active high reset
input[7:0]data_in  	, // Data input
input	rd_ack_in 	, // Read acknowledge
input	wr_en_in 	, // Write Enable
output[7:0]data_out 	, // Data Output
output	empty_out	, // FIFO empty
output	full_out   	, // FIFO full
output	overflow_out  // The fifo was written when full
);    

//------------------------------------------------
// FIFO constants
//------------------------------------------------
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;
parameter RAM_DEPTH = (1 << ADDR_WIDTH);

//------------------------------------------------
// Port Declarations
//------------------------------------------------
//input wire clk;
//input wire reset;
//input wire rd_ack_in;
//input wire wr_en_in;
//input wire [DATA_WIDTH-1:0] data_in;
      
//output wire full_out;
//output wire empty_out;
//output wire [DATA_WIDTH-1:0] data_out;
//output wire overflow_out;

//------------------------------------------------
// Internal variables
//------------------------------------------------

//the RAM pointer and the counter for the number of samples in the FIFO
reg [ADDR_WIDTH-1:0] wr_pointer = 0;		
reg [ADDR_WIDTH-1:0] rd_pointer = 0;		
wire [ADDR_WIDTH-1:0] sample_count;	

//control signals for moving the pointers
wire inc_rd_sig;
wire inc_wr_sig;
wire clr_rd_sig;
wire clr_wr_sig;

//flags
reg full_reg = 1'b0;
reg full_sig;
reg empty_reg = 1'b1;	//the fifo starts out empty
reg empty_sig;
reg overflow_sig;
reg overflow_reg = 1'b0;

// variable to infer the RAM
reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];

//------------------------------------------------
// Assign the flags
//------------------------------------------------
assign full_out = full_reg;
assign empty_out = empty_reg;
assign overflow_out = overflow_reg;

//------------------------------------------------
// Address Pointers
//		There are two counters. One for the read
//		and one for the write pointer in the RAM
//------------------------------------------------
always @ (posedge clk)
begin : WRITE_POINTER
	if (reset)
		wr_pointer <= 0;
	else begin
		if (clr_wr_sig)
			wr_pointer <= 0;
		else if (inc_wr_sig)
			wr_pointer <= wr_pointer + 1;
		else
			wr_pointer <= wr_pointer;
	end
end

always @ (posedge clk)
begin : READ_POINTER
	if (reset)
		rd_pointer <= 0;
	else begin
		if (clr_rd_sig)
			rd_pointer <= 0;
		else if (inc_rd_sig) 
			rd_pointer <= rd_pointer + 1;
		else
			rd_pointer <= rd_pointer;
	end
end

//------------------------------------------------
// Combinational Logic
//------------------------------------------------

// Calculate the number of samples in the fifo.
assign sample_count = wr_pointer - rd_pointer;

// Determine the signal for the full register
always @ (*)
begin
	//default conditions
	overflow_sig = 1'b0;
	full_sig = full_reg;
	
	// Write but no read and the fifo is almost full.
	if (wr_en_in && !rd_ack_in && (sample_count == (RAM_DEPTH-1)))
		full_sig = 1'b1;	//at the next clock the fifo will be full.
	// Write but no read and the fifo is full.
	else if (wr_en_in && !rd_ack_in && full_reg) begin //the fifo is full and it is doing a write. Overflow!
		overflow_sig = 1'b1;
		full_sig = 1'b0;	//reset the full signal.
		end
	//it is not writing but it is reading with the fifo full
	else if (!wr_en_in && rd_ack_in && full_reg)	
		full_sig = 1'b0;	//the fifo will no longer be full.
	else begin	//default conditions just for fun.
		overflow_sig = 1'b0;
		full_sig = full_reg;
		end
end 

// Determine the signal for the empty register
always @ (*)
begin
	//default conditions
	empty_sig = empty_reg;
	
	// Read but no write and there is data in the fifo.
	if (overflow_sig)
		empty_sig = 1'b1;	//when we overflow we are going to reset the fifo.
	else if (rd_ack_in && !wr_en_in && (sample_count == 1))	//reading out the last sample of the fifo.
		empty_sig = 1'b1;	//at the next clock the fifo will be empty.
	// Write but no read and the FIFO is empty
	else if (wr_en_in && !rd_ack_in && empty_reg)
		empty_sig = 1'b0;	//the fifo will no longer be empty
	else	//default condition just for fun
		empty_sig = empty_reg;
end 

// Determine the signal to increment and clear the read and write pointers
assign inc_rd_sig = (rd_ack_in && !empty_reg);	//there is a read and the fifo is not empty.
assign inc_wr_sig = wr_en_in;	//always increment the write whenever there is data on the input line.
assign clr_rd_sig = overflow_sig;	//whenever there is an overflow we are going to reset the machine.
assign clr_wr_sig = overflow_sig;	//whenever there is an overflow we are going to reset the machine.

//------------------------------------------------
// Register blocks for output flags.
//------------------------------------------------
always @ (posedge clk)
begin
	if(reset) begin
		full_reg	 <= 1'b0;
		empty_reg	 <= 1'b1;	//when reset it is empty
		overflow_reg <= 1'b0;
		end
	else begin
		full_reg	 <= full_sig;
		empty_reg	 <= empty_sig;
		overflow_reg <= overflow_sig;
		end
end

//Assign output
assign full_out = full_reg;
assign empty_out = empty_reg;
assign overflow_out = overflow_reg;


//Infer a two port RAM
always @(posedge clk) begin
	if (wr_en_in)
		ram[wr_pointer] <= data_in;
	end

assign data_out = ram[rd_pointer];

endmodule
