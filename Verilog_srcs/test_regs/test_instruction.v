module test_instruction(
	input wire [1:0] sel,
	output reg [31:0] value
);

always @(*) begin
	case (sel)
		2'b00: value = 32'h0000_0000;
		2'b01: value = 32'h0000_0001;
		2'b10: value = 32'hA5A5_0001;
		2'b11: value = 32'h5A5A_0002;
		default: value = 32'h0000_0000;
	endcase
end

endmodule
