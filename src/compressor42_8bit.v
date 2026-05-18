`timescale 1ns / 1ps

module compressor42_8bit(
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

integer i, j;

reg [15:0] partial [7:0];

always @(*) begin
    for(i = 0; i < 8; i = i + 1) begin
        partial[i] = 0;

        for(j = 0; j < 8; j = j + 1) begin
            partial[i][i+j] = a[j] & b[i];
        end
    end
end

wire [15:0] s1;
wire [15:0] c1;
wire [16:0] carry_out_chain;

assign carry_out_chain[0] = 1'b0;

genvar k;

generate
    for(k = 0; k < 16; k = k + 1) begin : COMP

        compressor42 c42(
            .a(partial[0][k]),
            .b(partial[1][k]),
            .c(partial[2][k]),
            .d(partial[3][k]),
            .cin(carry_out_chain[k]),

            .sum(s1[k]),
            .carry(c1[k]),
            .cout(carry_out_chain[k+1])
        );

    end
endgenerate

assign product = s1 + (c1 << 1) + (carry_out_chain[16] << 16)
               + partial[4]
               + partial[5]
               + partial[6]
               + partial[7];

endmodule