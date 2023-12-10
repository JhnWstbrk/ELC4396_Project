`timescale 1ns / 1ps


module mic_core_wrapper
	(
		input wire [15:0] fft_in,
		output wire [15:0] pcm
	);

	// Instantiation of the SystemVerilog module
	mic_core mic_core_inst (
		.fft_in(fft_in),
		.pcm(pcm)
	);

endmodule
