`timescale 1ns / 1ps

module exact_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

wire [63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp16, pp17, pp18, pp19, pp20, pp21, pp22, pp23, pp24, pp25, pp26, pp27, pp28, pp29, pp30, pp31;

// Fazendo shift-and-add
assign pp0 = b[0] ? (a << 0) : 64'b0;
assign pp1 = b[1] ? (a << 1) : 64'b0;
assign pp2 = b[2] ? (a << 2) : 64'b0;
assign pp3 = b[3] ? (a << 3) : 64'b0;
assign pp4 = b[4] ? (a << 4) : 64'b0;
assign pp5 = b[5] ? (a << 5) : 64'b0;
assign pp6 = b[6] ? (a << 6) : 64'b0;
assign pp7 = b[7] ? (a << 7) : 64'b0;
assign pp8 = b[8] ? (a << 8) : 64'b0;
assign pp9 = b[9] ? (a << 9) : 64'b0;
assign pp10 = b[10] ? (a << 10) : 64'b0;
assign pp11 = b[11] ? (a << 11) : 64'b0;
assign pp12 = b[12] ? (a << 12) : 64'b0;
assign pp13 = b[13] ? (a << 13) : 64'b0;
assign pp14 = b[14] ? (a << 14) : 64'b0;
assign pp15 = b[15] ? (a << 15) : 64'b0;
assign pp16 = b[16] ? (a << 16) : 64'b0;
assign pp17 = b[17] ? (a << 17) : 64'b0;
assign pp18 = b[18] ? (a << 18) : 64'b0;
assign pp19 = b[19] ? (a << 19) : 64'b0;
assign pp20 = b[20] ? (a << 20) : 64'b0;
assign pp21 = b[21] ? (a << 21) : 64'b0;
assign pp22 = b[22] ? (a << 22) : 64'b0;
assign pp23 = b[23] ? (a << 23) : 64'b0;
assign pp24 = b[24] ? (a << 24) : 64'b0;
assign pp25 = b[25] ? (a << 25) : 64'b0;
assign pp26 = b[26] ? (a << 26) : 64'b0;
assign pp27 = b[27] ? (a << 27) : 64'b0;
assign pp28 = b[28] ? (a << 28) : 64'b0;
assign pp29 = b[29] ? (a << 29) : 64'b0;
assign pp30 = b[30] ? (a << 30) : 64'b0;
assign pp31 = b[31] ? (a << 31) : 64'b0;

assign product = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7 + pp8 + pp9 + pp10 + pp11 + pp12 + pp13 + pp14 + pp15 + pp16 + pp17 + pp18 + pp19 + pp20 + pp21 + pp22 + pp23 + pp24 + pp25 + pp26 + pp27 + pp28 + pp29 + pp30 + pp31;

endmodule
