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

ctrl control_unit (
    .pll_clk(pll_clk),
    .sw(sw),
    .key(key),
    .fpga_instruction(fpga_instruction),
    .fpga_status(fpga_status),
    .data_to_fpga(data_to_fpga),
    .data_from_fpga(data_from_fpga),
    .hex_value(hex_value),
    .led(led)
);

//-- aes module -----------

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