`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Modificado com Árvore de Compressores Aproximada - 8 bits
 */
module approx_modified_radix_compressor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

    // 1. Detecção de Faixa (Logic Gating)
    reg [1:0] range_b;
    always @(*) begin
        if (b[7:5] != 3'b000)      range_b = 3;
        else if (b[4:3] != 2'b00)   range_b = 2;
        else if (b[2:1] != 2'b00)   range_b = 1;
        else                        range_b = 0;
    end

    // 2. Geração de Produtos Parciais com Gating
    wire [16:0] pp [4:0];
    wire [10:0] b_ext = {2'b0, b, 1'b0};
    wire [16:0] a_ext = {9'd0, a};

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_PP
            wire [2:0] triplet = b_ext[2*i +: 3];
            reg signed [16:0] raw_pp;
            
            always @(*) begin
                if (i <= range_b) begin
                    case (triplet)
                        3'b001, 3'b010: raw_pp = $signed(a_ext) << (2*i);
                        3'b011:         raw_pp = (i < 1) ? ($signed(a_ext) << (2*i)) : ($signed(a_ext) << (2*i + 1));
                        3'b100:         raw_pp = (i < 1) ? -($signed(a_ext) << (2*i)) : -($signed(a_ext) << (2*i + 1));
                        3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                        default:        raw_pp = 17'd0;
                    endcase
                end else begin
                    raw_pp = 17'd0;
                end
            end
            assign pp[i] = raw_pp;
        end
    endgenerate

    assign pp[4] = (b[7]) ? (a_ext << 8) : 17'd0;

    // 3. Redução Estrutural (Aproximada)
    genvar k;
    wire [16:0] s1, c1;
    wire [17:0] cout1;
    assign cout1[0] = 1'b0;
    generate
        for (k = 0; k < 17; k = k + 1) begin : L1B
            approx_compressor42 comp (
                .a(pp[0][k]), .b(pp[1][k]), .c(pp[2][k]), .d(pp[3][k]),
                .cin(cout1[k]), .sum(s1[k]), .carry(c1[k]), .cout(cout1[k+1])
            );
        end
    endgenerate

    assign product = s1[15:0] + (c1[14:0] << 1) + pp[4][15:0];

endmodule
