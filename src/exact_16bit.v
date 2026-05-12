`timescale 1ns / 1ps

module exact_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

wire [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15;

// Fazendo shift-and-add
assign pp0 = b[0] ? (a << 0) : 32'b0;
assign pp1 = b[1] ? (a << 1) : 32'b0;
assign pp2 = b[2] ? (a << 2) : 32'b0;
assign pp3 = b[3] ? (a << 3) : 32'b0;
assign pp4 = b[4] ? (a << 4) : 32'b0;
assign pp5 = b[5] ? (a << 5) : 32'b0;
assign pp6 = b[6] ? (a << 6) : 32'b0;
assign pp7 = b[7] ? (a << 7) : 32'b0;
assign pp8 = b[8] ? (a << 8) : 32'b0;
assign pp9 = b[9] ? (a << 9) : 32'b0;
assign pp10 = b[10] ? (a << 10) : 32'b0;
assign pp11 = b[11] ? (a << 11) : 32'b0;
assign pp12 = b[12] ? (a << 12) : 32'b0;
assign pp13 = b[13] ? (a << 13) : 32'b0;
assign pp14 = b[14] ? (a << 14) : 32'b0;
assign pp15 = b[15] ? (a << 15) : 32'b0;

assign product = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7 + pp8 + pp9 + pp10 + pp11 + pp12 + pp13 + pp14 + pp15;

endmodule
