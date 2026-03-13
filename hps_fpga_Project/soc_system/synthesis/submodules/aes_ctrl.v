// state machine controller interfaces with aes_top and directs data to aes processor
module aes_ctrl(
   input wire        clk,
	input wire        reset,
	input wire [31:0] instruction,
	output reg [31:0] status,
   output reg [1:0] aes_mux_sel
);

// Instruction values from main.c driver
localparam [31:0] INST_RESET            = 32'h0000_0000;
localparam [31:0] INST_SIGNAL_LOAD_KEY  = 32'h0000_0001;
localparam [31:0] INST_LOADING_KEY      = 32'h0000_0003;
localparam [31:0] INST_LOADING_DATA     = 32'h0000_0005;
localparam [31:0] INST_START_ENCRYPTION = 32'h0000_0009;

// Status values expected by main.c
localparam [31:0] STATUS_RESET      = 32'h0000_0000;
localparam [31:0] STATUS_LOAD_KEY   = 32'h0000_0003;
localparam [31:0] STATUS_LOAD_DATA  = 32'h0000_0005;
localparam [31:0] STATUS_ENCRYPTING = 32'h0000_0009;
localparam [31:0] STATUS_DONE       = 32'h0000_000F;

// State encoding
localparam [2:0] ST_RESET      = 3'd0;
localparam [2:0] ST_LOAD_KEY   = 3'd1;
localparam [2:0] ST_LOAD_DATA  = 3'd2;
localparam [2:0] ST_ENCRYPTING = 3'd3;
localparam [2:0] ST_DONE       = 3'd4;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge clk or posedge reset) begin
	if (reset)
		state <= ST_RESET;
	else
		state <= next_state;
end

// set state
always @(*) begin
	next_state = state;
   aes_mux_sel    = 2'b00; // always default for now
	case (state)
		ST_RESET: begin
			if ((instruction == INST_SIGNAL_LOAD_KEY) ||
				(instruction == INST_LOADING_KEY))
				next_state = ST_LOAD_KEY;
		end

		ST_LOAD_KEY: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else if (instruction == INST_LOADING_DATA)
				next_state = ST_LOAD_DATA;
		end

		ST_LOAD_DATA: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else if (instruction == INST_START_ENCRYPTION)
				next_state = ST_ENCRYPTING;
		end

		ST_ENCRYPTING: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else
				next_state = ST_DONE;
		end

		ST_DONE: begin
			if (instruction == INST_RESET)
				next_state = ST_RESET;
			else if ((instruction == INST_SIGNAL_LOAD_KEY) ||
					 (instruction == INST_LOADING_KEY))
				next_state = ST_LOAD_KEY;
		end

		default: next_state = ST_RESET;
	endcase
end

// set status
always @(*) begin
	status   = STATUS_RESET;
	case (state)
		ST_RESET: begin
			status = STATUS_RESET;
		end

		ST_LOAD_KEY: begin
			status  = STATUS_LOAD_KEY;
		end

		ST_LOAD_DATA: begin
			status   = STATUS_LOAD_DATA;
		end

		ST_ENCRYPTING: begin
			status   = STATUS_ENCRYPTING;
		end

		ST_DONE: begin
			status = STATUS_DONE;
		end

		default: begin
			status = STATUS_RESET;
		end
	endcase
end

endmodule
