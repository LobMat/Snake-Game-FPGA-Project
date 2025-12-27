// --------------------------------------
// lfsr8.v   (8-bit pseudo random generator)
// --------------------------------------
module lfsr8(
    input clk,
    input rst,
    output reg [7:0] rnd
);

    wire feedback = rnd[7] ^ rnd[5] ^ rnd[4] ^ rnd[3];

    always @(posedge clk or posedge rst) begin
        if(rst)
            rnd <= 8'hA5;
        else
            rnd <= {rnd[6:0], feedback};
    end

endmodule
