`timescale 1ns / 1ps


module FFT_wrapper_test;
// Inputs
  reg aclk;
  reg aresetn;
  
  reg [31:0] in_data;
  reg in_valid;
  reg in_last;
  wire in_ready;
  
  reg [7:0] config_data;
  reg config_valid;
  wire config_ready;
  
  // Outputs
  wire [31:0] out_data;
  wire out_valid;
  wire out_last;
  reg out_ready;
  
  reg [31:0] input_data [15:0];
  
  integer i;

  // Instantiate the FFT_wrapper module
  FFT_wrapper FFT_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .in_data(in_data),
    .in_valid(in_valid),
    .in_last(in_last),
    .in_ready(in_ready),
    .config_data(config_data),
    .config_valid(config_valid),
    .config_ready(config_ready),
    .out_data(out_data),
    .out_valid(out_valid),
    .out_last(out_last),
    .out_ready(out_ready)
  );

  // Clock generation
	initial begin
		forever #5 aclk = ~aclk;
	end
	
	// Stimulus
	initial begin
		// Initialize inputs
		aclk = 0;
		aresetn = 0;
		in_data = 16'h0000;
		in_valid = 0;
		in_last = 0;
		config_data = 8'h00;
		config_valid = 0;
		out_ready = 1'b1;
	end
    
    initial begin
    	#70;
    	aresetn = 1;
    	
    	input_data[0] = 32'b00100101100011010011000100110010;
		input_data[1] = 32'b00111111001111100011111010111101;
		input_data[2] = 32'b00111111011111101001100011111101;
		input_data[3] = 32'b00111111000101100111100100011000;
		input_data[4] = 32'b10111110010101001110011011001101;
		input_data[5] = 32'b10111111010111011011001111010111;
		input_data[6] = 32'b10111111011100110111100001110001;
		input_data[7] = 32'b10111110110100000011111111001001;
		input_data[8] = 32'b00111110110100000011111111001001;
		input_data[9] = 32'b10111110110100000011111111001001;
		input_data[10] = 32'b10111111010111011011001111010111;
		input_data[11] = 32'b10111110010101001110011011001101;
		input_data[12] = 32'b00111111000101100111100100011000;
		input_data[13] = 32'b00111111011111101001100011111101;
		input_data[14] = 32'b00111111001111100011111010111101;
		input_data[15] = 32'b00100101100011010011000100110010;
	end
	
	initial begin // Config Data initial block
		#100;
		config_data = 1; // 1: Forward FFT
		#5 config_valid = 1;
		
		while(config_ready == 0) begin
			config_valid = 1;
		end
		#5 config_valid = 0;
	end
	
	initial begin
		#100
		for(i = 15; i>=0; i=i-1) begin
			#10
			if(i == 0) begin
				in_last = 1'b1;
			end
			in_data = input_data[i];
			in_valid = 1'b1;
			
			while (in_ready == 0) begin
				in_valid = 1'b1;
			end
		end
		#10;
		in_valid = 1'b0;
		in_last = 1'b0;
	end
	
	initial begin
		#100
		
		wait(out_valid == 1);
		#300 out_ready = 1'b0;
	end
	
	
endmodule
