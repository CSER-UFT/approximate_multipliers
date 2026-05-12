`timescale 1ns / 1ps

module exact_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

wire [15:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;

// Fazendo shift-and-add
assign pp0 = b[0] ? (a << 0) : 16'b0;
assign pp1 = b[1] ? (a << 1) : 16'b0;
assign pp2 = b[2] ? (a << 2) : 16'b0;
assign pp3 = b[3] ? (a << 3) : 16'b0;
assign pp4 = b[4] ? (a << 4) : 16'b0;
assign pp5 = b[5] ? (a << 5) : 16'b0;
assign pp6 = b[6] ? (a << 6) : 16'b0;
assign pp7 = b[7] ? (a << 7) : 16'b0;

assign product = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;

endmodule
