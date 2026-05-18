`timescale 1ns / 1ps

module compressor42_16bit(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

integer i, j;

reg [31:0] partial [15:0];

always @(*) begin
    for(i = 0; i < 16; i = i + 1) begin
        partial[i] = 0;

        for(j = 0; j < 16; j = j + 1) begin
            partial[i][i+j] = a[j] & b[i];
        end
    end
end

wire [31:0] s1;
wire [31:0] c1;
wire [32:0] carry_out_chain;

assign carry_out_chain[0] = 1'b0;

genvar k;

generate
    for(k = 0; k < 32; k = k + 1) begin : COMP

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

assign product = s1 + (c1 << 1) + (carry_out_chain[32] << 32)
               + partial[4]
               + partial[5]
               + partial[6]
               + partial[7]
               + partial[8]
               + partial[9]
               + partial[10]
               + partial[11]
               + partial[12]
               + partial[13]
               + partial[14]
               + partial[15];

endmodule