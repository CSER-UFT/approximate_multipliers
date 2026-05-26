`timescale 1ns / 1ps

/**
 * Compressor 4:2 Aproximado
 * Esta versão simplifica a lógica eliminando a dependência do cin/cout 
 * e utilizando portas lógicas mais simples para reduzir área e potência.
 */
module approx_compressor42(
    input  a,
    input  b,
    input  c,
    input  d,
    input  cin,

    output sum,
    output carry,
    output cout
);

    // Na maioria das arquiteturas de compressores aproximados, 
    // a corrente de carry (cin/cout) é eliminada para quebrar o caminho crítico.
    assign cout = 1'b0;

    // Lógica simplificada (baseada em arquiteturas comuns de baixa potência)
    // Erro introduzido em troca de redução de portas XOR
    assign sum = (a ^ b) | (c ^ d);
    assign carry = (a & b) | (c & d);

endmodule
