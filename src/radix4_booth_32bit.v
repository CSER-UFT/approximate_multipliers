`timescale 1ns / 1ps

module radix4_booth_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);

integer i;

reg [32:0] extended_b;
reg signed [64:0] pp;
reg signed [64:0] result;

// Multiplicando 'a' estendido com zero para garantir operação unsigned
wire signed [64:0] a_ext = {33'd0, a};

always @(*) begin
    result = 65'd0;
    extended_b = {b, 1'b0};

    // Mantém N/2 = 16 iterações
    for (i = 0; i < 16; i = i + 1) begin
        case (extended_b[2*i +: 3])
            3'b000, 3'b111: pp = 65'd0;
            3'b001, 3'b010: pp = a_ext << (2*i);
            3'b011:         pp = (a_ext << (2*i + 1));
            3'b100:         pp = -(a_ext << (2*i + 1));
            3'b101, 3'b110: pp = -(a_ext << (2*i));
            default:        pp = 65'd0;
        endcase
        result = result + pp;
    end

    // Correção para Unsigned
    if (b[31]) begin
        result = result + (a_ext << 32);
    end
end

assign product = result[63:0];

endmodule