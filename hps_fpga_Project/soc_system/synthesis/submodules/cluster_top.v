// interfaces with eric_ip2 APB and creates top level for testing independent of HPS
module cluster_top (
    input wire clk,
    input wire reset,
    input wire [31:0] instruction,
    output wire [31:0] status,
    input wire [31:0] data_rx_0,
    input wire [31:0] data_rx_1,
    input wire [31:0] data_rx_2,
    input wire [31:0] data_rx_3,
    input wire [31:0] data_rx_4,
    input wire [31:0] data_rx_5,
    input wire [31:0] data_rx_6,
    input wire [31:0] data_rx_7,
    input wire [31:0] data_rx_8,
    input wire [31:0] data_rx_9,
    input wire [31:0] data_rx_10,
    input wire [31:0] data_rx_11,
    output wire [31:0] data_tx_0_lo,
    output wire [31:0] data_tx_0_hi,
    output wire [31:0] data_tx_1_lo,
    output wire [31:0] data_tx_1_hi,
    output wire [31:0] data_tx_2_lo,
    output wire [31:0] data_tx_2_hi,
    output wire cluster_tx_state
);

wire [63:0] mac_result_0;
wire [63:0] mac_result_1;
wire [63:0] mac_result_2;
wire mac_done_0;
wire mac_done_1;
wire mac_done_2;
wire [2:0] mac_status;
wire mac_start;

assign mac_status = {mac_done_2, mac_done_1, mac_done_0};

cluster_ctrl u_cluster_ctrl (
    .clk(clk),
    .reset(reset),
    .instruction(instruction),
    .mac_status(mac_status),
    .status(status),
    .mac_start(mac_start),
    .cluster_tx_state(cluster_tx_state)
);

mac_2x2 u_mac_0 (
    .clk(clk),
    .reset(reset),
    .start(mac_start),
    .done(mac_done_0),
    .a0(data_rx_0),
    .a1(data_rx_1),
    .b0(data_rx_2),
    .b1(data_rx_3),
    .result(mac_result_0)
);

mac_2x2 u_mac_1 (
    .clk(clk),
    .reset(reset),
    .start(mac_start),
    .done(mac_done_1),
    .a0(data_rx_4),
    .a1(data_rx_5),
    .b0(data_rx_6),
    .b1(data_rx_7),
    .result(mac_result_1)
);

mac_2x2 u_mac_2 (
    .clk(clk),
    .reset(reset),
    .start(mac_start),
    .done(mac_done_2),
    .a0(data_rx_8),
    .a1(data_rx_9),
    .b0(data_rx_10),
    .b1(data_rx_11),
    .result(mac_result_2)
);

assign data_tx_0_lo = mac_result_0[31:0];
assign data_tx_0_hi = mac_result_0[63:32];
assign data_tx_1_lo = mac_result_1[31:0];
assign data_tx_1_hi = mac_result_1[63:32];
assign data_tx_2_lo = mac_result_2[31:0];
assign data_tx_2_hi = mac_result_2[63:32];

endmodule