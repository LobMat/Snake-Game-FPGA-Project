// ============================================================
// vga_sync.v (PURE VERILOG-2001)
// ============================================================

module vga_sync(
    input clk,        // 25 MHz
    output [9:0] px,
    output [9:0] py,
    output reg hsync,
    output reg vsync,
    output display_on
);

// VGA timing constants
parameter H_VISIBLE = 640;
parameter H_FP = 16;
parameter H_SYNC = 96;
parameter H_BP = 48;
parameter H_TOTAL = 800;

parameter V_VISIBLE = 480;
parameter V_FP = 10;
parameter V_SYNC = 2;
parameter V_BP = 33;
parameter V_TOTAL = 525;

reg [9:0] hcount = 0;
reg [9:0] vcount = 0;

always @(posedge clk) begin
    if (hcount == H_TOTAL-1) begin
        hcount <= 0;
        if (vcount == V_TOTAL-1)
            vcount <= 0;
        else
            vcount <= vcount + 1;
    end else begin
        hcount <= hcount + 1;
    end
end

always @(*) begin
    hsync = ~((hcount >= H_VISIBLE + H_FP) &&
              (hcount <  H_VISIBLE + H_FP + H_SYNC));

    vsync = ~((vcount >= V_VISIBLE + V_FP) &&
              (vcount <  V_VISIBLE + V_FP + V_SYNC));
end

assign display_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
assign px = hcount;
assign py = vcount;

endmodule
