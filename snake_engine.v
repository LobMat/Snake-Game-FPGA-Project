// ============================================================
// snake_engine.v  (PURE VERILOG-2001)
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

reg [5:0] lfsr_x = 6'b101001;  // X random
reg [4:0] lfsr_y = 5'b11011;   // Y random

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
		body_segment_on <= 64'b0000000000000000000000000000000000000000000000000000000000011111;

        snake_length <= 5;

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

        // WALL CHECK: if head_x or head_y exceed grid, reset immediately
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
