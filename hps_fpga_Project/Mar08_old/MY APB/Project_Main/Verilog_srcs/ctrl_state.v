module controller (
    input clk, selectorC, selector, reset_key, load_key, encrypt_key, encrypt_done,
	 input [3:0] load_count,
	 input [7:0] byte0,
	 input [7:0] byte1,
    input [127:0] ptext,
    input [127:0] ctext,
    input [2:0] sel,
    output reg [15:0] Hex_value,
	 output reg done, reset, load, encrypt // state indicators
);

	// STATES: RESET, LOAD, ENCRYPT, DONE/DISPLAY

	always @(posedge(clk)) begin
		if (encrypt_done == 1) begin 
			if (selector == 1) begin // Selector SW 9
				if (selectorC == 0 ) begin // SelectorC Sw 8
						Hex_value[3:0] = ptext[sel*16     +: 4];
						Hex_value[7:4] = ptext[sel*16 +4  +: 4];
						Hex_value[11:8] = ptext[sel*16 +8  +: 4];
						Hex_value[15:12] = ptext[sel*16 +12 +: 4];

				end else if (selectorC == 1) begin
						Hex_value[3:0] = ctext[sel*16     +: 4];
						Hex_value[7:4] = ctext[sel*16 +4  +: 4];
						Hex_value[11:8] = ctext[sel*16 +8  +: 4];
						Hex_value[15:12] = ctext[sel*16 +12 +: 4];
				end
			end 
		end
		else begin
			Hex_value[3:0] = byte0[3:0];
			Hex_value[7:4] = byte0[7:4];
			Hex_value[11:8] = byte1[3:0];
			Hex_value[15:12] = byte1[7:4];
		end

		done	<= (encrypt_done | ~encrypt_key) & reset_key;
		reset <= reset_key;
		load	<= ~done & reset & encrypt & reset_key;
		
	end

endmodule