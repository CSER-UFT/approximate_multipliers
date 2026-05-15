module compressor42_32bit(
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

integer i, j;

reg [63:0] partial [31:0];

always @(*) begin
    for(i = 0; i < 32; i = i + 1) begin
        partial[i] = 0;

        for(j = 0; j < 32; j = j + 1) begin
            partial[i][i+j] = a[j] & b[i];
        end
    end
end

wire [63:0] s1;
wire [63:0] c1;
wire [64:0] carry_out_chain;

assign carry_out_chain[0] = 1'b0;

genvar k;

generate
    for(k = 0; k < 64; k = k + 1) begin : COMP

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

assign product = s1 + (c1 << 1) + (carry_out_chain[64] << 64)
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
               + partial[15]
               + partial[16]
               + partial[17]
               + partial[18]
               + partial[19]
               + partial[20]
               + partial[21]
               + partial[22]
               + partial[23]
               + partial[24]
               + partial[25]
               + partial[26]
               + partial[27]
               + partial[28]
               + partial[29]
               + partial[30]
               + partial[31];

endmodule