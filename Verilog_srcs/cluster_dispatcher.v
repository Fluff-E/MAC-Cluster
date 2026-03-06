module cluster_dispatcher (
	input  wire       start,
	input  wire       busy,
	input  wire [1:0] cluster_sel,

	output wire [0:0] start_1c,
	output wire [1:0] start_2c,
	output wire [3:0] start_4c,
	output wire [7:0] start_8c
);

	wire fire_1c = start && !busy && (cluster_sel == 2'b00);
	wire fire_2c = start && !busy && (cluster_sel == 2'b01);
	wire fire_4c = start && !busy && (cluster_sel == 2'b10);
	wire fire_8c = start && !busy && (cluster_sel == 2'b11);

	assign start_1c = {1{fire_1c}};
	assign start_2c = {2{fire_2c}};
	assign start_4c = {4{fire_4c}};
	assign start_8c = {8{fire_8c}};

endmodule
