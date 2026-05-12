`timescale 1ns / 1ps

module exact_32bit_simple (
    input [31:0] a,
    input [31:0] b,
    output [63:0] product
    );
    // O operador '*' produz um resultado de precisão completa (2n bits, usando um slice DSP48E2 segundo documentação da FPGA) 
    assign product = a * b;

endmodule
