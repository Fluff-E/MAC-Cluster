// state machine controller interfaces with aes_top and directs data to aes processor
module cluster_ctrl(
   input wire        clk,
	input wire        reset,
	input wire [31:0] instruction,
   input wire [2:0] mac_status, // one bit per tracked mac: 0 ready, 1 done
	output reg [31:0] status,
	output reg        cluster_tx_state
);

// Instruction values from main.c driver
localparam [31:0] INST_RESET            = 32'h0000_0000;
localparam [31:0] INST_SIGNAL_TX        = 32'h0000_0001;
localparam [31:0] INST_TX_COMPLETE      = 32'h0000_0003;
localparam [31:0] INST_RX_COMPLETE      = 32'h0000_0005;


// Status values expected by main.c
localparam [31:0] STATUS_RESET      = 32'h0000_0000;
localparam [31:0] STATUS_READY_RX   = 32'h0000_0003;
localparam [31:0] STATUS_ACK_RX     = 32'h0000_0005;
localparam [31:0] STATUS_PROCESSING = 32'h0000_0009;
localparam [31:0] STATUS_DONE_TX    = 32'h0000_000F;

// State encoding
localparam [2:0] ST_RESET      = 3'd0;
localparam [2:0] ST_READY_RX   = 3'd1;
localparam [2:0] ST_ACK_RX     = 3'd2;
localparam [2:0] ST_PROCESSING = 3'd3;
localparam [2:0] ST_DONE       = 3'd4;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= ST_RESET;
		cluster_tx_state <= 1'b0; // de-assert tx state on reset
	end

	else
		state <= next_state;
end

// set state
always @(*) begin
	next_state = state;
	case (state)
		ST_RESET: begin
			cluster_tx_state = 1'b0; // ensure tx state is de-asserted in reset
         if (instruction == INST_SIGNAL_TX)
				next_state = ST_READY_RX;
		end

		ST_READY_RX: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else if (instruction == INST_RX_COMPLETE)
				next_state = ST_ACK_RX;
		end

		ST_ACK_RX: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else
				next_state = ST_PROCESSING;
		end

		ST_PROCESSING: begin
			if (instruction == INST_RESET)
            next_state = ST_RESET;
			else if (&mac_status) begin // DOUBLE CHECK THIS LOGIC
				cluster_tx_state = 1'b1;
				next_state = ST_DONE;
         end
		end

		ST_DONE: begin
			if (instruction == INST_RESET)
				cluster_tx_state = 1'b0; // de-assert tx state on reset
            next_state = ST_RESET;
			
		end

		default: next_state = ST_RESET;
	endcase
end

// set status
always @(*) begin
	status   = STATUS_RESET;
	cluster_tx_state = 1'b0;
	case (state)
		ST_RESET: begin
			status = STATUS_RESET;
		end

		ST_READY_RX: begin
			status  = STATUS_READY_RX;
		end

		ST_ACK_RX: begin
			status   = STATUS_ACK_RX;
		end

		ST_PROCESSING: begin
			status   = STATUS_PROCESSING;
		end

		ST_DONE: begin
			status = STATUS_DONE_TX;
		end

		default: begin
			status = STATUS_RESET;
		end
	endcase
end

endmodule
