`timescale 1ns / 1ps

module approx_radix_compressor_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

    // =========================================================
    // 1. Geração de Produtos Parciais (Booth Radix-4)
    // =========================================================
    
    // N/2 = 16 produtos parciais + 1 de correção unsigned = 17 PPs
    wire [64:0] pp [16:0];
    
    wire [34:0] b_ext = {2'b0, b, 1'b0};
    wire [64:0] a_ext = {33'd0, a};

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_PP
            wire [2:0] triplet = b_ext[2*i +: 3];
            
            reg signed [64:0] raw_pp;
            
            always @(*) begin
                case (triplet)
                    3'b001, 3'b010: raw_pp = $signed(a_ext) << (2*i);
                    3'b011:         raw_pp = $signed(a_ext) << (2*i + 1);
                    3'b100:         raw_pp = -($signed(a_ext) << (2*i + 1));
                    3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                    default:        raw_pp = 65'd0;
                endcase
            end
            
            assign pp[i] = raw_pp;
        end
    endgenerate

    // PP 16: Correção para unsigned
    assign pp[16] = (b[31]) ? (a_ext << 32) : 65'd0;

    // =========================================================
    // 2. Redução com Árvore de Compressores Aproximados
    // =========================================================
    
    genvar k;

    // Nível 1: 16 PPs -> 4 pares (S, C)
    wire [64:0] s1 [3:0];
    wire [64:0] c1 [3:0];
    wire [65:0] cout1 [3:0];
    generate
        for (i = 0; i < 4; i = i + 1) begin : LEVEL1_GEN
            assign cout1[i][0] = 1'b0;
            for (k = 0; k < 65; k = k + 1) begin : LEVEL1_BIT
                approx_compressor42 comp (
                    .a(pp[4*i][k]), .b(pp[4*i+1][k]), .c(pp[4*i+2][k]), .d(pp[4*i+3][k]),
                    .cin(cout1[i][k]), .sum(s1[i][k]), .carry(c1[i][k]), .cout(cout1[i][k+1])
                );
            end
        end
    endgenerate

    // Nível 2: 4 pares (S, C) -> 2 pares (S, C)
    wire [64:0] s2 [1:0];
    wire [64:0] c2 [1:0];
    wire [65:0] cout2 [1:0];
    generate
        for (i = 0; i < 2; i = i + 1) begin : LEVEL2_GEN
            assign cout2[i][0] = 1'b0;
            for (k = 0; k < 65; k = k + 1) begin : LEVEL2_BIT
                wire c_in_a = (k == 0) ? 1'b0 : c1[2*i][k-1];
                wire c_in_b = (k == 0) ? 1'b0 : c1[2*i+1][k-1];
                approx_compressor42 comp (
                    .a(s1[2*i][k]), .b(c_in_a), .c(s1[2*i+1][k]), .d(c_in_b),
                    .cin(cout2[i][k]), .sum(s2[i][k]), .carry(c2[i][k]), .cout(cout2[i][k+1])
                );
            end
        end
    endgenerate

    // Nível 3: 2 pares (S, C) -> 1 par (S, C)
    wire [64:0] s3, c3;
    wire [65:0] cout3;
    assign cout3[0] = 1'b0;
    generate
        for (k = 0; k < 65; k = k + 1) begin : LEVEL3_BIT
            wire c_in_a = (k == 0) ? 1'b0 : c2[0][k-1];
            wire c_in_b = (k == 0) ? 1'b0 : c2[1][k-1];
            approx_compressor42 comp (
                .a(s2[0][k]), .b(c_in_a), .c(s2[1][k]), .d(c_in_b),
                .cin(cout3[k]), .sum(s3[k]), .carry(c3[k]), .cout(cout3[k+1])
            );
        end
    endgenerate

    // Soma final: s3 + (c3 << 1) + pp[16]
    assign product = s3[63:0] + (c3[62:0] << 1) + pp[16][63:0];

endmodule
