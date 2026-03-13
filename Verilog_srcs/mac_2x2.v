module mac_2x2 (
	input  wire         clk,
	input  wire         reset,

	// Handshake
	input  wire         start,
	output reg          done,

	// Matrix A row ai
	input  wire signed [31:0] a0,
	input  wire signed [31:0] a1,

	// Matrix B column bi
	input  wire signed [31:0] b0,
	input  wire signed [31:0] b1,

	// Output Matrix O entry oi
	output reg signed [63:0] result
);

	reg busy;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			result <= 0;
			done   <= 0;
			busy   <= 0;
		end
		else begin

			// Start computation
			if (start && !busy) begin
				busy <= 1;
				done <= 0;
			end

			// One-cycle dot product
			else if (busy) begin
				result <=
					(a0 * b0) +
					(a1 * b1);

				done <= 1;
				busy <= 0;
			end

			// Clear done once start is lowered
			if (!start)
				done <= 0;
		end
	end

endmodule
