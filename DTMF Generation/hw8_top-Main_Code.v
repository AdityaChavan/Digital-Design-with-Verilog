`include "./defines.v"

/*
************************************************************
*  Engineer:   Aditya Chavan
*  Module:    DTMF Generator
*  Functionality: Check numbers.hex file
*                 Generate freq corresponding to given number.
*		  LUT is 12 bit wide, shift audio by 10 bits	(to account for carry bit (13th bit) and sign bit(14th bit))
*		  In numbers.hex store * as 2A and # as 23 (ASCII Format).
************************************************************
*/

module hw8_top(
input wire clk, 
input wire play, 
output reg [`PCM_BITWIDTH-1:0] audio //0 to 23
);
//===========================================================
// PARAMETERS
//===========================================================
parameter samples=`SAMPLING_RATE*`TONE_DURATION/1000;
//===========================================================
// SIGNALS
//===========================================================  
//variables for the NCO
wire [4*4-1:0]sin1;
wire [4*4-1:0]sin2;
reg[15:0] sin_temp;	//NCO 1 output
reg[15:0] sin_temp2;	//NCO 2 output
reg [15:0]freq1;
reg [15:0]freq2;

//Variables for the RAM
reg [5:0]addr1;
wire [5:0]addr;
wire[15:0]do;		//RAM output
wire[15:0]di;
reg en1;
reg we1;

//misc variables 
integer i=0;
integer count=1;
//===========================================================
// Instantiation
//===========================================================
ram ram1(clk,en,we,addr,di,do);
nco nco1(clk,freq1,sin1);
nco nco2(clk,freq2,sin2);

//===========================================================
// Code Body
//===========================================================
initial begin
en1=1;
we1=0;
i=0;
addr1=0;
case(do)
0: begin freq1=941 ;freq2=1336 ; end
1: begin freq1=697 ;freq2=1209 ; end
2: begin freq1=697 ;freq2=1336 ; end
3: begin freq1=697 ;freq2=1477 ; end
4: begin freq1=770 ;freq2=1209 ; end
5: begin freq1=770 ;freq2=1336 ; end
6: begin freq1=770 ;freq2=1477 ; end
7: begin freq1=852 ;freq2=1209 ; end
8: begin freq1=852 ;freq2=1336 ; end
9: begin freq1=852 ;freq2=1477 ; end
"2A": begin freq1=941 ;freq2=1209 ; end //ASCII FOR * is 42 / 2A
"23": begin freq1=941 ;freq2=1477 ; end //ASCII FOR # is 35 / 23
default: begin freq1=100 ;freq2=100 ; end //invalid
endcase
end

always@(i) begin
  en1=1;
  we1=0;
case(do)
  0: begin freq1=941 ;freq2=1336 ; end
  1: begin freq1=697 ;freq2=1209 ; end
  2: begin freq1=697 ;freq2=1336 ; end
  3: begin freq1=697 ;freq2=1477 ; end
  4: begin freq1=770 ;freq2=1209 ; end
  5: begin freq1=770 ;freq2=1336 ; end
  6: begin freq1=770 ;freq2=1477 ; end
  7: begin freq1=852 ;freq2=1209 ; end
  8: begin freq1=852 ;freq2=1336 ; end
  9: begin freq1=852 ;freq2=1477 ; end
  "*": begin freq1=941 ;freq2=1209 ; end //ASCII FOR * is 2A. Use that in numbers.hex
  "#": begin freq1=941 ;freq2=1477 ; end //ASCII FOR # is 23. 
  default: begin freq1=101 ;freq2=101 ; end //invalid
endcase
	if(i==samples)begin //at every 24000 values,
	  addr1=count;
	  i=0;
	  count=count+1;
	end
end

always@(posedge clk)begin
	if((play)) begin
	  en1=1;
	  sin_temp=sin1;
 	  sin_temp2=sin2;
  audio <= ((sin_temp+sin_temp2)<< (`PCM_BITWIDTH-14) ); //check description
  i=i+1;
   	end
end

assign addr=addr1;
assign en=1;
assign we=we1;
endmodule