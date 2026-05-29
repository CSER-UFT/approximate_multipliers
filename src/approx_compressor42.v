`timescale 1ns / 1ps

/**
 * Compressor 4:2 Aproximado (Versão Otimizada)
 * Esta versão utiliza uma lógica mais equilibrada para reduzir o erro médio.
 * O erro é zero para 1, 2 ou 3 entradas em '1' (considerando cin=0).
 * O erro é -2 apenas quando as 4 entradas são '1'.
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

    // Fios intermediários para otimizar o compartilhamento de portas
    wire x1 = a ^ b;
    wire x2 = c ^ d;

    // Sum exato para cin=0
    assign sum = x1 ^ x2;

    // Carry otimizado: captura o valor 2 quando (a,b)=(1,1) OU (c,d)=(1,1) OU (x1,x2)=(1,1)
    assign carry = (a & b) | (c & d) | (x1 & x2);

    // Mantém cout=0 para evitar propagação de carry horizontal se desejado,
    // mas a fiação nos multiplicadores suportaria uma lógica aqui.
    assign cout = 1'b0;

endmodule
