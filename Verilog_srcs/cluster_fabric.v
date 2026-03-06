module cluster_fabric (
    input  wire         clk,
    input  wire         reset,

    // Command interface
    input  wire         start,
    input  wire [1:0]   cluster_sel,   // 2'b00=1 core, 2'b01=2 cores, 2'b10=4 cores, 2'b11=8 cores

    // Operand payload sized for max (8-core) cluster
    input  wire [767:0] a_rows_flat_in,
    input  wire [767:0] b_cols_flat_in,

    // Response / benchmark signals
    output reg          done,
    output reg          busy,
    output reg  [1:0]   active_cluster_sel,
    output reg  [31:0]  cycles_last,
    output reg  [511:0] result_flat_out
);

    reg [31:0] cycles_running;

    // One-cycle launch pulse for the selected cluster when fabric is idle
    wire fire_1c = start && !busy && (cluster_sel == 2'b00);
    wire fire_2c = start && !busy && (cluster_sel == 2'b01);
    wire fire_4c = start && !busy && (cluster_sel == 2'b10);
    wire fire_8c = start && !busy && (cluster_sel == 2'b11);

    wire [0:0] start_1c = {1{fire_1c}};
    wire [1:0] start_2c = {2{fire_2c}};
    wire [3:0] start_4c = {4{fire_4c}};
    wire [7:0] start_8c = {8{fire_8c}};

    wire [0:0] done_1c;
    wire [1:0] done_2c;
    wire [3:0] done_4c;
    wire [7:0] done_8c;

    wire [63:0]  result_1c;
    wire [127:0] result_2c;
    wire [255:0] result_4c;
    wire [511:0] result_8c;

    wire done_1c_all = &done_1c;
    wire done_2c_all = &done_2c;
    wire done_4c_all = &done_4c;
    wire done_8c_all = &done_8c;

    wire [511:0] result_1c_pad = {448'd0, result_1c};
    wire [511:0] result_2c_pad = {384'd0, result_2c};
    wire [511:0] result_4c_pad = {256'd0, result_4c};

    reg          selected_done;
    reg [511:0]  selected_result;

    // Active-cluster response mux
    always @(*) begin
        case (active_cluster_sel)
            2'b00: begin
                selected_done   = done_1c_all;
                selected_result = result_1c_pad;
            end
            2'b01: begin
                selected_done   = done_2c_all;
                selected_result = result_2c_pad;
            end
            2'b10: begin
                selected_done   = done_4c_all;
                selected_result = result_4c_pad;
            end
            default: begin
                selected_done   = done_8c_all;
                selected_result = result_8c;
            end
        endcase
    end

    // 1-core cluster
    mac_cluster #(
        .NUM_CORES(1)
    ) u_cluster_1c (
        .clk        (clk),
        .reset      (reset),
        .start      (start_1c),
        .done       (done_1c),
        .a_rows_flat(a_rows_flat_in[95:0]),
        .b_cols_flat(b_cols_flat_in[95:0]),
        .result_flat(result_1c)
    );

    // 2-core cluster
    mac_cluster #(
        .NUM_CORES(2)
    ) u_cluster_2c (
        .clk        (clk),
        .reset      (reset),
        .start      (start_2c),
        .done       (done_2c),
        .a_rows_flat(a_rows_flat_in[191:0]),
        .b_cols_flat(b_cols_flat_in[191:0]),
        .result_flat(result_2c)
    );

    // 4-core cluster
    mac_cluster #(
        .NUM_CORES(4)
    ) u_cluster_4c (
        .clk        (clk),
        .reset      (reset),
        .start      (start_4c),
        .done       (done_4c),
        .a_rows_flat(a_rows_flat_in[383:0]),
        .b_cols_flat(b_cols_flat_in[383:0]),
        .result_flat(result_4c)
    );

    // 8-core cluster
    mac_cluster #(
        .NUM_CORES(8)
    ) u_cluster_8c (
        .clk        (clk),
        .reset      (reset),
        .start      (start_8c),
        .done       (done_8c),
        .a_rows_flat(a_rows_flat_in),
        .b_cols_flat(b_cols_flat_in),
        .result_flat(result_8c)
    );

    // Fabric state and benchmark counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done               <= 1'b0;
            busy               <= 1'b0;
            active_cluster_sel <= 2'b00;
            cycles_running     <= 32'd0;
            cycles_last        <= 32'd0;
            result_flat_out    <= 512'd0;
        end
        else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy               <= 1'b1;
                active_cluster_sel <= cluster_sel;
                cycles_running     <= 32'd0;
            end
            else if (busy) begin
                cycles_running <= cycles_running + 32'd1;
            end

            if (busy && selected_done) begin
                busy            <= 1'b0;
                done            <= 1'b1;
                cycles_last     <= cycles_running;
                result_flat_out <= selected_result;
            end
        end
    end

endmodule
