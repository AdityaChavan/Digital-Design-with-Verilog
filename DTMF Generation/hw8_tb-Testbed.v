/*
************************************************************
*  Engineer:   Zajo, Joju Joseph
*  Module:    hw8 testbench
*  Functionality: Monitor audio output of DTMF generator
*                 and dump python script to generate .wav 
*  Version History:
*    0.1    File Created                02/27/2018
*    0.2    defines moved to defines.v  02/30/2018
*    0.3    System clock runs at PCM Sampling frequency  03/06/2018
************************************************************
*/

//defines.v should be modified to assign TCLK = 12500 ns
`include "./defines.v"

module hw8_tb;

//===========================================================
// PARAMETERS
//===========================================================
  parameter NUMBER_OF_SAMPLES = `NUMBER_OF_DIGITS*`SAMPLING_RATE*`TONE_DURATION/1000; //Testbench will log these many samples and stop simulation
 //   parameter NUMBER_OF_SAMPLES = 500; //Testbench will log these many samples and stop simulation
  parameter SAMPLING_PERIOD = 1000000000/`SAMPLING_RATE; //PCM sampling period
  parameter HALF_TCLK = `TCLK/2;
  parameter PLAY_ENABLE_TIME= `TCLK;
  //Changed in version 0.3:
  parameter SAMPLING_START_TIME= `TCLK*2; //multiple of TCLK based on latency of audio generation from time(play=1)
//===========================================================
// SIGNALS
//===========================================================  
  //DUT Inputs
  reg clk = 0;
  reg play;  //0 indicates disable, 1 indicates enable
  
  //DUT Outputs
  wire signed [`PCM_BITWIDTH-1:0] audio;        //DAC input generated from your code
  
  //Variables for reading and writing
  reg [30*8:1] file_name;
  integer i,f;
//===========================================================
// Code Body
//===========================================================
        
  //--------------------------------------------------------
  //Unit Under Test
  //--------------------------------------------------------
  hw8_top uut (
            .clk(clk),
            .play(play),
            .audio(audio)
          );
//ram ram1(clk,1,0,0,0,0);
  //--------------------------------------------------------
  //Testbed Signals
  //--------------------------------------------------------

  //Clock
  always #HALF_TCLK clk = clk+1;

  //Stimulus: switch on play button
  initial begin
	 play = 0;
	 #PLAY_ENABLE_TIME
	 play = 1;
  end

  //Dump python script to generate wav
  initial begin
	$sformat(file_name, "%s.py",`USER);
        f = $fopen(file_name,"w");
        
        //check to see if they were opened
        if(f==0) begin
          $display("Error! Unable to open the write file");
	  $stop;
        end
	
       #SAMPLING_START_TIME
	for(i=0;i<NUMBER_OF_SAMPLES;i=i+1) begin

       
          if(i==0)begin
	  //  $display("hello");
	    $fwrite(f,"import numpy as np\nfrom scipy.io.wavfile import write\n");
            $fwrite(f,"myarray=[%d",$signed(audio));
	  end
	  else begin
 	  //  $display("world");
            $fwrite(f,",%d",$signed(audio));
          end
	  #SAMPLING_PERIOD;
        end

    	$display("writing..");
        $fwrite(f,"]\n");
        $fwrite(f,"myarray=np.int16(np.array(myarray,dtype=float)*((2**(16-1))/(2**(%d-1))))\n",`PCM_BITWIDTH);
        $sformat(file_name, "%s.wav",`USER);
        $fwrite(f,"write('%s',%d,myarray)\n",file_name,`SAMPLING_RATE);
        $fclose(f);
        $stop;
  end
    
endmodule
