// eric_ip.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module eric_ip (
		input  wire [3:0]  aps_s0_paddr,   // aps_s0.paddr
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
	wire [3:0] addr;

	assign addr = aps_s0_paddr;
	assign aps_s0_pready = 1'b1; // slave always ready, no wait states
	assign aps_s0_prdata = data_temp;

	always @ (posedge clock_clk)
	begin
		if (aps_s0_psel && (~aps_s0_pwrite) && aps_s0_pready)
		begin
			case(addr)
				4'b0000 : data_temp <= data_out[0];
				4'b0001 : data_temp <= data_out[1];
				4'b0010 : data_temp <= data_out[2];
				4'b0011 : data_temp <= data_out[3];
				4'b0100 : data_temp <= data_out[4];
				4'b0101 : data_temp <= data_out[5];
				4'b0110 : data_temp <= data_out[6];
				4'b0111 : data_temp <= data_out[7];
				4'b1000 : data_temp <= data_out[8];
				4'b1001 : data_temp <= data_out[9];
				4'b1010 : data_temp <= data_out[10];
				4'b1011 : data_temp <= data_out[11];
				4'b1100 : data_temp <= data_out[12];
				4'b1101 : data_temp <= data_out[13];
				4'b1110 : data_temp <= data_out[14];
				4'b1111 : data_temp <= data_out[15];
				default : data_temp <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			endcase
		end
	end

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
		else if (aps_s0_psel && aps_s0_pwrite && aps_s0_pready)
		begin
			case(addr)
				4'b0000 : data_out[0] <= aps_s0_pwdata;
				4'b0001 : data_out[1] <= aps_s0_pwdata;
				4'b0010 : data_out[2] <= aps_s0_pwdata;
				4'b0011 : data_out[3] <= aps_s0_pwdata;
				4'b0100 : data_out[4] <= aps_s0_pwdata;
				4'b0101 : data_out[5] <= aps_s0_pwdata;
				4'b0110 : data_out[6] <= aps_s0_pwdata;
				4'b0111 : data_out[7] <= aps_s0_pwdata;
				4'b1000 : data_out[8] <= aps_s0_pwdata;
				4'b1001 : data_out[9] <= aps_s0_pwdata;
				4'b1010 : data_out[10] <= aps_s0_pwdata;
				4'b1011 : data_out[11] <= aps_s0_pwdata;
				4'b1100 : data_out[12] <= aps_s0_pwdata;
				4'b1101 : data_out[13] <= aps_s0_pwdata;
				4'b1110 : data_out[14] <= aps_s0_pwdata;
				4'b1111 : data_out[15] <= aps_s0_pwdata;
			endcase
		end
	end

endmodule
