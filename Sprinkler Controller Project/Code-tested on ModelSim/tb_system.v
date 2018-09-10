//-----------------------------------------------------
// Engineer: Muya Chang 
// Overview
//  A testbench to sprinkler system
//
// Design Name:   tb_System
// File Name:     tb_System.v
//
// History:       14 Feb. 2017, Muya Chang
//
//-----------------------------------------------------
module tb_System();
  // Testbench signals
  //Global
  reg clk;
  reg rst;
  //Rain Sensor
  reg raining;
  //GPS
  reg         gps_data_in_ready;
  reg  [7:0]  gps_data_in;
  wire        gps_data_valid_out;
  wire [47:0] gps_time_out;
  integer     gps_file;
  //SD Card
  wire        SD_read_next_line;
  wire        SD_data_valid;
  wire [1:0] SD_zone;
  wire [31:0] SD_start_time;
  wire [31:0] SD_stop_time;
  //With zones
  wire zone_0_out;
  wire zone_1_out;
  wire zone_2_out;
  wire zone_3_out; 
   
  initial begin
    $dumpfile("tb_system.vcd");
    $dumpvars();
    clk = 1'b0;
    #5 rst = 1'b1;
    #15 rst = 1'b0;

    // rain sensor
    raining = 1'b0;

    // gps
    gps_data_in_ready = 1'b0;
    gps_data_in = 1'd0;
    gps_file = $fopen("GPS_Serial_data_HW6.txt","r");
    if(gps_file == 0)
    begin
      $display("Error! Could not create result file");
      $finish;
    end
  end
 
// Modules instantiation
gps myGPS(
  .CLK(clk),
  .RxD_data_in_ready(gps_data_in_ready),
  .RxD_data_in(gps_data_in),
  .time_out(gps_time_out),
  .data_valid_out(gps_data_valid_out)
);

sdcard mySDCard(
  .read_next_line(SD_read_next_line),
  .data_valid(SD_data_valid),
  .zone(SD_zone),
  .start_time(SD_start_time),
  .stop_time(SD_stop_time),
  .rst(rst), //input wire rst,
  .clk(clk)
);

system mySystem(
  // With GPS Module
  .gps_time_reg(gps_time_out[47:16]),         //input wire [31:0] gps_time_reg;
  .gps_data_valid(gps_data_valid_out), //input wire gps_data_valid;

  // With Rain Sensor
  .raining(raining),                   //input wire raining;

  // With SD Card
  .SD_read_next_line(SD_read_next_line), //output wire SD_read_next_line;
  .SD_data_valid(SD_data_valid),        //input SD_data_valid
  .SD_zones(SD_zone),               //input wire [1:0] SD_zones;
  .SD_start_time(SD_start_time),         //input wire [31:0] SD_start_time;
  .SD_stop_time(SD_stop_time),           //input wire [31:0] SD_stop_time;

  // With zone controler
  .zone_0(zone_0_out), //output wire zone_0;
  .zone_1(zone_1_out), //output wire zone_1;
  .zone_2(zone_2_out), //output wire zone_2;
  .zone_3(zone_3_out), //output wire zone_3;

  // Global signal
  .rst(rst), //input wire rst,
  .clk(clk)  //input wire clk
);

  // Clock
  always #10 clk <= ~clk;

  // Parse GPS file
  always #50 @(negedge clk) begin
    if ($feof(gps_file)) begin
      $fclose(gps_file);
      $finish;
    end   
      gps_data_in = $fgetc(gps_file);
      gps_data_in_ready = 1'd1;

      #20
      gps_data_in_ready = 1'd0;
  end

endmodule
