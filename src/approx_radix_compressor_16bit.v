`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 com Árvore de Compressores Aproximada - 16 bits
 */
module approx_radix_compressor_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

    // 1. Geração de Produtos Parciais
    wire [32:0] pp [8:0];
    wire [18:0] b_ext = {2'b0, b, 1'b0};
    wire [32:0] a_ext = {17'd0, a};

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_PP
            wire [2:0] triplet = b_ext[2*i +: 3];
            reg signed [32:0] raw_pp;
            
            always @(*) begin
                case (triplet)
                    3'b001, 3'b010: raw_pp = $signed(a_ext) << (2*i);
                    3'b011:         raw_pp = (i < 2) ? ($signed(a_ext) << (2*i)) : ($signed(a_ext) << (2*i + 1));
                    3'b100:         raw_pp = (i < 2) ? -($signed(a_ext) << (2*i)) : -($signed(a_ext) << (2*i + 1));
                    3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                    default:        raw_pp = 33'd0;
                endcase
            end
            assign pp[i] = raw_pp;
        end
    endgenerate

    assign pp[8] = (b[15]) ? (a_ext << 16) : 33'd0;

    // 2. Redução Estrutural (Aproximada)
    genvar k;
    wire [32:0] s1 [1:0], c1 [1:0];
    wire [33:0] cout1 [1:0];
    generate
        for (i = 0; i < 2; i = i + 1) begin : L1
            assign cout1[i][0] = 1'b0;
            for (k = 0; k < 33; k = k + 1) begin : L1B
                approx_compressor42 comp (
                    .a(pp[4*i][k]), .b(pp[4*i+1][k]), .c(pp[4*i+2][k]), .d(pp[4*i+3][k]),
                    .cin(cout1[i][k]), .sum(s1[i][k]), .carry(c1[i][k]), .cout(cout1[i][k+1])
                );
            end
        end
    endgenerate

    wire [32:0] s2, c2;
    wire [33:0] cout2;
    assign cout2[0] = 1'b0;
    generate
        for (k = 0; k < 33; k = k + 1) begin : L2B
            wire cin_a = (k == 0) ? 1'b0 : c1[0][k-1];
            wire cin_b = (k == 0) ? 1'b0 : c1[1][k-1];
            approx_compressor42 comp (
                .a(s1[0][k]), .b(cin_a), .c(s1[1][k]), .d(cin_b),
                .cin(cout2[k]), .sum(s2[k]), .carry(c2[k]), .cout(cout2[k+1])
            );
        end
    endgenerate

    assign product = s2[31:0] + (c2[30:0] << 1) + pp[8][31:0];

endmodule
