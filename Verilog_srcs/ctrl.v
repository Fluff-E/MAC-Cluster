module ctrl(
	input wire        pll_clk,
	input wire [9:0]  sw,
	input wire [3:0]  key,
	input wire [31:0] fpga_instruction,
	input wire [31:0] fpga_status,
	input wire [31:0] data_to_fpga,
	input wire [31:0] data_from_fpga,
	output reg [23:0] hex_value,
	output wire [9:0] led
);

reg [3:0] key_meta;
reg [3:0] key_sync;
reg [3:0] key_prev;

reg [31:0] fpga_instruction_meta;
reg [31:0] fpga_instruction_sync;
reg [31:0] fpga_status_meta;
reg [31:0] fpga_status_sync;

reg [31:0] data_to_fpga_reg;
reg [31:0] data_from_fpga_reg;

wire reset_n;
wire load_pulse;
wire manual_step_pulse;
wire update_enable;

assign reset_n = key_sync[0];

assign load_pulse = key_prev[1] & ~key_sync[1];
assign manual_step_pulse = key_prev[3] & ~key_sync[3];
assign update_enable = sw[9] ? manual_step_pulse : 1'b1;

always @(posedge pll_clk) begin
	key_meta <= key;
	key_sync <= key_meta;
	key_prev <= key_sync;
end

always @(posedge pll_clk) begin
	fpga_instruction_meta <= fpga_instruction;
	fpga_instruction_sync <= fpga_instruction_meta;
	fpga_status_meta <= fpga_status;
	fpga_status_sync <= fpga_status_meta;
end

always @(posedge pll_clk) begin
	if (!reset_n) begin
		data_to_fpga_reg <= 32'h0000_0000;
		data_from_fpga_reg <= 32'h0000_0000;
	end else if (update_enable || load_pulse) begin
		data_to_fpga_reg <= data_to_fpga;
		data_from_fpga_reg <= data_from_fpga;
	end
end

always @(*) begin
	if (sw[1] == 1'b0 && sw[0] == 1'b0)
		hex_value = fpga_status_sync[23:0];
	else if (sw[1] == 1'b0 && sw[0] == 1'b1)
		hex_value = fpga_instruction_sync[23:0];
	else if (sw[1] == 1'b1 && sw[0] == 1'b0)
		hex_value = data_from_fpga_reg[23:0];
	else
		hex_value = data_to_fpga_reg[23:0];
end

assign led[9:6] = fpga_instruction_sync[3:0];
assign led[5:2] = fpga_status_sync[3:0];
assign led[1] = fpga_status_sync[1]; // ready
assign led[0] = fpga_status_sync[0]; // done

endmodule

/*
-- ctrl ----------------------------
   manual clock mode on/off (SW[9])
   reset (KEY[0])
   load init/test data (KEY[1])
   manual clock (KEY[3])
   
   does synchronization of the fpga_instruction and fpga_status signals
   SWs controls mux for the 7-segment display hex_value output
      - shows fpga_instruction when SW[0] is on
      - shows fpga_status when SW[0] is off  
      - shows data_to_fpga when SW[1] is on
      - shows data_from_fpga when SW[1] is off


   // Need to implement handshake template in C
   LED [9:6] fpga_instruction[4:0]
   LED [5:2] fpga_status[4:0]

   LED [1] ready
   LED [0] done
*/