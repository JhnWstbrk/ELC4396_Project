`timescale 1ns / 1ps


module pitch_estimation(
	input logic clk,
	input logic rst,
	input logic [15:0] pcm,  // PCM input (adjust width based on your requirements)
    output logic [15:0] frequency  // Output frequency estimate
);

    logic [15:0] autocorrelation_result;
    logic [15:0] previous_pcm_sample = 16'h8000;  // Initial value (adjust based on your requirements)
    logic [15:0] max_autocorrelation = 16'h0;
    logic [15:0] max_delay = 16'h0;
    logic [15:0] current_delay = 16'h0;
	logic [5:0] counter = 0;
	logic [31:0] temp_frequency;

	always_ff @(posedge clk or posedge rst)
      if (rst)
         counter <= 0;
      else   
         counter <= counter + 1;
         
         
    always @(posedge clk) begin
    
        // Autocorrelation calculation
        autocorrelation_result <= autocorrelation_result + (pcm * previous_pcm_sample);

        // Update previous PCM sample
        previous_pcm_sample <= pcm;

        // Output frequency estimate and reset autocorrelation when needed
        if (counter[0] == 1) begin
            // Update delay and check for maximum autocorrelation
            if (autocorrelation_result > max_autocorrelation) begin
                max_autocorrelation <= autocorrelation_result;
                max_delay <= current_delay;
            end

            // Reset autocorrelation and delay for the next calculation
            autocorrelation_result <= 16'h0;
            current_delay <= 16'h0;
        end else begin
            // Increment delay for the next autocorrelation calculation
            current_delay <= current_delay + 1;
        end
        
    end
    
    always @* begin
		// Calculate frequency based on the maximum delay and sample period
		temp_frequency <= (1 << 12) / max_delay;
	end

	assign frequency = temp_frequency;
	
endmodule
