// interfaces with eric_ip2 APB and creates top level for testing independent of HPS
module aes_top (
    input wire clk,
    input wire reset,
    input wire [31:0] instruction,
    output wire [31:0] status,
    input wire [127:0] key,
    input wire [127:0] ptext,
    output wire [127:0] ctext
);

wire [1:0] aes_mux_sel;

// Instantiate aes_ctrl.v
aes_ctrl u_aes_ctrl (
    .clk         (clk),
    .reset       (reset),
    .instruction (instruction),
    .status      (status),
    .aes_mux_sel (aes_mux_sel)
);

// Instantiate my_aes_coprocessor.v
my_aes128_coprocessor u_my_aes128_coprocessor (
    .key       (key),
    .ptext     (ptext),
    .ctext_aes (ctext)
);

endmodule