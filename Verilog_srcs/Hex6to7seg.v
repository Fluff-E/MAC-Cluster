module Hexto7seg(H, Seven);
    input [3:0] H;
    output [6:0] Seven;
    reg [6:0] store;

    always @(H) begin
        case (H)
            4'b0000: store <= 7'b1000000; // display 0
            4'b0001: store <= 7'b1111001; // display 1
            4'b0010: store <= 7'b0100100; // display 2
            4'b0011: store <= 7'b0110000; // display 3
            4'b0100: store <= 7'b0011001; // display 4
            4'b0101: store <= 7'b0010010; // display 5
            4'b0110: store <= 7'b0000010; // display 6
            4'b0111: store <= 7'b1111000; // display 7
            4'b1000: store <= 7'b0000000; // display 8
            4'b1001: store <= 7'b0010000; // display 9
            4'b1010: store <= 7'b0001000; // display A
            4'b1011: store <= 7'b0000011; // display B
            4'b1100: store <= 7'b1000110; // display C
            4'b1101: store <= 7'b0100001; // display D
            4'b1110: store <= 7'b0000110; // display E
            4'b1111: store <= 7'b0001110; // display F
        endcase
    end
    assign Seven = store;
endmodule

module Hex6to7seg(
    input [23:0] hex_value,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    Hexto7seg HEX_0(hex_value[3:0], HEX0);
    Hexto7seg HEX_1(hex_value[7:4], HEX1);
    Hexto7seg HEX_2(hex_value[11:8], HEX2);
    Hexto7seg HEX_3(hex_value[15:12], HEX3);
    Hexto7seg HEX_4(hex_value[19:16], HEX4);
    Hexto7seg HEX_5(hex_value[23:20], HEX5);
endmodule