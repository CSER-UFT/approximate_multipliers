`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Booth com Somador Aproximado LOA (Lower-part OR Adder)
 * 
 * Técnica: A acumulação dos produtos parciais utiliza o conceito de LOA.
 * - Os 16 bits menos significativos (LSBs) são calculados usando uma porta OR bit a bit.
 * - Os bits restantes (MSBs) utilizam um somador exato.
 * - A propagação de carry da parte aproximada para a exata é eliminada.
 */
module approx_radix4_LOA_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

integer i;

reg [32:0] extended_b;
reg signed [64:0] pp;
reg signed [64:0] result;

// Multiplicando 'a' estendido com zero para garantir operação unsigned (como nos outros modelos do projeto)
wire signed [64:0] a_ext = {33'd0, a};

// Fios para a lógica do LOA
wire [64:16] sum_msb;
wire [15:0]  sum_lsb;

always @(*) begin
    result = 65'd0;
    extended_b = {b, 1'b0};

    // Radix-4: 16 iterações para 32 bits
    for (i = 0; i < 16; i = i + 1) begin
        case (extended_b[2*i +: 3])
            3'b000, 3'b111: pp = 65'd0;
            3'b001, 3'b010: pp = a_ext << (2*i);
            3'b011:         pp = (a_ext << (2*i + 1));
            3'b100:         pp = -(a_ext << (2*i + 1));
            3'b101, 3'b110: pp = -(a_ext << (2*i));
            default:        pp = 65'd0;
        endcase
        
        // Aplicação do LOA na acumulação: result = result + pp
        // Parte LSB (aproximada): bits 15 down to 0 usando OR
        // Parte MSB (exata): bits 64 down to 16 usando somador exato
        // Carry-in para a parte exata: AND entre os bits na posição 15 (Padrão LOA)
        result = { (result[64:16] + pp[64:16] + (result[15] & pp[15])), (result[15:0] | pp[15:0]) };
    end

    // Correção para Unsigned (Tratamento de sinal conforme padrão do projeto)
    if (b[31]) begin
        pp = (a_ext << 32);
        // Aplicação do LOA também na correção final
        result = { (result[64:16] + pp[64:16] + (result[15] & pp[15])), (result[15:0] | pp[15:0]) };
    end
end

assign product = result[63:0];

endmodule
