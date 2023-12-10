//==================================================================
// R: # reolution bit
// duty signal needs 1 extra bit
//   * e.g., 8- bit resolution need 2^8+1 values (0, 1, 2, ..., 
// DIV: frequency Divider 
//   * tick_freq = pwm_freq * (2^resolution_bit) 
//   * DIV = system_freq / tick_freq 
//   * use 32-bit freq divider
//==================================================================
// register map
// 0x10 to 0x1f for pwm duty cycles
// 0x00 for frequency divisor 
//==================================================================

module chu_io_pwm_core
   #(parameter W = 6,  // width (# bits) of output port
               R = 10  // # bits of PWM resolution (i.e., 2^R levels) // How long the wave is
   )  
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
    output logic [W-1:0] pwm_out // custom output, seperate pwms each with own duty cycle
   );

   // signal declaration
   logic [R:0] duty_2d_reg [W-1:0]; // stores numbers for how fast each pwm will change
   logic duty_array_en, dvsr_en; // counters
   logic [31:0] q_reg;
   logic [31:0] q_next; // baud or the tick
   logic [R-1:0] d_reg; // wave
   logic [R-1:0] d_next;
   logic [R:0] d_ext;
   logic [W-1:0] pwm_reg;
   logic [W-1:0] pwm_next;
   logic tick;
   logic [31:0] dvsr_reg; 

   //*****************************************************************
   // wrapping circuit
   //*****************************************************************
   //  decoding 
   assign duty_array_en = cs && write && addr[4]; // are you talking to me?
   assign dvsr_en = cs && write && addr==5'b00000; 
   // register for divisor
   always_ff @(posedge clk, posedge reset)
      if (reset)	// flip flops don't have to have a reset
         dvsr_reg <= 0;
      else   
         if (dvsr_en)
            dvsr_reg <= wr_data;
   // register file for duty cycles 
   always_ff @(posedge clk)
      if (duty_array_en)
         duty_2d_reg[addr[3:0]] <= wr_data[R:0];
   //*****************************************************************
   //  multi-bit PWM 
   //*****************************************************************
   always_ff @(posedge clk, posedge reset) // compact, 
      if (reset) begin			// would be better to pick a not-reset value
         q_reg <= 0;			// 
         d_reg <= 0;
         pwm_reg <= 0;
      end 
      else begin				// convention not liked because it generates tick pulses like crazy
         q_reg <= q_next;		// system will count faster
         d_reg <= d_next;
         pwm_reg <= pwm_next;
     end
   // "prescale" counter
   assign q_next = (q_reg==dvsr_reg) ? 0 : q_reg + 1;
   assign tick = q_reg==0;
   // duty cycle counter
   assign d_next = (tick) ? d_reg + 1 : d_reg;
   assign d_ext = {1'b0, d_reg};
   // comparison circuit
   generate
     genvar i;		// three types of generates
     for (i=0; i<W; i=i+1) begin		// code for us is describing a circuit, not something that is run
       assign pwm_next[i] = d_ext < duty_2d_reg[i];		// if you can't draw your circuit, you don't know what you're making
     end
   endgenerate
   assign pwm_out = pwm_reg;	// you can write to it but no read from it
   // read data not used 
   assign rd_data = 32'b0 ;
endmodule

