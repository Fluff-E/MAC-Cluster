// my_aes_ip.v

//implemented as a register vector read/write
//Radu Muresan, March 2022

`timescale 1 ps / 1 ps
module my_aes_ip (
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

	reg [31:0] data_out [0:3];
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
				4'b0100 : data_temp <= data_out[1];
				4'b1000 : data_temp <= data_out[2];
				4'b1100 : data_temp <= data_out[3];
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
		end
		else if (aps_s0_psel && aps_s0_pwrite && aps_s0_pready)
		begin
			case(addr)
				4'b0000 : data_out[0] <= aps_s0_pwdata;
				4'b0100 : data_out[1] <= aps_s0_pwdata;
				4'b1000 : data_out[2] <= aps_s0_pwdata;
				4'b1100 : data_out[3] <= aps_s0_pwdata;
			endcase
		end
	end

endmodule
