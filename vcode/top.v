module top(
	input rst,
	input clk,
	input [7:0]wdata,
	input [6:0]addr,
	input rw,//w 1'b0 r 1'b1
	input start,
	output [7:0]rdata,
	output done,

	output scl,
	inout sda 
);

	i2c_master#(
	.MAX(3)
) u_i2c_master(
	.rst,
	.clk,
	.wdata,
	.addr,
	.rw,
	.start,
	.rdata,
	.done,
	.scl,
	.sda
);

	 initial begin
		 if ($test$plusargs("trace") != 0) begin
				 $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
				 $dumpfile("logs/vlt_dump.vcd");
				 $dumpvars(); end
		 $display("[%0t] Model running...\n", $time);
 end

endmodule
