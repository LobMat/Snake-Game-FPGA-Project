// --------------------------------------
// vga_timing.v
// --------------------------------------
module vga_timing(
    input clk,        // 25 MHz pixel clock
    input rst,
    output reg [9:0] x,
    output reg [9:0] y,
    output reg hsync,
    output reg vsync,
    output visible
);

    // VGA Timing 640x480 @ 60Hz
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x <= 0;
            y <= 0;
        end else begin
            if(x == H_TOTAL - 1) begin
                x <= 0;
                if(y == V_TOTAL - 1)
                    y <= 0;
                else
                    y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    // HSYNC and VSYNC
    always @(*) begin
        hsync = ~((x >= H_VISIBLE + H_FRONT) &&
                  (x <  H_VISIBLE + H_FRONT + H_SYNC));

        vsync = ~((y >= V_VISIBLE + V_FRONT) &&
                  (y <  V_VISIBLE + V_FRONT + V_SYNC));
    end

    assign visible = (x < H_VISIBLE && y < V_VISIBLE);

endmodule
