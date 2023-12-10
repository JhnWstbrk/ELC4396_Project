`timescale 1ns / 1ps



module pdm_2_pcm_test();
	reg clk;
	reg rst;
	
	wire [31:0] mic_pcm_data;
	wire pcm_data_valid;
	
	wire mic_clk;
	reg mic_pdm_data;
	wire mic_lrsel;
	
	// Instantiate the pdm_2_pcm module
	pdm_2_pcm pdm_pcm_inst (
		.*
	);
	
	reg [99:0] sample_data;
	
	// Clock generation
	assign clk = 0;
	initial begin
		forever #5 clk = ~clk;
	end
	
	//real clk_period = 1.0 / 100e6;
	int i = 99;

	initial begin
		sample_data[99:0] = 100'b0101011011110111111111111111111111011111101101101010100100100000010000000000000000000001000010010101;
		//sample_data[99:0] = 100'b0101101111111111111101101010010000000000000100010011011101111111111111011010100100000000000000100101;
		rst = 1;
		mic_pdm_data = 0;
		#10;
		rst = 0;
		forever @(posedge(mic_clk)) begin
			mic_pdm_data = sample_data[i];
			if (i > 0) begin
				i--;
			end else begin
				i = 99;
			end
		end
	end
	
endmodule
