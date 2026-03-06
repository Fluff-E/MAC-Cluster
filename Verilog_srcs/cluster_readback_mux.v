module cluster_readback_mux (
    input  wire [1:0]  readback_sel,
    input  wire [31:0] cycles_last,
    input  wire [511:0] result_flat,
    input  wire        busy,
    input  wire        done,
    input  wire [1:0]  active_cluster_sel,
    output reg  [31:0] data_from_fpga
);

    always @(*) begin
        case (readback_sel)
            2'b00: data_from_fpga = cycles_last;
            2'b01: data_from_fpga = result_flat[31:0];
            2'b10: data_from_fpga = result_flat[63:32];
            default: data_from_fpga = {28'd0, busy, done, active_cluster_sel};
        endcase
    end

endmodule
