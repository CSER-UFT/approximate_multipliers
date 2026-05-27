`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Modificado com Árvore de Compressores Aproximada
 * Combina a detecção de faixa dinâmica (Modified Radix) com 
 * a redução estrutural usando compressores 4:2 aproximados.
 */
module approx_modified_radix_compressor_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

    // 1. Detecção de Faixa (Logic Gating)
    reg [3:0] range_b;
    always @(*) begin
        if (b[31:29] != 3'b000)      range_b = 15;
        else if (b[28:27] != 2'b00) range_b = 14;
        else if (b[26:25] != 2'b00) range_b = 13;
        else if (b[24:23] != 2'b00) range_b = 12;
        else if (b[22:21] != 2'b00) range_b = 11;
        else if (b[20:19] != 2'b00) range_b = 10;
        else if (b[18:17] != 2'b00) range_b = 9;
        else if (b[16:15] != 2'b00) range_b = 8;
        else if (b[14:13] != 2'b00) range_b = 7;
        else if (b[12:11] != 2'b00) range_b = 6;
        else if (b[10:9] != 2'b00)  range_b = 5;
        else if (b[8:7] != 2'b00)   range_b = 4;
        else if (b[6:5] != 2'b00)   range_b = 3;
        else if (b[4:3] != 2'b00)   range_b = 2;
        else if (b[2:1] != 2'b00)   range_b = 1;
        else                        range_b = 0;
    end

    // 2. Geração de Produtos Parciais com Gating
    wire [64:0] pp [16:0];
    wire [34:0] b_ext = {2'b0, b, 1'b0};
    wire [64:0] a_ext = {33'd0, a};

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_PP
            wire [2:0] triplet = b_ext[2*i +: 3];
            reg signed [64:0] raw_pp;
            
            always @(*) begin
                // Só ativa o produto parcial se estiver dentro da faixa detectada
                if (i <= range_b) begin
                    case (triplet)
                        3'b001, 3'b010: raw_pp = $signed(a_ext) << (2*i);
                        3'b011:         raw_pp = (i < 4) ? ($signed(a_ext) << (2*i)) : ($signed(a_ext) << (2*i + 1));
                        3'b100:         raw_pp = (i < 4) ? -($signed(a_ext) << (2*i)) : -($signed(a_ext) << (2*i + 1));
                        3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                        default:        raw_pp = 65'd0;
                    endcase
                end else begin
                    raw_pp = 65'd0;
                end
            end
            assign pp[i] = raw_pp;
        end
    endgenerate

    assign pp[16] = (b[31]) ? (a_ext << 32) : 65'd0;

    // 3. Redução Estrutural (Aproximada)
    genvar k;
    wire [64:0] s1 [3:0], c1 [3:0];
    wire [65:0] cout1 [3:0];
    generate
        for (i = 0; i < 4; i = i + 1) begin : L1
            assign cout1[i][0] = 1'b0;
            for (k = 0; k < 65; k = k + 1) begin : L1B
                approx_compressor42 comp (
                    .a(pp[4*i][k]), .b(pp[4*i+1][k]), .c(pp[4*i+2][k]), .d(pp[4*i+3][k]),
                    .cin(cout1[i][k]), .sum(s1[i][k]), .carry(c1[i][k]), .cout(cout1[i][k+1])
                );
            end
        end
    endgenerate

    wire [64:0] s2 [1:0], c2 [1:0];
    wire [65:0] cout2 [1:0];
    generate
        for (i = 0; i < 2; i = i + 1) begin : L2
            assign cout2[i][0] = 1'b0;
            for (k = 0; k < 65; k = k + 1) begin : L2B
                wire cin_a = (k == 0) ? 1'b0 : c1[2*i][k-1];
                wire cin_b = (k == 0) ? 1'b0 : c1[2*i+1][k-1];
                approx_compressor42 comp (
                    .a(s1[2*i][k]), .b(cin_a), .c(s1[2*i+1][k]), .d(cin_b),
                    .cin(cout2[i][k]), .sum(s2[i][k]), .carry(c2[i][k]), .cout(cout2[i][k+1])
                );
            end
        end
    endgenerate

    wire [64:0] s3, c3;
    wire [65:0] cout3;
    assign cout3[0] = 1'b0;
    generate
        for (k = 0; k < 65; k = k + 1) begin : L3B
            wire cin_a = (k == 0) ? 1'b0 : c2[0][k-1];
            wire cin_b = (k == 0) ? 1'b0 : c2[1][k-1];
            approx_compressor42 comp (
                .a(s2[0][k]), .b(cin_a), .c(s2[1][k]), .d(cin_b),
                .cin(cout3[k]), .sum(s3[k]), .carry(c3[k]), .cout(cout3[k+1])
            );
        end
    endgenerate

    assign product = s3[63:0] + (c3[62:0] << 1) + pp[16][63:0];

endmodule
