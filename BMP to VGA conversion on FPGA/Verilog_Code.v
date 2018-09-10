`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Aditya
// 
// Create Date:    04/11/2018 
// Design Name: 
// Module Name:    hw10_top 
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
module hw10_top(
						clk,
						R,
						G,
						B,
						HS,
						VS,
						out_pixel,
						out_pixel_valid
    );
	
//Inputs
input clk;
input [7:0] R, G, B;
input HS, VS;

//Outputs
output [7:0] out_pixel;
output out_pixel_valid;

//parameters
parameter backporch=1;
parameter frontporch=3;
parameter actualimage=5;
parameter displayimage=2;
parameter syncpulse=4;

//LOL this works:
//assign out_pixel=R;
//assign out_pixel_valid=(R>0)?1'b1:1'b0;

integer counter;
reg out_valid;
reg [1:0]NS;
reg [1:0]PS;
integer output1;
integer counterVS=0;

always @(posedge clk) begin
counter=counter+1;

if((R>0)&&(out_valid!=1)&&(counterVS<512))
$display("%d:   %d",counterVS, counter);

if(counter<88)//backporch
NS=backporch;

else if (counter<(88+512))//image
NS=displayimage;

else if (counter<(88+800+40)) //frontporch
NS=frontporch;

else NS=syncpulse; //sync

PS=NS;
end //pos clk
assign out_pixel=R*output1;
assign out_pixel_valid=out_valid*(R>0?1:0);


always @(posedge HS) begin
counter=0;
counterVS=counterVS+1;

end

always @(PS,out_valid)
case(PS)
(backporch): begin
out_valid=0;
output1=0;

end

(displayimage): begin 
out_valid=1'b1;
output1=1'b1;
end

(actualimage): begin 
out_valid=0;
output1=0;
end

(frontporch): begin
out_valid=0; 
output1=0;
end

(syncpulse): begin  
out_valid=0; 
output1=0;
end

default: begin  
out_valid=0; 
output1=0;
end
endcase

endmodule
