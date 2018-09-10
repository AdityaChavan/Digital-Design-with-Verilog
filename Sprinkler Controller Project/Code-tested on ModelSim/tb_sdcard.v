module tb_sdcard;
reg clk=0;
integer i=0;
//reg [7:0]address;
reg read_next_line=0;
wire read_enable;
wire [15:0]zone;
wire [31:0]start_time;
wire[31:0]stop_time;
integer j=0;

always #5 clk <= ~clk;
initial begin
//address=8'd0;
j=0;
end
sdcard uut(clk,read_next_line,read_enable,zone,start_time,stop_time);


always @(posedge clk) begin
if(read_next_line==0) begin
j=j+1;
read_next_line=1;
end
end

//always @(negedge clk) begin

//end
  
always @(read_enable) begin
if(read_enable) begin
$display("Zone:%s,Start:%s,Stop:%s,en:%d,",zone,start_time,stop_time,read_enable);
$display(".%d\t",i);

//read_next_line=0;
i=i+1;
end
end

always@(i) begin
if(i>10) begin
//$display("%d",i);
$stop;
end
end

endmodule

