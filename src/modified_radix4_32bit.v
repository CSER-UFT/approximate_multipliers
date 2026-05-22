`timescale 1ns / 1ps

module modified_radix4_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

    reg signed [64:0] result;
    reg signed [64:0] pp;
    reg [32:0] extended_b;
    reg [3:0] range_b;
    integer i;

    // Multiplicando 'a' estendido com zero para garantir operação unsigned
    wire signed [64:0] a_ext = {33'd0, a};

    always @(*) begin
        result = 65'd0;
        extended_b = {b, 1'b0};

        // Detecção de Faixa Segura (Considerando o bit de sobreposição do Booth)
        if (b[31:29] != 3'b000)
            range_b = 15;
        else if (b[28:27] != 2'b00)
            range_b = 14;
        else if (b[26:25] != 2'b00)
            range_b = 13;
        else if (b[24:23] != 2'b00)
            range_b = 12;
        else if (b[22:21] != 2'b00)
            range_b = 11;
        else if (b[20:19] != 2'b00)
            range_b = 10;
        else if (b[18:17] != 2'b00)
            range_b = 9;
        else if (b[16:15] != 2'b00)
            range_b = 8;
        else if (b[14:13] != 2'b00)
            range_b = 7;
        else if (b[12:11] != 2'b00)
            range_b = 6;
        else if (b[10:9] != 2'b00)
            range_b = 5;
        else if (b[8:7] != 2'b00)
            range_b = 4;
        else if (b[6:5] != 2'b00)
            range_b = 3;
        else if (b[4:3] != 2'b00)
            range_b = 2;
        else if (b[2:1] != 2'b00)
            range_b = 1;
        else
            range_b = 0;

        // Loop estático para síntese, com bloqueio dinâmico interno
        for (i = 0; i < 16; i = i + 1) begin
            if (i <= range_b) begin
                case (extended_b[2*i +: 3])
                    3'b000, 3'b111: pp = 65'd0;
                    3'b001, 3'b010: pp = a_ext << (2*i);
                    3'b011:         pp = (a_ext << (2*i + 1));
                    3'b100:         pp = -(a_ext << (2*i + 1));
                    3'b101, 3'b110: pp = -(a_ext << (2*i));
                    default:        pp = 65'd0;
                endcase
            end else begin
                pp = 65'd0;
            end
            result = result + pp;
        end

        // Correção para Unsigned
        if (b[31]) begin
            result = result + (a_ext << 32);
        end
    end

    assign product = result[63:0];

endmodule
