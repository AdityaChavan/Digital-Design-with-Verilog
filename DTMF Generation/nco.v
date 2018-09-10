`include "./defines.v"
module nco(input clk,
input [15:0]freq,
output [15:0]sin
);
//===========================================================
// PARAMETERS
//===========================================================
parameter resolution = 100;
parameter samples=`SAMPLING_RATE*`TONE_DURATION/1000;
//===========================================================
// VARIABLES
//===========================================================
reg [4*4-1:0]lut[resolution-1:0];
integer i=0;
integer temp;
reg [4*4-1:0]f;
reg [4*4-1:0]stepsize;
reg [4*4-1:0]fs=`SAMPLING_RATE;
reg [4*4-1:0] sine[4*resolution-1:0];
reg [4*4-1:0] sinc;
integer step;
//===========================================================
// Code Body
//===========================================================
initial $readmemh("./LUT.hex", lut);


initial begin
temp=freq;
  for (i=0; i < resolution; i=i+1) begin
	sine[i]=lut[i];
	sine[2*resolution-1-i]=lut[i];
	sine[2*resolution+i]=-lut[i];
	sine[4*resolution-1-i]=-lut[i];
  end
end

always@(freq) begin
temp=freq;
end

always@(posedge clk) begin
	step=(i*temp/800*4)%(4*resolution);
	sinc=(sine[step]);
	i=i+1;
end

assign sin=(sinc);
endmodule
