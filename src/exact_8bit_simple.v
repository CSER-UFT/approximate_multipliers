`timescale 1ns / 1ps

module exact_8bit_simple (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
    );
    // O operador '*' produz um resultado de precisão completa (2n bits, usando um slice DSP48E2 segundo documentação da FPGA) 
    assign product = a * b;

endmodule
