module ram(
  input clk,
  input we,
  input en,
  input [7:0] addr,
  input [31:0] din,
  output reg [31:0] dout
);
 
  //-----------------------------------------------------
  // FILE FORMAT ="zone 01 0800 to 0900"; 
  //_______________----____----____----
  //________________0___1___2___3___4__
  //______________5 reads for each line
  //_____________________________________________________

  reg [31:0] RAM [127:0];
  integer i;
  parameter init=10;

  initial begin
    for(i=0;i<128;i=i+1)
      RAM[i] = 0;

    RAM[init+0]="zone";
    RAM[init+1]="0000";
    RAM[init+2]="0800";
    RAM[init+3]="  to";
    RAM[init+4]="0900";

    RAM[init+5]="zone";
    RAM[init+6]="0001";
    RAM[init+7]="1000";
    RAM[init+8]="  to";
    RAM[init+9]="1100";

    RAM[init+10]="zone";
    RAM[init+11]="0002";
    RAM[init+12]="1200";
    RAM[init+13]="  to";
    RAM[init+14]="1300";

    RAM[init+15]="zone";
    RAM[init+16]="0003";
    RAM[init+17]="2300";
    RAM[init+18]="  to";
    RAM[init+19]="0100";
  end

always@(posedge clk) begin
  if (en) begin
    if (we)
      RAM[addr]<=din;
    dout <= RAM[addr];
  end
end

endmodule
