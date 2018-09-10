`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Aditya
// 
// Create Date:    21st April
// Design Name: 
// Module Name:    hw11_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module hw11_top(
input						clk,
input[7:0]						R,
input[7:0]						G,
input[7:0]						B,
input						HS,
input						VS,
output[7:0]						out_pixel,
output						out_pixel_valid
						
    );

parameter counter_wid = 32;
	
	//--------------------------------------------------------
	//Image Details
	//--------------------------------------------------------
	parameter bit_depth = 32'd8;
	parameter rows = 32'd512;
	parameter cols = 32'd512;

	//--------------------------------------------------------
	//VGA Details
	//--------------------------------------------------------
	parameter VGA_pixels = 32'd800;
	parameter VGA_lines = 32'd600;
	
	//Horizontal Sync Details
	parameter HS_front_porch = 32'd40;
	parameter HS_back_porch = 32'd88;
	
		
	//Vertical Sync Details
	parameter VS_front_porch = 32'd1;
	parameter VS_back_porch = 32'd23;
	

wire [bit_depth-1:0] fifo1;
wire fifo1_empty;
wire fifo1_full;
wire fifo1_overflow;


wire [bit_depth-1:0] fifo2;
wire fifo2_empty;
wire fifo2_full;
wire fifo2_overflow;

reg [7:0] shift_reg_1[0:2];
reg [7:0] shift_reg_2[0:2];
reg [7:0] shift_reg_3[0:2];


reg [17:0]Gx;
reg [17:0]Gy;
reg [17:0]Gx_mag;
reg [17:0]Gy_mag;

reg [18:0]sum;
reg delay1;
reg delay2;
reg delay3;

parameter WAITSTATE 		= 0;
parameter FRONTPORCHSTATE 	= 1;
parameter ACTIVESTATE 		= 2;
parameter BACKPORCHSTATE	= 3;
	
reg[2:0] PS=0;
reg[2:0] NS=0;	
reg[2:0] PS_v=0;
reg[2:0] NS_v=0;	

//SIGNALS.........................................................................................................................................................

//Pixel Counter
	reg [counter_wid-1:0] pixel_counter = 0;
	reg pixel_enable = 0;
	reg pixel_valid = 0;
	
	reg HS_reg;

//Line Counter
	reg [counter_wid-1:0] line_counter = 0;
	reg line_enable = 0;
	reg line_valid = 0;
	
	reg VS_reg;

	always @(posedge clk or HS or VS) begin
		HS_reg = HS;
		VS_reg = VS;
	end

	always @(posedge clk or HS_reg)
	pixel_counter=pixel_enable?(pixel_counter+1):(pixel_counter);
	
	always@(HS_reg)
	line_counter=HS_reg?line_counter:line_counter+1;
	
	always@(posedge clk) begin
	PS <= NS;
	PS_v <= NS_v;
	end
	
	always @ (*) begin
		case (PS)
			WAITSTATE: begin
				pixel_enable = 0;
				pixel_counter = 0;
				pixel_valid = 0;
				NS=HS_reg?WAITSTATE:BACKPORCHSTATE;
			end
			
			
			BACKPORCHSTATE: begin
				pixel_valid = 0;
				
				if(HS_reg == 1) begin
					pixel_enable = 1; 
					NS=(pixel_counter < HS_back_porch)?BACKPORCHSTATE:ACTIVESTATE;
				end
				else begin
					NS = BACKPORCHSTATE;
				end
					
					
			end
				
			ACTIVESTATE: begin
				pixel_enable = 1;
				
				if(pixel_counter <= (VGA_pixels + HS_back_porch)) begin
					pixel_valid=(pixel_counter >= HS_back_porch && pixel_counter <= (HS_back_porch+cols)) ?1:0;
					NS=ACTIVESTATE;
				end
				else begin
					pixel_valid = 0;
					NS = FRONTPORCHSTATE;			
				end
			end
			
			FRONTPORCHSTATE: begin
				pixel_enable = 1;
				
				if(pixel_counter <= (HS_back_porch + VGA_pixels + HS_front_porch)) begin
					pixel_valid = 0;
					NS = FRONTPORCHSTATE;
				end
				else begin
					pixel_counter = 0;
					NS = WAITSTATE;
				end
			end
		endcase
	end
	
always @ (*) begin
	case (PS_v)
		WAITSTATE: begin
			line_enable = 0;
			line_counter = 0;
			line_valid = 0;
		if(VS_reg == 0) begin
				NS_v = BACKPORCHSTATE;
			end
			
			else begin
				NS_v = WAITSTATE;
			end
								
		end
		BACKPORCHSTATE: begin
		
			if(VS_reg== 1) begin
			line_enable = 1;
			
				if(line_counter == VS_back_porch) begin
					if(pixel_counter == (HS_back_porch + VGA_pixels + 3)) begin
					line_valid = 1;
					NS_v = BACKPORCHSTATE;
					end
				end
					
					
				end
				else begin
				line_enable = 0;
				line_counter = 0;
				line_valid = 0;
				NS_v = BACKPORCHSTATE;
				end
				
										
					
			end	
		endcase
	end	
	
wire image_pixel_valid = line_valid && pixel_valid;	
	
wire read_fifo1 = image_pixel_valid && fifo1_full;

reg[31:0] shiftreg_full = 0;
wire [7:0] data_fifo1;
wire [7:0] data_fifo2;


//module simpleFIFO (	clk reset data_in  rd_ack_in   wr_en_in 	  data_out 	empty_out 	full_out    overflow_out 
simpleFIFO f1(		clk, 	,	R, read_fifo1 ,image_pixel_valid, data_fifo1 ,	empty_fifo1, 	fifo1_full, fifo1_overflow);

simpleFIFO f2(		clk, 	,data_fifo1, image_pixel_valid&fifo2_full, image_pixel_valid&fifo1_full, data_fifo2, fifo2_empty, fifo2_full, fifo2_overflow);
	
always @(posedge clk) begin

	//3 SR for 3 lines of data
	if(image_pixel_valid) begin
	shift_reg_1[2] <= shift_reg_1[1];
	shift_reg_1[1] <= shift_reg_1[0];
	shift_reg_1[0] <= R;
	end
	else begin
	shift_reg_1[2] <= shift_reg_1[2];
	shift_reg_1[1] <= shift_reg_1[1];
	shift_reg_1[0] <= shift_reg_1[0];
	end
	
	if(image_pixel_valid && fifo1_full) begin
	shift_reg_2[2] <= shift_reg_2[1];
	shift_reg_2[1] <= shift_reg_2[0];
	shift_reg_2[0] <= data_fifo1;
	end
	else begin
	shift_reg_2[2] <= shift_reg_2[2];
	shift_reg_2[1] <= shift_reg_2[1];
	shift_reg_2[0] <= shift_reg_2[0];
	end
	
	if(image_pixel_valid && fifo2_full) begin
	shift_reg_3[2] <= shift_reg_3[1];
	shift_reg_3[1] <= shift_reg_3[0];
	shift_reg_3[0] <= data_fifo2;
	
	shiftreg_full <= shiftreg_full + 1;
	
	end
	else begin
	shift_reg_3[2] <= shift_reg_3[2];
	shift_reg_3[1] <= shift_reg_3[1];
	shift_reg_3[0] <= shift_reg_3[0];
	
	shiftreg_full <= 0;
	end
	

end

always @(*) begin

	if(shiftreg_full > 2) begin
	Gx = (shift_reg_1[2] + 3'd2*shift_reg_1[1] + shift_reg_1[0]) - (shift_reg_3[2] + 3'd2*shift_reg_3[1] + shift_reg_3[0]);
	Gy = (shift_reg_3[0] + 3'd2*shift_reg_2[0] + shift_reg_1[0]) - (shift_reg_3[2] + 3'd2*shift_reg_2[2] + shift_reg_1[2]);
	Gx_mag = (Gx[17])? ~Gx+1'b1:Gx;
	Gy_mag = (Gy[17])? ~Gy+1'b1:Gy;
	
	sum = Gx_mag + Gy_mag;
	
	end
	else begin
	sum = 10;//error
	end


end
	
always @(posedge clk) begin
delay1 <= image_pixel_valid;
delay2 <= delay1;
delay3 <= delay2;

end
	
	assign out_pixel = (sum > 32'd127)? 8'd255 : 8'd0;
//	assign out_pixel = sum;
	assign out_pixel_valid = delay2;
			
endmodule	
	
