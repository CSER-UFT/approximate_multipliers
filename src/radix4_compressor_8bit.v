`timescale 1ns / 1ps

module radix4_compressor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

    // =========================================================
    // 1. Geração de Produtos Parciais (Booth Radix-4)
    // =========================================================
    
    // N/2 = 4 produtos parciais + 1 de correção unsigned = 5 PPs
    wire [16:0] pp [4:0];
    
    wire [10:0] b_ext = {2'b0, b, 1'b0}; 
    wire [16:0] a_ext = {9'd0, a};

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_PP
            wire [2:0] triplet = b_ext[2*i +: 3];
            
            reg signed [16:0] raw_pp;
            
            always @(*) begin
                case (triplet)
                    3'b001, 3'b010: raw_pp = $signed(a_ext) << (2*i);
                    3'b011:         raw_pp = $signed(a_ext) << (2*i + 1);
                    3'b100:         raw_pp = -($signed(a_ext) << (2*i + 1));
                    3'b101, 3'b110: raw_pp = -($signed(a_ext) << (2*i));
                    default:        raw_pp = 17'd0;
                endcase
            end
            
            assign pp[i] = raw_pp;
        end
    endgenerate

    // PP 4: Correção para unsigned (se b[7]=1, soma a << 8)
    assign pp[4] = (b[7]) ? (a_ext << 8) : 17'd0;

    // =========================================================
    // 2. Redução Estrutural com Compressores 4:2
    // =========================================================
    
    wire [16:0] s1, c1;
    wire [17:0] cout_chain;
    assign cout_chain[0] = 1'b0;

    genvar k;
    generate
        for (k = 0; k < 17; k = k + 1) begin : STAGE1
            compressor42 comp (
                .a(pp[0][k]),
                .b(pp[1][k]),
                .c(pp[2][k]),
                .d(pp[3][k]),
                .cin(cout_chain[k]),
                .sum(s1[k]),
                .carry(c1[k]),
                .cout(cout_chain[k+1])
            );
        end
    endgenerate

    // Soma final: s1 + (c1 << 1) + pp[4]
    assign product = s1[15:0] + (c1[14:0] << 1) + pp[4][15:0];

endmodule
