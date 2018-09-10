module tb_gps;
    reg        clk;
    reg        data_in_ready;
    reg[7:0]   data_in;
    wire       data_valid_out;
    wire[47:0] time_out;

    integer file;

    gps uut(clk, data_in_ready, data_in, time_out, data_valid_out);

    always #5 clk <= ~clk;

    initial
    begin
        data_in_ready = 8'd0;
        data_in = 1'd0;
        clk = 1'b0;
        file = $fopen("GPS_Serial_data_capture.txt","r");
        if(file == 0)
        begin
            $display("Error! Could not create result file");
            $finish;
        end
    end

    always@(posedge clk)
    begin
        if ($feof(file))
        begin
            $fclose(file);
            $stop;
        end   
        data_in = $fgetc(file);
        data_in_ready = 1'd1;
    end

endmodule
