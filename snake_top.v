// ============================================================
// snake_top module
// ============================================================

module snake_top(
	input CLOCK_50,
	input [4:0] KEY,           // KEY 4 = reset, KEY 0-3 directions
	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5
);

// ------------------------------------------------------------
// 25 MHz clock divider for VGA
// ------------------------------------------------------------
reg clk25 = 0;
always @(posedge CLOCK_50)
	clk25 <= ~clk25;

// ------------------------------------------------------------
// Generate slow movement pulse (~8Hz)
// ------------------------------------------------------------
reg [22:0] slowcnt = 0;
reg move_tick = 0;

always @(posedge CLOCK_50) begin
	slowcnt <= slowcnt + 1;
	move_tick <= (slowcnt == 0);
end

// ------------------------------------------------------------
// Direction encoding
// ------------------------------------------------------------

wire reset = ~KEY[4];

reg [1:0] direction;
always @(posedge CLOCK_50 or posedge reset) begin
	if (reset)
		direction <= 2'b01; // start moving right
	else begin
		if (KEY[0] && direction != 2'b10) direction <= 2'b00; // up
		else if (KEY[1] && direction != 2'b11) direction <= 2'b01; // right
		else if (KEY[2] && direction != 2'b00) direction <= 2'b10; // down
		else if (KEY[3] && direction != 2'b01) direction <= 2'b11; // left
	end
end

// ------------------------------------------------------------
// Snake engine
// ------------------------------------------------------------

wire [639:0] snake_x;
wire [639:0] snake_y;
wire [6:0] snake_length;

wire [9:0] apple_x;
wire [9:0] apple_y;

wire game_over;

snake_engine ENGINE (
	.clk(CLOCK_50),
	.reset(reset),
	.move_tick(move_tick),
	.direction(direction),
	.snake_x(snake_x),
	.snake_y(snake_y),
	.snake_length(snake_length),
	.apple_x(apple_x),
	.apple_y(apple_y),
	.game_over(game_over)
);

// ------------------------------------------------------------
// VGA sync
// ------------------------------------------------------------

wire [9:0] px, py;
wire display_on;

vga_sync VGA (
	.clk(clk25),
	.px(px),
	.py(py),
	.hsync(VGA_HS),
	.vsync(VGA_VS),
	.display_on(display_on)
);

// ------------------------------------------------------------
// Renderer
// ------------------------------------------------------------

wire [3:0] r, g, b;

game_render RENDER (
	.px(px),
	.py(py),
	.snake_x(snake_x),
	.snake_y(snake_y),
	.snake_length(snake_length),
	.apple_x(apple_x),
	.apple_y(apple_y),
	.game_over(game_over),
	.red(r),
	.green(g),
	.blue(b)
);

assign VGA_R = display_on ? r : 0;
assign VGA_G = display_on ? g : 0;
assign VGA_B = display_on ? b : 0;

// ------------------------------------------------------------
// HEX DISPLAY for score/snake length
// ------------------------------------------------------------

wire [3:0] score_tens = (snake_length) / 10;
wire [3:0] score_ones = (snake_length) % 10;

hex_decoder H0 (score_ones, HEX0);
hex_decoder H1 (score_tens, HEX1);

assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

endmodule

// ============================================================
// snake_engine module
// ============================================================
module snake_engine #(
	parameter SNAKE_MAX = 64
)(
	input clk,
	input reset,
	input move_tick,          // move event (slow clock pulse)
	input [1:0] direction,    // 00=up 01=right 10=down 11=left

	output reg [10*SNAKE_MAX-1:0] snake_x, // packed positions
	output reg [10*SNAKE_MAX-1:0] snake_y,
	output reg [6:0] snake_length,
	output reg [9:0] apple_x,
	output reg [9:0] apple_y,
	output reg game_over
);

reg [9:0] head_x;
reg [9:0] head_y;

reg [9:0] food_x;
reg [9:0] food_y;

reg [5:0] lfsr_x = 6'b101001;  // X pseudo-random
reg [4:0] lfsr_y = 5'b11011;   // Y pseudo-random

integer i, j;
reg collision;

reg [SNAKE_MAX-1:0] body_segment_on;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		game_over <= 0;
		// Reset food to top left initially
		apple_x <= 40/4;  
		apple_y <= 30/4;
		// Reset snake at center
		head_x <= 20;
		head_y <= 15;
		body_segment_on <= 64'b0000000000000000000000000000000000000000000000000000001111111111;

		snake_length <= 10;

		for (i=0; i<SNAKE_MAX; i=i+1) begin
			snake_x[i*10 +: 10] <= 20;
			snake_y[i*10 +: 10] <= 15 + i;
		end
	end else if (game_over);
	// Do nothing if game is over
	else if (move_tick) begin
		// LFSR for next food position
		lfsr_x <= {lfsr_x[4:0], lfsr_x[5] ^ lfsr_x[2]};
		lfsr_y <= {lfsr_y[3:0], lfsr_y[4] ^ lfsr_y[2]};
		if(lfsr_x <= 1 || lfsr_x >= 39) lfsr_x <= 5;
		if(lfsr_y <= 1 || lfsr_y >= 29) lfsr_y <= 5;
			
		// Compute tentative next head
		case(direction)
			2'b00: head_y <= head_y - 1;
			2'b01: head_x <= head_x + 1;
			2'b10: head_y <= head_y + 1;
			2'b11: head_x <= head_x - 1;
		endcase
	
		collision = 0;
		for (j=1; j<SNAKE_MAX; j=j+1) begin
			if (snake_x[j*10 +:10] == head_x && snake_y[j*10 +:10] == head_y && body_segment_on[j]) begin
				collision = 1;
			end
		end

		if(collision) begin
			game_over <= 1;
		end

		// WALL CHECK: if head_x or head_y exceed grid, go to game over
		else if (head_x >= 39 || head_y >= 29 || head_x <= 1 || head_y < 1) begin
			game_over <= 1;
		end else begin
			if (eat_food) begin
				// Grow snake
				snake_length <= snake_length + 1;
				body_segment_on[snake_length] <= 1;
				// Pick new food position
				apple_x <= lfsr_x % 40;
				apple_y <= lfsr_y % 30;
			end
			// shift body
			for (i=SNAKE_MAX-1; i>0; i=i-1) begin
				snake_x[i*10 +:10] <= snake_x[(i-1)*10 +:10];
				snake_y[i*10 +:10] <= snake_y[(i-1)*10 +:10];
			end

			// update head in packed arrays
			snake_x[0*10 +:10] <= head_x;
			snake_y[0*10 +:10] <= head_y;
		end
	end
end

wire eat_food = (head_x == apple_x) && (head_y == apple_y);

endmodule

// ============================================================
// vga_sync module
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
	hsync = ~((hcount >= H_VISIBLE + H_FP) && (hcount <  H_VISIBLE + H_FP + H_SYNC));

	vsync = ~((vcount >= V_VISIBLE + V_FP) && (vcount <  V_VISIBLE + V_FP + V_SYNC));
end

assign display_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
assign px = hcount;
assign py = vcount;

endmodule

// ============================================================
// game_render module
// ============================================================

module game_render #(
	parameter SNAKE_MAX = 64
)(
	input [9:0] px,    // pixel x
	input [9:0] py,    // pixel y
	input [10*SNAKE_MAX-1:0] snake_x,
	input [10*SNAKE_MAX-1:0] snake_y,
	input [6:0] snake_length,
	input [9:0] apple_x,
	input [9:0] apple_y,
	input game_over,

	output reg [3:0] red,
	output reg [3:0] green,
	output reg [3:0] blue
);

integer i;
reg hit_snake;
reg hit_apple;

// convert to grid cell
wire [9:0] cell_x = px >> 4;   // divide by 16
wire [9:0] cell_y = py >> 4;

always @(*) begin
	hit_snake = 0;
	hit_apple = 0;

	for (i = 0; i < 64; i = i + 1) begin
		if (i < snake_length) begin
			if (cell_x == snake_x[i*10 +: 10] &&
				cell_y == snake_y[i*10 +: 10])
				hit_snake = 1;
		end
	end

	if(cell_x == apple_x && cell_y == apple_y)
		hit_apple = 1;
	if (game_over) begin
		// Red screen
		red = 4'hF;
		green = 4'h0;
		blue = 4'h0;
		// Draw "GAME OVER" in white text
		if (px > 200 && px <= 250) begin
			if (py > 200 && py <=210) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 210 && py <= 230 && px > 200 && px <= 210) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 230 && py <= 240 && ((px > 200 && px <= 210) || (px > 230 && px <= 250))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 240 && py <= 260 && ((px > 200 && px <= 210) || (px > 240 && px <= 250))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			end else if (py > 260 && py <= 270) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 280 && py <= 290) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 290 && py <= 340 && ((px > 200 && px <= 210) || (px > 240 && px <= 250))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 340 && py <= 350) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end
		end else if (px > 260 && px <= 310) begin
			if (py > 200 && py <=210) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 210 && py <= 230 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 230 && py <=240) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 240 && py <= 270 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 280 && py <= 320 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 320 && py <= 340 && ((px > 270 && px <= 280) || (px > 290 && px <= 300))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 340 && py <= 350 && px > 280 && px <= 290) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end
		end else if (px > 320 && px <= 370) begin
			if (py > 200 && py <=220 && ((px > 320 && px <= 330) || (px > 360 && px <= 370))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 220 && py <= 230 && ((px > 320 && px <= 340) || (px > 350 && px <= 370))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 230 && py <= 240 && ((px > 320 && px <= 330) || (px > 360 && px <= 370) || (px > 340 && px <= 350))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 240 && py <= 270 && ((px > 320 && px <= 330) || (px > 360 && px <= 370))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 280 && py <= 290) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 290 && py <= 310 && px > 320 && px <= 330) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 310 && py <= 320 && px > 320 && px <= 350) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 320 && py <= 340 && px > 320 && px <= 330) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 340 && py <= 350) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end  
		end else if (px > 380 && px <= 430) begin
			if (py > 200 && py <=210) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 210 && py <= 230 && px > 380 && px <= 390) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 230 && py <= 240 && px > 380 && px <= 410) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 240 && py <= 260 && px > 380 && px <= 390) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 260 && py <= 270) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 280 && py <= 290 && px > 380 && px <= 420 /*heh, nice*/) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 290 && py <= 310 && ((px > 380 && px <= 390) || (px > 420 && px <= 430))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 310 && py <= 320 && px > 380 && px <= 420 /*heh, nice*/) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 320 && py <= 330 && ((px > 380 && px <= 390) || (px > 400 && px <= 410))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 330 && py <= 340 && ((px > 380 && px <= 390) || (px > 410 && px <= 420))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end else if (py > 340 && py <= 350 && ((px > 380 && px <= 390) || (px > 420 && px <= 430))) begin
				red = 4'hF;
				green = 4'hF;
				blue = 4'hF;
			end  
		end else begin
			red = 4'hF;
			green = 4'h0;
			blue = 4'h0;
		end
   end else if (hit_snake) begin
		red   = 4'h0;
		green = 4'hF;
		blue  = 4'h0;
	end else if (hit_apple) begin
		red   = 4'hF;
		green = 4'h0;
		blue  = 4'h0;
	end else if(px < 16+13 || px >= (40-1)*16 || py < 16 || py >= (30-1)*16) begin
		red = 4'h0;
		green = 4'hA;
		blue = 4'hA;
	end else begin
		red   = 4'h0;
		green = 4'h0;
		blue  = 4'h0;
	end
end

endmodule

// ============================================================
// hex_decoder module
// ============================================================

module hex_decoder(
	input [3:0] value,
	output reg [6:0] seg      // active low
);

always @(*) begin
	case(value)
		4'h0: seg = 7'b1000000;
		4'h1: seg = 7'b1111001;
		4'h2: seg = 7'b0100100;
		4'h3: seg = 7'b0110000;
		4'h4: seg = 7'b0011001;
		4'h5: seg = 7'b0010010;
		4'h6: seg = 7'b0000010;
		4'h7: seg = 7'b1111000;
		4'h8: seg = 7'b0000000;
		4'h9: seg = 7'b0010000;
		4'hA: seg = 7'b0001000;
		4'hB: seg = 7'b0000011;
		4'hC: seg = 7'b1000110;
		4'hD: seg = 7'b0100001;
		4'hE: seg = 7'b0000110;
		4'hF: seg = 7'b0001110;
	endcase
end

endmodule
