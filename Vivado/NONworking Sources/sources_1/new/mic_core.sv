`timescale 1ns / 1ps


module mic_core
	#(parameter N = 32)
	(
	input  logic clk,
    input  logic reset,
    // slot interface
    input  logic cs,
    input  logic read,
    input  logic write,
    input  logic [4:0] addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // external signal
    output logic mic_clk,
   	input logic mic_data,
   	output logic mic_LRsel
    );
    
    // signal declaration
	logic [N-1:0] data_reg;
	logic [4:0] clk_cntr_reg = 5'b0;
	logic [N-1:0] frequency = 16'd420;
	
	// FFT Signals
	logic [N-1:0] pcm_data = 16'b0;
	logic in_valid;
	logic in_last;
	logic in_ready;
	logic [7:0] config_data;
	logic config_valid;
	logic config_ready;
	logic [N-1:0] out_data;
	logic out_valid;
	logic out_last;
	logic out_ready;

	// body
	always_ff @(posedge clk, posedge reset)
	  if (reset)
		 data_reg <= 0;
	  else   
		 data_reg <= frequency;

	logic pcm_data_valid;
    pdm_2_pcm converter(
    	.clk(clk),
    	.rst(reset),
    	.mic_pcm_data(pcm_data),
    	.pcm_data_valid(pcm_data_valid),
    	.mic_clk(mic_clk),
    	.mic_pdm_data(mic_data),
    	.mic_lrsel(mic_LRsel)
    	);
    	
    // INSTANTIATE SAMPLE FRAME BLOCK RAM 
    // This 16x4096 bram stores the frame of samples
    // The write port is written by osample16.
    // The read port is read by the bram_to_fft module and sent to the fft.
    wire fwe;
    reg [11:0] fhead = 0; // Frame head - a pointer to the write point, works as circular buffer
    wire [15:0] fsample;  // The sample data from the XADC, oversampled 15x
    wire [11:0] faddr;    // Frame address - The read address, controlled by bram_to_fft
    wire [15:0] fdata;    // Frame data - The read data, input into bram_to_fft
    bram_frame bram1 (
        .clka(clk),
        .wea(pcm_data_valid),
        .addra(fhead),
        .dina(pcm_data),
        .clkb(clk),
        .addrb(faddr),
        .doutb(fdata));
    
    // SAMPLE FRAME BRAM WRITE PORT SETUP
    always @(posedge clk) if (pcm_data_valid) fhead <= fhead + 1;
    
    // INSTANTIATE BRAM TO FFT MODULE
    // This module handles the magic of reading sample frames from the BRAM whenever start is asserted,
    // and sending it to the FFT block design over the AXI-stream interface.
    wire last_missing; // All these are control lines to the FFT block design
    wire [31:0] frame_tdata;
    wire frame_tlast, frame_tready, frame_tvalid;
    bram_to_fft bram_to_fft_0(
        .clk(clk),
        .head(fhead),
        .addr(faddr),
        .data(fdata),
        .start(vsync_104mhz_pulse),
        .last_missing(last_missing),
        .frame_tdata(frame_tdata),
        .frame_tlast(frame_tlast),
        .frame_tready(frame_tready),
        .frame_tvalid(frame_tvalid)
    );
    
    // This is the FFT module, implemented as a block design with a 4096pt, 16bit FFT
    // that outputs in magnitude by doing sqrt(Re^2 + Im^2) on the FFT result.
    // It's fully pipelined, so it streams 4096-wide frames of frequency data as fast as
    // you stream in 4096-wide frames of time-domain samples.
    wire [23:0] magnitude_tdata; // This output bus has the FFT magnitude for the current index
    wire [11:0] magnitude_tuser; // This represents the current index being output, from 0 to 4096
    wire [11:0] scale_factor; // This input adjusts the scaling of the FFT, which can be tuned to the input magnitude.
    FFT_wrapper #(.N(32)) FFT(
    	.aclk(clk),
    	.aresetn(reset),
    	.in_data(pcm),
    	.in_valid(in_valid),
    	.in_last(),
    	.in_ready(),
    	.config_data(),
    	.config_valid(),
    	.config_ready(),
    	.out_data(),
    	.out_valid(),
    	.out_last(),
    	.out_ready()
    );
    
    bram_fft bram2 (
        .clka(clk_104mhz),
        .wea(in_range & magnitude_tvalid),  // Only save FFT output if in range and output is valid
        .addra(magnitude_tuser[9:0]),       // The FFT output index, 0 to 1023
        .dina(magnitude_tdata[15:0]),       // The actual FFT magnitude
        .clkb(clk_65mhz),  // input wire clkb
        .addrb(haddr),     // input wire [9 : 0] addrb
        .doutb(hdata)      // output wire [15 : 0] doutb
    );
    
    assign rd_data[N-1:0] = data_reg;
	assign rd_data[31:N] = 0;
	
endmodule
