module sdcard(
  input  clk,
  input  rst,
  input  read_next_line,
  output data_valid,
  output  [1:0] zone,
  output [31:0] start_time,
  output [31:0] stop_time
);

//-----------------------------------------------------
// PARAMETERS
//-----------------------------------------------------
parameter FILE_START=10;

//State Machine Variables
parameter ST_IDLE=0, ST_PARSE=1;
reg PS;
reg NS;

//-----------------------------------------------------
// SIGNALS
//-----------------------------------------------------
// buffers for output
reg         data_valid_reg;
reg  [15:0] zone_reg;
reg  [31:0] start_time_reg;
reg  [31:0] stop_time_reg;

// With RAM
reg         ram_en;
reg         ram_we;
reg   [7:0] ram_addr;
reg  [31:0] ram_din;
wire [31:0] ram_dout;

// State register
always @(posedge clk) begin
  if(rst)
    PS <= ST_IDLE;
  else
    PS <= NS;
end

always @(posedge clk) begin
  if(rst) begin
    ram_en  <= 1'b1;
    ram_we  <= 1'b0;
    ram_din <= 1'b0;
  end
  else begin
    ram_en  <= ram_en;
    ram_we  <= ram_we;
    ram_din <= ram_din;
  end
end

always @(posedge clk) begin
  case(PS)		
    ST_IDLE:
      ram_addr<=FILE_START;
    ST_PARSE:
      ram_addr<=ram_addr+1;
    default:
      ram_addr<=FILE_START;
  endcase		
end

always@(*) begin
  //-----------------------------------------------------
  // FILE FORMAT ="zone 01 0800 to 0900"; 
  //_______________----____----____----
  //________________0___1___2___3___4__
  
  // Zone
  if((ram_addr-2)%5==0)
    zone_reg=ram_dout;
  else
    zone_reg=zone_reg;

  // Start Time
  if((ram_addr-3)%5==0)
    start_time_reg=ram_dout;
  else
    start_time_reg=start_time_reg;

  // Stop Time
  if((ram_addr-5)%5==0)
    stop_time_reg=ram_dout;
  else
    stop_time_reg=stop_time_reg;
end

always@(*) begin
  case(PS)		
    ST_IDLE:
      data_valid_reg=0;
    ST_PARSE:
      if((ram_addr!=FILE_START)&&(ram_addr%5==0)&&(ram_addr!=0))
        data_valid_reg=1;
      else
        data_valid_reg=0;
    default:
      data_valid_reg=0;
  endcase		
end

always@(*)begin
  case(PS)		
    ST_IDLE: begin
      if(read_next_line)
        NS = ST_PARSE;
      else
        NS = PS;
    end
    ST_PARSE: begin
      if(read_next_line)
        NS = PS;
      else
        NS = ST_IDLE;
    end
    default: begin
      NS = ST_IDLE;
    end
  endcase		
end

// Wire assignments
assign zone=data_valid?zone_reg[1:0]:0;
assign start_time=data_valid?start_time_reg:0;
assign stop_time=data_valid?stop_time_reg:0;
assign data_valid=data_valid_reg;

//-----------------------------------------------------
// Memory Instantiation
//-----------------------------------------------------
ram myRam(
  .clk(clk),
  .en(ram_en),
  .we(ram_we),
  .addr(ram_addr),
  .din(ram_din),
  .dout(ram_dout)
);

endmodule
