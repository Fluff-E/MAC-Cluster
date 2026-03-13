module simple_counter(CLOCK_50, counter_out);
input CLOCK_50;
output reg [31:0] counter_out;

always@(posedge CLOCK_50) begin
	counter_out <= #1 counter_out + 1; // in simulation incriment after 1 clock edge
	end
endmodule
