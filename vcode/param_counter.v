module param_counter #(
    parameter MAX = 255,
    parameter UP = 1  // 1 表示向上计数，0 表示向下计数
) (
    input wire clk,
    input wire rst,
		input wire en,
    output reg [$clog2(MAX+1)-1:0] q
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= (UP ? 0 : MAX);
        end else if(en)begin
            if (UP) begin
                if (q == MAX)
                    q <= 0;
                else
                    q <= q + 1;
            end else begin
                if (q == 0)
                    q <= MAX;
                else
                    q <= q - 1;
            end
        end
    end

endmodule
