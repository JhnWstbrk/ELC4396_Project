`timescale 1ns / 1ps


module FFT_wrapper#(parameter N = 32) // width of input data
   (
	input aclk,
	input aresetn,
	
	input [N-1:0] in_data,
	input in_valid,
	input in_last,
	output in_ready,
	
	input [7:0] config_data,
	input config_valid,
	output config_ready,
	
	output [N-1:0] out_data,
	output out_valid,
	output out_last,
	input out_ready
    );
    
    wire [63:0] data_fft;
    assign data_fft[63:N] = 'd0;
    assign data_fft[N-1:0] = in_data;
    
    wire [63:0] out_fft;
    
    wire
    event_frame_started,
    event_tlast_unexpected,
    event_tlast_missing,
    event_status_channel_halt,
    event_data_in_channel_halt,
    event_data_out_channel_halt;
    
    
    FFT PCM_FFT (
		.aclk(aclk),                                                // input wire aclk
		.aresetn(aresetn),
		
		.s_axis_config_tdata(config_data),                  // input wire [15 : 0] s_axis_config_tdata
		.s_axis_config_tvalid(config_valid),                // input wire s_axis_config_tvalid
		.s_axis_config_tready(config_ready),                // output wire s_axis_config_tready
		
		.s_axis_data_tdata(data_fft),                      // input wire [31 : 0] s_axis_data_tdata
		.s_axis_data_tvalid(in_valid),                    // input wire s_axis_data_tvalid
		.s_axis_data_tready(in_ready),                    // output wire s_axis_data_tready
		.s_axis_data_tlast(in_last),                      // input wire s_axis_data_tlast
		
		.m_axis_data_tdata(out_fft),                      // output wire [31 : 0] m_axis_data_tdata
		.m_axis_data_tvalid(out_valid),                    // output wire m_axis_data_tvalid
		.m_axis_data_tready(out_ready),                    // input wire m_axis_data_tready
		.m_axis_data_tlast(out_last),                      // output wire m_axis_data_tlast
		
		.event_frame_started(event_frame_started),                  // output wire event_frame_started
		.event_tlast_unexpected(event_tlast_unexpected),            // output wire event_tlast_unexpected
		.event_tlast_missing(event_tlast_missing),                  // output wire event_tlast_missing
		.event_status_channel_halt(event_status_channel_halt),      // output wire event_status_channel_halt
		.event_data_in_channel_halt(event_data_in_channel_halt),    // output wire event_data_in_channel_halt
		.event_data_out_channel_halt(event_data_out_channel_halt)  // output wire event_data_out_channel_halt
	);

assign out_data = out_fft[N-1:0];
endmodule
