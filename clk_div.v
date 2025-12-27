// --------------------------------------
// clk_div.v
// --------------------------------------
module clk_div(
    input clk50,
    input rst,
    output reg clk25,
    output reg slow_tick
);

    reg toggle = 0;
    always @(posedge clk50) begin
        toggle <= ~toggle;
        clk25 <= toggle;   // 50 → 25 MHz
    end

    // slow ~5 Hz tick
    reg [23:0] cnt;
    always @(posedge clk50 or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            slow_tick <= 0;
        end else begin
            cnt <= cnt + 1;
            if(cnt == 24'd10_000_000) begin
                slow_tick <= 1;
                cnt <= 0;
            end else
                slow_tick <= 0;
        end
    end

endmodule
