module mac_cluster #(
	parameter integer NUM_CORES = 4
) (
	input  wire                          clk,
	input  wire                          reset,

	// Per-core start and done handshake
	input  wire [NUM_CORES-1:0]          start,
	output wire [NUM_CORES-1:0]          done,

	// Flattened per-core matrix row/column data (3x32 bits per core)
	input  wire [(NUM_CORES*96)-1:0]     a_rows_flat,
	input  wire [(NUM_CORES*96)-1:0]     b_cols_flat,

	// Flattened per-core result (64 bits per core)
	output wire [(NUM_CORES*64)-1:0]     result_flat
);

	genvar i;
	generate
		for (i = 0; i < NUM_CORES; i = i + 1) begin : gen_mac_core
			mac_3x3 u_mac_3x3 (
				.clk   (clk),
				.reset (reset),

				.start (start[i]),
				.done  (done[i]),

				.a0    ($signed(a_rows_flat[(i*96)+31 -: 32])),
				.a1    ($signed(a_rows_flat[(i*96)+63 -: 32])),
				.a2    ($signed(a_rows_flat[(i*96)+95 -: 32])),

				.b0    ($signed(b_cols_flat[(i*96)+31 -: 32])),
				.b1    ($signed(b_cols_flat[(i*96)+63 -: 32])),
				.b2    ($signed(b_cols_flat[(i*96)+95 -: 32])),

				.result(result_flat[(i*64)+63 -: 64])
			);
		end
	endgenerate

endmodule
