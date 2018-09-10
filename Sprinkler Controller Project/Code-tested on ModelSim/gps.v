module gps(CLK, RxD_data_in_ready, RxD_data_in, time_out, data_valid_out);
input CLK;
input RxD_data_in_ready;
input [7:0] RxD_data_in;

output wire [47:0] time_out;
output wire data_valid_out;


//=========================================================================================
//------- Create the mechanism to grab the serial data and parse it -----------------------
//=========================================================================================

// State Machine Variables
parameter ST_IDLE=0, ST_CHECK=1, ST_PARSE=2;
reg [2:0] PS=ST_IDLE;	//this is a register
reg [2:0] NS;	//this is the combinational output line driving the register.

// Local variables
reg [7:0] CHAR_CNT=0;
reg [23:0] NMEA=0;

// Data registers
reg [47:0] time_reg;
reg data_valid_reg;

// Signals that will drive the Data registers
reg [47:0] time_sig;
reg data_valid_sig;

// Internal Counter
integer index_counter = 0;
reg inc_index;	//increment flag
reg clr_index;	//clear flag

// CREATE THE COUNTING MECHANISM FOR PARSING THE SERIAL DATA
always @(posedge CLK) begin
	if(RxD_data_in_ready) begin				
		if(RxD_data_in=="$")begin // '$': Start of frame
			CHAR_CNT<=0;
		end
		else begin
			CHAR_CNT<=CHAR_CNT+1;	
		end
	end	
end

// CREATE A SHIFT REGISTER TO LOOK FOR THE GGA MESSAGE
always @(posedge CLK) begin
	if(RxD_data_in_ready) begin				
		NMEA[23:8]<=NMEA[15:0];
		NMEA[7:0]<=RxD_data_in; //Grab the tag info						
	end	
end

// Create a register block for the state variable
always @(posedge CLK) begin
	PS <= NS;
end

// Create a counter for the indexing of the output variable
always @(posedge CLK) begin
	if(clr_index)
		index_counter = 0;
	else if(inc_index)
		index_counter = index_counter + 8;	//the data comes in 8 bits at a time. So we increment by 8.
	else
		index_counter = index_counter;
end

// Create a register block for the outputs
always @(posedge CLK) begin
	time_reg <= time_sig;
	data_valid_reg <= data_valid_sig;
end

// CREATE THE MECHNISM THAT PARSES THE SERIAL DATA
always @(RxD_data_in_ready, CHAR_CNT, RxD_data_in, NMEA, time_reg, index_counter, PS) begin	
	//set the default conditions
	time_sig   = time_reg;
	data_valid_sig = 1'b0;
	inc_index = 1'b0;
	clr_index = 1'b0;
	NS = PS;
	
	//the state machine combinational logic
	casex({!RxD_data_in_ready, PS})		
		//---------------------------------------------------------------------------------
		4'b1xxx: begin	//data is not valid, so we are just going to wait.
			NS = PS;
		end
		//---------------------------------------------------------------------------------
		ST_IDLE: begin //Search for '$'		
			clr_index = 1'b1;
			if(RxD_data_in=="$")// '$': Start of frame	
				NS = ST_CHECK;
			else
				NS = ST_IDLE;
		end
		//---------------------------------------------------------------------------------
		ST_CHECK: begin //Check Tag, if not the proper tag go back to idle, else proceed to parse	
			clr_index = 1'b1;
			if({NMEA,RxD_data_in} == "GGA,")
				NS = ST_PARSE;	//Found the message we are looking for. 
								//Move to the next state
			else if(RxD_data_in == ",")
				NS = ST_IDLE;		//Wrong message, go back and search for the 
									//start of the next message.
			else
				NS = ST_CHECK;		//Wait for the complete message code to load
		end
		//---------------------------------------------------------------------------------
		ST_PARSE: begin //Parse the latitude and longitude		
			if(RxD_data_in==10) begin //LF: Line Feed, end of message, go to idle state					
				NS = ST_IDLE;
			end
			else begin	//valid data on the RxD_data_in line
				NS = ST_PARSE;				//stay in the current state
				if(CHAR_CNT>=6) begin
					if (CHAR_CNT<=11) begin
						inc_index = 1'b1;
						time_sig[(40-index_counter) +: 8] = RxD_data_in;
					end
					else begin
					data_valid_sig = 1'b1;
					clr_index = 1'b1;
					end			
				end
			end
		end	
		default: begin
			NS = ST_IDLE;
		end
	endcase		
end

//assign the outputs
assign time_out = time_reg;
assign data_valid_out = data_valid_reg;

endmodule

