`timescale 1ns / 1ps

module radix4_compressor_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

    // =========================================================
    // 1. Geração de Produtos Parciais (Booth Radix-4)
    // =========================================================

    // N/2 = 8 produtos parciais + 1 de correção unsigned = 9 PPs
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
                    3'b011:         raw_pp = $signed(a_ext) << (2*i + 1);
                    3'b100:         raw_pp = -($signed(a_ext) << (2*i + 1));
                    3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                    default:        raw_pp = 33'd0;
                endcase
            end

            assign pp[i] = raw_pp;
        end
    endgenerate

    // PP 8: Correção para unsigned
    assign pp[8] = (b[15]) ? (a_ext << 16) : 33'd0;

    // =========================================================
    // 2. Redução Estrutural com Compressores 4:2
    // =========================================================

    // Nível 1: Reduz 8 PPs (0-7) em 4 sinais (S1, C1, S2, C2)
    wire [32:0] s1, c1, s2, c2;
    wire [33:0] cout1, cout2;
    assign cout1[0] = 1'b0;
    assign cout2[0] = 1'b0;

    genvar k;
    generate
        for (k = 0; k < 33; k = k + 1) begin : LEVEL1
            compressor42 comp1 (
                .a(pp[0][k]), .b(pp[1][k]), .c(pp[2][k]), .d(pp[3][k]),
                .cin(cout1[k]), .sum(s1[k]), .carry(c1[k]), .cout(cout1[k+1])
            );
            compressor42 comp2 (
                .a(pp[4][k]), .b(pp[5][k]), .c(pp[6][k]), .d(pp[7][k]),
                .cin(cout2[k]), .sum(s2[k]), .carry(c2[k]), .cout(cout2[k+1])
            );
        end
    endgenerate

    // Nível 2: Reduz (S1, C1<<1, S2, C2<<1) em (S3, C3)
    wire [32:0] s3, c3;
    wire [33:0] cout3;
    assign cout3[0] = 1'b0;

    generate
        for (k = 0; k < 33; k = k + 1) begin : LEVEL2
            wire c1_in = (k == 0) ? 1'b0 : c1[k-1];
            wire c2_in = (k == 0) ? 1'b0 : c2[k-1];
            compressor42 comp3 (
                .a(s1[k]), .b(c1_in), .c(s2[k]), .d(c2_in),
                .cin(cout3[k]), .sum(s3[k]), .carry(c3[k]), .cout(cout3[k+1])
            );
        end
    endgenerate

    // Soma final: s3 + (c3 << 1) + pp[8]
    assign product = s3[31:0] + (c3[30:0] << 1) + pp[8][31:0];

endmodule
