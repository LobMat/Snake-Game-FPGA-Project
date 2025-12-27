// ============================================================
// game_render.v (PURE VERILOG-2001)
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
			  end
			  else if (py > 210 && py <= 230 && px > 200 && px <= 210) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 230 && py <= 240 && ((px > 200 && px <= 210) || (px > 230 && px <= 250))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 240 && py <= 260 && ((px > 200 && px <= 210) || (px > 240 && px <= 250))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 260 && py <= 270) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 280 && py <= 290) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 290 && py <= 340 && ((px > 200 && px <= 210) || (px > 240 && px <= 250))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 340 && py <= 350) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
		 end
		 else if (px > 260 && px <= 310) begin
			  if (py > 200 && py <=210) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 210 && py <= 230 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 230 && py <=240) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 240 && py <= 270 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 280 && py <= 320 && ((px > 260 && px <= 270) || (px > 300 && px <= 310))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 320 && py <= 340 && ((px > 270 && px <= 280) || (px > 290 && px <= 300))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 340 && py <= 350 && px > 280 && px <= 290) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  
		 end
		 else if (px > 320 && px <= 370) begin
			  if (py > 200 && py <=220 && ((px > 320 && px <= 330) || (px > 360 && px <= 370))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 220 && py <= 230 && ((px > 320 && px <= 340) || (px > 350 && px <= 370))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 230 && py <= 240 && ((px > 320 && px <= 330) || (px > 360 && px <= 370) || (px > 340 && px <= 350))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 240 && py <= 270 && ((px > 320 && px <= 330) || (px > 360 && px <= 370))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 280 && py <= 290) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 290 && py <= 310 && px > 320 && px <= 330) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 310 && py <= 320 && px > 320 && px <= 350) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 320 && py <= 340 && px > 320 && px <= 330) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 340 && py <= 350) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  
		 end
		 else if (px > 380 && px <= 430) begin
			  if (py > 200 && py <=210) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 210 && py <= 230 && px > 380 && px <= 390) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 230 && py <= 240 && px > 380 && px <= 410) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 240 && py <= 260 && px > 380 && px <= 390) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 260 && py <= 270) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 280 && py <= 290 && px > 380 && px <= 420 /*heh, nice*/) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 290 && py <= 310 && ((px > 380 && px <= 390) || (px > 420 && px <= 430))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 310 && py <= 320 && px > 380 && px <= 420 /*heh, nice*/) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 320 && py <= 330 && ((px > 380 && px <= 390) || (px > 400 && px <= 410))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 330 && py <= 340 && ((px > 380 && px <= 390) || (px > 410 && px <= 420))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  else if (py > 340 && py <= 350 && ((px > 380 && px <= 390) || (px > 420 && px <= 430))) begin
					red = 4'hF;
					green = 4'hF;
					blue = 4'hF;
			  end
			  
		 end	
		 else begin
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
