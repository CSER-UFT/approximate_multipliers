`timescale 1ns / 1ps

module modified_radix4_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

    reg signed [32:0] result;
    reg signed [32:0] pp;
    reg [16:0] extended_b;
    reg [3:0] range_b;
    integer i;

    // Multiplicando 'a' estendido com zero para garantir operação unsigned
    wire signed [32:0] a_ext = {17'd0, a};

    always @(*) begin
        result = 33'd0;
        extended_b = {b, 1'b0};

        // Detecção de Faixa Segura (Considerando o bit de sobreposição do Booth)
        // Verificamos pares de bits para decidir até qual iteração 'i' o cálculo é necessário.
        if (b[15:13] != 3'b000)
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
        for (i = 0; i < 8; i = i + 1) begin
            if (i <= range_b) begin
                case (extended_b[2*i +: 3])
                    3'b000, 3'b111: pp = 33'd0;
                    3'b001, 3'b010: pp = a_ext << (2*i);
                    3'b011:         pp = (a_ext << (2*i + 1));
                    3'b100:         pp = -(a_ext << (2*i + 1));
                    3'b101, 3'b110: pp = -(a_ext << (2*i));
                    default:        pp = 33'd0;
                endcase
            end else begin
                pp = 33'd0;
            end
            result = result + pp;
        end

        // Correção para Unsigned (Essencial para multiplicadores que só trabalham com inteiros positivos)
        if (b[15]) begin
            result = result + (a_ext << 16);
        end
    end

    assign product = result[31:0];

endmodule
