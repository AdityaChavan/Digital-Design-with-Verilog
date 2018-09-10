module ram(clk,en,we,addr,di,do);

input clk;
input we;
input en;
input[5:0]addr;
input[15:0]di;

output[15:0]do;

reg[15:0] RAM[63:0];
reg[15:0] do;

initial $readmemh("./number.hex", RAM);

always@(posedge clk) begin
  if(en) begin
    if(we)
      RAM[addr]<=di;
    do<=RAM[addr];
  end
end

///*read and display the values from the text file on screen*/ 
integer i;
initial begin
  $display("rdata:");
  for (i=0; i < 12; i=i+1)
  $display("%d:%h",i,RAM[i]);
end

endmodule
