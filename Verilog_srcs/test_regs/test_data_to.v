module test_data_to(
	input wire [1:0] sel,
	output reg [31:0] value
);

always @(*) begin
	case (sel)
		2'b00: value = 32'h0011_2233;
		2'b01: value = 32'h4455_6677;
		2'b10: value = 32'h8899_AABB;
		2'b11: value = 32'hCCDD_EEFF;
		default: value = 32'h0011_2233;
	endcase
end

endmodule
