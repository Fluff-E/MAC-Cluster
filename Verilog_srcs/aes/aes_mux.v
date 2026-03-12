// combinational logic for selecting between key and plaintext inputs to the AES coprocessor
module aes_mux (
    input wire [31:0] key_in,
    input wire [31:0] ptext_in,
    input wire [1:0]  sel,
    output reg [31:0] mux_ctext_out
);


endmodule