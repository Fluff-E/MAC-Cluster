// eric_ip2.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module eric_ip2 (
		input  wire [5:0]  aps_s0_paddr,   // aps_s0.paddr
		input  wire        aps_s0_psel,    //       .psel
		input  wire        aps_s0_penable, //       .penable
		input  wire        aps_s0_pwrite,  //       .pwrite
		input  wire [31:0] aps_s0_pwdata,  //       .pwdata
		output wire [31:0] aps_s0_prdata,  //       .prdata
		output wire        aps_s0_pready,  //       .pready
		input  wire        clock_clk,      //  clock.clk
		input  wire        reset_reset     //  reset.reset
	);

	reg [31:0] data_out [0:15];
	reg [31:0] data_temp;
	wire [5:0] addr;
	wire [31:0] instruction;
	wire [31:0] aes_status;
	wire [127:0] key;
	wire [127:0] ptext;
	wire [127:0] aes_ctext;

	assign addr = aps_s0_paddr;
	assign aps_s0_pready = 1'b1; // slave always ready, no wait states
	assign aps_s0_prdata = data_temp;

	// Drive nets for aes_top module inputs and outputs.
	assign instruction = data_out[0];
	assign key = {data_out[5], data_out[4], data_out[3], data_out[2]};
	assign ptext = {data_out[9], data_out[8], data_out[7], data_out[6]};

	// APB Read logic: read from data_out registers on APB read.
	always @ (posedge clock_clk)
	begin
		if (aps_s0_psel && (~aps_s0_pwrite) && aps_s0_pready)
		begin
			case(addr)
				6'b000000 : data_temp <= data_out[0];
				6'b000100 : data_temp <= data_out[1];
				6'b001000 : data_temp <= data_out[2];
				6'b001100 : data_temp <= data_out[3];
				6'b010000 : data_temp <= data_out[4];
				6'b010100 : data_temp <= data_out[5];
				6'b011000 : data_temp <= data_out[6];
				6'b011100 : data_temp <= data_out[7];
				6'b100000 : data_temp <= data_out[8];
				6'b100100 : data_temp <= data_out[9];
				6'b101000 : data_temp <= data_out[10];
				6'b101100 : data_temp <= data_out[11];
				6'b110000 : data_temp <= data_out[12];
				6'b110100 : data_temp <= data_out[13];
				6'b111000 : data_temp <= data_out[14];
				6'b111100 : data_temp <= data_out[15];
				default : data_temp <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			endcase
		end
	end

	// APB Write logic: write to data_out registers on APB write.
	always @ (posedge clock_clk or posedge reset_reset)
	begin
		if(reset_reset == 1)
		begin
			data_out[0] <= 32'b00000000000000000000000000000000;
			data_out[1] <= 32'b00000000000000000000000000000000;
			data_out[2] <= 32'b00000000000000000000000000000000;
			data_out[3] <= 32'b00000000000000000000000000000000;
			data_out[4] <= 32'b00000000000000000000000000000000;
			data_out[5] <= 32'b00000000000000000000000000000000;
			data_out[6] <= 32'b00000000000000000000000000000000;
			data_out[7] <= 32'b00000000000000000000000000000000;
			data_out[8] <= 32'b00000000000000000000000000000000;
			data_out[9] <= 32'b00000000000000000000000000000000;
			data_out[10] <= 32'b00000000000000000000000000000000;
			data_out[11] <= 32'b00000000000000000000000000000000;
			data_out[12] <= 32'b00000000000000000000000000000000;
			data_out[13] <= 32'b00000000000000000000000000000000;
			data_out[14] <= 32'b00000000000000000000000000000000;
			data_out[15] <= 32'b00000000000000000000000000000000;
		end
		else
		begin
			// Capture AES outputs into APB-visible status/ciphertext registers.
			data_out[1]  <= aes_status;
			data_out[10] <= aes_ctext[31:0];
			data_out[11] <= aes_ctext[63:32];
			data_out[12] <= aes_ctext[95:64];
			data_out[13] <= aes_ctext[127:96];

			if (aps_s0_psel && aps_s0_pwrite && aps_s0_pready)
			begin
			case(addr)
			6'b000000 : data_out[0]  <= aps_s0_pwdata;
			//6'b000100 : data_out[1]  <= aps_s0_pwdata;
			6'b001000 : data_out[2]  <= aps_s0_pwdata;
			6'b001100 : data_out[3]  <= aps_s0_pwdata;
			6'b010000 : data_out[4]  <= aps_s0_pwdata;
			6'b010100 : data_out[5]  <= aps_s0_pwdata;
			6'b011000 : data_out[6]  <= aps_s0_pwdata;
			6'b011100 : data_out[7]  <= aps_s0_pwdata;
			6'b100000 : data_out[8]  <= aps_s0_pwdata;
			6'b100100 : data_out[9]  <= aps_s0_pwdata;
			//6'b101000 : data_out[10] <= aps_s0_pwdata;
			//6'b101100 : data_out[11] <= aps_s0_pwdata;
			//6'b110000 : data_out[12] <= aps_s0_pwdata;
			//6'b110100 : data_out[13] <= aps_s0_pwdata;
			6'b111000 : data_out[14] <= aps_s0_pwdata;
			6'b111100 : data_out[15] <= aps_s0_pwdata;	
			endcase
			end
		end
	end

	// APB register map follows hps_code/main.c offsets.
	aes_top u_aes_top (
		.clk         (clock_clk),
		.reset       (reset_reset),
		.instruction (instruction),
		.status      (aes_status),
		.key         (key),
		.ptext       (ptext),
		.ctext       (aes_ctext)
	);

endmodule
