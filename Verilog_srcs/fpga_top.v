module fpga_top(
    input pll_clk,
    input [9:0] sw,
    input [3:0] key,
    input [31:0] fpga_instruction,
    input [31:0] fpga_status,
    input [31:0] data_to_fpga,
    output [31:0] data_from_fpga,
    output [6:0] hex0,
    output [6:0] hex1,
    output [6:0] hex2,
    output [6:0] hex3,
    output [6:0] hex4,
    output [6:0] hex5,
    output [9:0] led
);

wire [23:0] hex_value;
wire [31:0] data_from_fpga_wire;

// Fabric command/data path
reg  [31:0] fpga_instruction_meta;
reg  [31:0] fpga_instruction_sync;
reg         start_prev;

wire         fabric_start_pulse;
wire [1:0]   fabric_cluster_sel;
wire [767:0] fabric_a_rows_flat;
wire [767:0] fabric_b_cols_flat;

wire         fabric_done;
wire         fabric_busy;
wire [1:0]   fabric_active_cluster_sel;
wire [31:0]  fabric_cycles_last;
wire [511:0] fabric_result_flat;

wire [31:0] data_from_fpga_mux;

assign data_from_fpga = data_from_fpga_wire;
assign data_from_fpga_wire = data_from_fpga_mux;

assign fabric_cluster_sel = fpga_instruction_sync[2:1];
assign fabric_start_pulse = fpga_instruction_sync[0] & ~start_prev;

// Temporary benchmark feed: replicate one 32-bit value into all A/B lanes.
assign fabric_a_rows_flat = {24{data_to_fpga}};
assign fabric_b_cols_flat = {24{data_to_fpga}};

always @(posedge pll_clk or negedge key[0]) begin
    if (!key[0]) begin
        fpga_instruction_meta <= 32'd0;
        fpga_instruction_sync <= 32'd0;
        start_prev <= 1'b0;
    end
    else begin
        fpga_instruction_meta <= fpga_instruction;
        fpga_instruction_sync <= fpga_instruction_meta;
        start_prev <= fpga_instruction_sync[0];
    end
end

cluster_readback_mux u_cluster_readback_mux (
    .readback_sel      (fpga_instruction_sync[4:3]),
    .cycles_last       (fabric_cycles_last),
    .result_flat       (fabric_result_flat),
    .busy              (fabric_busy),
    .done              (fabric_done),
    .active_cluster_sel(fabric_active_cluster_sel),
    .data_from_fpga    (data_from_fpga_mux)
);

ctrl control_unit (
    .pll_clk(pll_clk),
    .sw(sw),
    .key(key),
    .fpga_instruction(fpga_instruction),
    .fpga_status(fpga_status),
    .data_to_fpga(data_to_fpga),
    .data_from_fpga(data_from_fpga_wire),
    .hex_value(hex_value),
    .led(led)
);

cluster_fabric_structural u_cluster_fabric_structural (
    .clk               (pll_clk),
    .reset             (~key[0]),
    .start             (fabric_start_pulse),
    .cluster_sel       (fabric_cluster_sel),
    .a_rows_flat_in    (fabric_a_rows_flat),
    .b_cols_flat_in    (fabric_b_cols_flat),
    .done              (fabric_done),
    .busy              (fabric_busy),
    .active_cluster_sel(fabric_active_cluster_sel),
    .cycles_last       (fabric_cycles_last),
    .result_flat_out   (fabric_result_flat)
);

Hex6to7seg hex6 (
    .hex_value(hex_value),
    .HEX0(hex0),
    .HEX1(hex1),
    .HEX2(hex2),
    .HEX3(hex3),
    .HEX4(hex4),
    .HEX5(hex5)
);

endmodule