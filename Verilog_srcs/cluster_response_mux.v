module cluster_response_mux (
	input  wire [1:0]   active_cluster_sel,

	input  wire [0:0]   done_1c,
	input  wire [1:0]   done_2c,
	input  wire [3:0]   done_4c,
	input  wire [7:0]   done_8c,

	input  wire [63:0]  result_1c,
	input  wire [127:0] result_2c,
	input  wire [255:0] result_4c,
	input  wire [511:0] result_8c,

	output reg          selected_done,
	output reg  [511:0] selected_result
);

	wire done_1c_all = &done_1c;
	wire done_2c_all = &done_2c;
	wire done_4c_all = &done_4c;
	wire done_8c_all = &done_8c;

	wire [511:0] result_1c_pad = {448'd0, result_1c};
	wire [511:0] result_2c_pad = {384'd0, result_2c};
	wire [511:0] result_4c_pad = {256'd0, result_4c};

	always @(*) begin
		case (active_cluster_sel)
			2'b00: begin
				selected_done   = done_1c_all;
				selected_result = result_1c_pad;
			end
			2'b01: begin
				selected_done   = done_2c_all;
				selected_result = result_2c_pad;
			end
			2'b10: begin
				selected_done   = done_4c_all;
				selected_result = result_4c_pad;
			end
			default: begin
				selected_done   = done_8c_all;
				selected_result = result_8c;
			end
		endcase
	end

endmodule
