//Only support one byte write/read once
//Do not support register address
module i2c_master#(
	parameter MAX = 255
)
(
	input clk,
	input rst,
	input [7:0]wdata,
	input [6:0]addr,
	input rw,//w 1'b0 r 1'b1
	input start,

	output [7:0]rdata,
	output done,

	output scl,
	inout sda 

);
	localparam IDLE = 0, START = 1, STOP = 2; 
	localparam ACK_I = 3, DATA_W = 4, ADDR_W = 5; //write state
	localparam ADDR_R = 6, ACK_O = 7, DATA_R = 8; //read state
	localparam RESTART = 9;
	reg [3:0]state;
	reg [3:0]next_state;
	wire [$clog2(MAX+1)-1:0]clk_div;	
	reg sda_en,sda_out;
	assign sda = sda_en ? sda_out : 1'bz;
	wire rst_true = rst || (state == STOP);
	param_counter #(
	.MAX(MAX),
	.UP(1)
	)	u_clk_div	(
	.clk(clk),
	.rst(rst_true),
	.en(1'b1),
	.q(clk_div));

	wire [2:0]bit_cnt;
	wire bit_cnt_a;
	reg cnt_rst;
	param_counter #(
	.MAX(4'd8),
	.UP(0)
	)	u_counter (
	.clk(!scl),
	.rst(rst_true || cnt_rst),
	.en((state == ADDR_W) || (state == DATA_W) || (state == ADDR_R) || (state == DATA_R)),
	.q({bit_cnt_a,bit_cnt}));

	reg scl_out;
	reg scl_en;
	always @(posedge clk, posedge rst_true)begin
	if(rst_true)
		scl_out <= 1'b1;
	else if((clk_div == 0) && scl_en)
		scl_out <= !scl_out;
end
	assign scl = scl_out;
	
	always @(posedge clk, posedge rst)begin
	if(rst) 
		state <= IDLE;
	else if(clk_div == 0)
		state <= next_state;
end

	reg [1:0]ack_in_ctr;
	always @(*)begin
	case(state)
		IDLE:	next_state = start ? START : IDLE;
		START:next_state = ADDR_W;
		ADDR_W:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : ADDR_W;
		ACK_I:	begin//DATA_W,STOP,  START,DATA_R
		case(ack_in_ctr)
			2'b00: next_state = scl ? DATA_W : ACK_I;
			2'b01: next_state = scl ? STOP : ACK_I;
			2'b10: next_state = scl ? RESTART : ACK_I;
			2'b11: next_state = scl ? DATA_R : ACK_I;
	endcase
	end
		DATA_W:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : DATA_W;
		STOP:	next_state = IDLE;
		ADDR_R:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : ADDR_R;
		DATA_R:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_O : DATA_R;
		ACK_O:	next_state = scl ? STOP : ACK_O;
		RESTART: next_state = scl ? ADDR_R : RESTART;
		default: next_state = IDLE;
endcase
end
	
	wire [7:0]addrw = {addr,{1'b0}};
	wire [7:0]addrr = {addr,{1'b1}};
	reg in_flag;
	reg dataw_flag;
	reg restart_out;
	reg [7:0]rdata_temp;
	
	always @(*)begin
	ack_in_ctr = 2'b00;
	cnt_rst = 1'b0;
	case(state)
		IDLE: begin 
		scl_en = 1'b0;
		sda_en = 1'b1;
		sda_out = 1'b1;
	 end	
		START: begin
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = 1'b0;
		end
		ADDR_W: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = addrw[bit_cnt];
	 end	
		ACK_I: begin 
		cnt_rst = 1'b1;
		scl_en = 1'b1;
		sda_en = 1'b0;
		ack_in_ctr = (sda) ? 2'b01 : (rw ? (in_flag ? 2'b11 : 2'b10) : (dataw_flag ? 2'b01 : 2'b00));
	 end	
		DATA_W: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = wdata[bit_cnt];
	 end	
		STOP: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = 1'b0;
	 end
		ADDR_R: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = addrr[bit_cnt];
	 end	
		DATA_R: begin 
		scl_en = 1'b1;
		sda_en = 1'b0;
	 end	
		ACK_O: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = 1'b0;
	 end	
		RESTART: begin 
		scl_en = 1'b1;
		sda_en = 1'b1;
		sda_out = !restart_out;
	 end	
endcase
end

		always @(negedge scl,posedge rst_true)begin
		if(rst_true) rdata_temp<= 8'b0;
		else if(state == DATA_R)	rdata_temp[bit_cnt]<= sda;
end
	
	always @(negedge clk,posedge rst_true)begin
		if(rst_true) restart_out <= 1'b0;
		else if(state == RESTART && (clk_div == ((MAX+1) >> 1)) && scl)	restart_out <= 1'b1;
end

	always @(negedge scl,posedge rst_true)begin
		if(rst_true) in_flag <= 1'b0;
		else if(state == ADDR_R)	in_flag <= 1'b1;
end
	always @(negedge scl,posedge rst_true)begin
		if(rst_true) dataw_flag <= 1'b0;
		else if(state == DATA_W)	dataw_flag <= 1'b1;
end
	assign done = (state == STOP);
	assign rdata = rdata_temp;
endmodule
