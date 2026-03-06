module cluster_fabric_structural (
	input  wire         clk,
	input  wire         reset,

	// Command interface
	input  wire         start,
	input  wire [1:0]   cluster_sel,

	// Operand payload sized for max (8-core) cluster
	input  wire [767:0] a_rows_flat_in,
	input  wire [767:0] b_cols_flat_in,

	// Response / benchmark signals
	output reg          done,
	output reg          busy,
	output reg  [1:0]   active_cluster_sel,
	output reg  [31:0]  cycles_last,
	output reg  [511:0] result_flat_out
);

	reg [31:0] cycles_running;

	wire [0:0] start_1c;
	wire [1:0] start_2c;
	wire [3:0] start_4c;
	wire [7:0] start_8c;

	wire [0:0] done_1c;
	wire [1:0] done_2c;
	wire [3:0] done_4c;
	wire [7:0] done_8c;

	wire [63:0]  result_1c;
	wire [127:0] result_2c;
	wire [255:0] result_4c;
	wire [511:0] result_8c;

	wire         selected_done;
	wire [511:0] selected_result;

	cluster_dispatcher u_cluster_dispatcher (
		.start      (start),
		.busy       (busy),
		.cluster_sel(cluster_sel),
		.start_1c   (start_1c),
		.start_2c   (start_2c),
		.start_4c   (start_4c),
		.start_8c   (start_8c)
	);

	cluster_response_mux u_cluster_response_mux (
		.active_cluster_sel(active_cluster_sel),
		.done_1c           (done_1c),
		.done_2c           (done_2c),
		.done_4c           (done_4c),
		.done_8c           (done_8c),
		.result_1c         (result_1c),
		.result_2c         (result_2c),
		.result_4c         (result_4c),
		.result_8c         (result_8c),
		.selected_done     (selected_done),
		.selected_result   (selected_result)
	);

	mac_cluster #(
		.NUM_CORES(1)
	) u_cluster_1c (
		.clk        (clk),
		.reset      (reset),
		.start      (start_1c),
		.done       (done_1c),
		.a_rows_flat(a_rows_flat_in[95:0]),
		.b_cols_flat(b_cols_flat_in[95:0]),
		.result_flat(result_1c)
	);

	mac_cluster #(
		.NUM_CORES(2)
	) u_cluster_2c (
		.clk        (clk),
		.reset      (reset),
		.start      (start_2c),
		.done       (done_2c),
		.a_rows_flat(a_rows_flat_in[191:0]),
		.b_cols_flat(b_cols_flat_in[191:0]),
		.result_flat(result_2c)
	);

	mac_cluster #(
		.NUM_CORES(4)
	) u_cluster_4c (
		.clk        (clk),
		.reset      (reset),
		.start      (start_4c),
		.done       (done_4c),
		.a_rows_flat(a_rows_flat_in[383:0]),
		.b_cols_flat(b_cols_flat_in[383:0]),
		.result_flat(result_4c)
	);

	mac_cluster #(
		.NUM_CORES(8)
	) u_cluster_8c (
		.clk        (clk),
		.reset      (reset),
		.start      (start_8c),
		.done       (done_8c),
		.a_rows_flat(a_rows_flat_in),
		.b_cols_flat(b_cols_flat_in),
		.result_flat(result_8c)
	);

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			done               <= 1'b0;
			busy               <= 1'b0;
			active_cluster_sel <= 2'b00;
			cycles_running     <= 32'd0;
			cycles_last        <= 32'd0;
			result_flat_out    <= 512'd0;
		end
		else begin
			done <= 1'b0;

			if (start && !busy) begin
				busy               <= 1'b1;
				active_cluster_sel <= cluster_sel;
				cycles_running     <= 32'd0;
			end
			else if (busy) begin
				cycles_running <= cycles_running + 32'd1;
			end

			if (busy && selected_done) begin
				busy            <= 1'b0;
				done            <= 1'b1;
				cycles_last     <= cycles_running;
				result_flat_out <= selected_result;
			end
		end
	end

endmodule
