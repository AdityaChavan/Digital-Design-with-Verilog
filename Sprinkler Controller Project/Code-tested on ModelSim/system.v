module system(
  // With GPS Module
  input wire [31:0] gps_time_reg,
  input wire gps_data_valid,

  // With Rain Sensor
  input wire raining,

  // With SD Card
  output wire SD_read_next_line,
  input wire SD_data_valid,
  input wire [1:0] SD_zones,
  input wire [31:0] SD_start_time,
  input wire [31:0] SD_stop_time,

  // With zone controler
  output reg zone_0,
  output reg zone_1,
  output reg zone_2,
  output reg zone_3,

  // Global signal
  input wire rst,
  input wire clk
);

parameter TCLK=10;
parameter INSP_PERIOD=600;
parameter LINE_NUMBER=4;
parameter MIDNIGHT=32'h32340000;

// State Machine Variables
parameter ST_IDLE=0, ST_INSP=1;
reg  PS;
reg  NS;

// Local registers
reg zone_0_reg;
reg zone_1_reg;
reg zone_2_reg;
reg zone_3_reg;

// Internal Counter
integer time_counter = 0;
reg clr_time;	//clear flag

integer line_counter = 0;
reg inc_line;	//increment flag
reg clr_line;	//clear flag

integer rain_counter = 0;
reg inc_rain;	//increment flag
reg clr_rain;	//clear flag

// Counters
always @(posedge clk) begin : TIME_COUNTER
  if(rst || clr_time)
    time_counter<=0;
  else
    time_counter<=time_counter+TCLK;
end

always @(posedge clk) begin : RAIN_COUNTER
  if(rst || clr_rain)
    rain_counter<=0;
  else if(inc_rain)
    rain_counter<=rain_counter+1;
  else
    rain_counter<=rain_counter;
end

always @(posedge clk) begin : LINE_COUNTER
  if(rst || clr_line)
    line_counter<=0;
  else if(inc_line && SD_data_valid)
    line_counter<=line_counter+1;
  else
    line_counter<=line_counter;
end

always @(posedge clk) begin : ZONE_CONTROLLER 
  if(rst) begin
    zone_0 <= 0;
    zone_1 <= 0;
    zone_2 <= 0;
    zone_3 <= 0;
  end
  else if(SD_data_valid) begin
    zone_0 <= (SD_zones==0)?zone_0_reg:zone_0;
    zone_1 <= (SD_zones==1)?zone_1_reg:zone_1;
    zone_2 <= (SD_zones==2)?zone_2_reg:zone_2;
    zone_3 <= (SD_zones==3)?zone_3_reg:zone_3;
  end
end
// State register
always @(posedge clk) begin
  if(rst)
    PS <= ST_IDLE;
  else
    PS <= NS;
end

// FSM Controller
always @(*) begin	
  case(PS)		
    //---------------------------------------------------------------------------------
    ST_IDLE: begin // Wait for the time to reach certain period
      if(time_counter==INSP_PERIOD)
        NS = ST_INSP;
      else
        NS = PS;
    end
    //---------------------------------------------------------------------------------
    ST_INSP: begin //
      if(line_counter==LINE_NUMBER)// Finish inspecting all lines
        NS = ST_IDLE;
      else
        NS = PS;
    end
    //---------------------------------------------------------------------------------
    default: begin
      NS = ST_IDLE;
    end
  endcase		
end

// Counter Signal Controller
always @(*) begin	
  // Default values for all the control signals
  clr_time = 1'b0;
  inc_line = 1'b0;
  clr_line = 1'b0;
  inc_rain = 1'b0;
  clr_rain = 1'b0;
  case(PS)		
    //---------------------------------------------------------------------------------
    ST_IDLE: begin // Wait for the time to reach certain period
    end
    //---------------------------------------------------------------------------------
    ST_INSP: begin //
      inc_line = 1'b1;
      if(line_counter==LINE_NUMBER) begin// Finish inspecting all lines
        clr_time = 1'b1;
        clr_line = 1'b1;
      end
      else begin
        if(gps_time_reg < SD_start_time || gps_time_reg >= SD_stop_time)
          if(raining)
            inc_rain = 1'b1;
      end
    end
    //---------------------------------------------------------------------------------
    default: begin
    end
  endcase	
end

// Zone Signal Controller
always @(*) begin	
  // Default values for all the control signals
  zone_0_reg = 1'b0;
  zone_1_reg = 1'b0;
  zone_2_reg = 1'b0;
  zone_3_reg = 1'b0;
  case(PS)		
    //---------------------------------------------------------------------------------
    ST_IDLE: begin // Wait for the time to reach certain period
    end
    //---------------------------------------------------------------------------------
    ST_INSP: begin //
      if(~raining) begin
        if( ((SD_start_time > SD_stop_time) && 
            ((gps_time_reg >= SD_start_time && gps_time_reg < MIDNIGHT) ||  
             (gps_time_reg  < SD_stop_time && gps_time_reg >= MIDNIGHT))) || 
            (gps_time_reg >= SD_start_time && gps_time_reg < SD_stop_time-rain_counter) ) begin
          case(SD_zones)
            2'b00:
              zone_0_reg = 1'b1;
            2'b01:
              zone_1_reg = 1'b1;
            2'b10:
              zone_2_reg = 1'b1;
            2'b11:
              zone_3_reg = 1'b1;
          endcase
        end
      end
    end
    //---------------------------------------------------------------------------------
    default: begin
    end
  endcase		
end

// Wire assignement
assign SD_read_next_line = inc_line;

endmodule // System

