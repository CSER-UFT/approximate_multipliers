`timescale 1ns / 1ps

(* use_dsp = "yes" *)
module dsp_approx_radix4_booth_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

integer i;

reg [16:0] extended_b;
reg signed [32:0] pp;
reg signed [32:0] result;

// Multiplicando 'a' estendido com zero para garantir operação unsigned
wire signed [32:0] a_ext = {17'd0, a};

always @(*) begin
    result = 33'd0;
    extended_b = {b, 1'b0};

    // Mantém N/2 = 8 iterações
    for (i = 0; i < 8; i = i + 1) begin
        case (extended_b[2*i +: 3])
            3'b000, 3'b111: pp = 33'd0;
            3'b001, 3'b010: pp = a_ext << (2*i);
            // Aproximação: 3'b011 (+2A) -> pp = +A apenas para i < 2
            3'b011:         pp = (i < 2) ? (a_ext << (2*i)) : (a_ext << (2*i + 1));
            // Aproximação: 3'b100 (-2A) -> pp = -A apenas para i < 2
            3'b100:         pp = (i < 2) ? -(a_ext << (2*i)) : -(a_ext << (2*i + 1));
            3'b101, 3'b110: pp = -(a_ext << (2*i));
            default:        pp = 33'd0;
        endcase
        result = result + pp;
    end

    // Correção para Unsigned
    if (b[15]) begin
        result = result + (a_ext << 16);
    end
end

assign product = result[31:0];

endmodule
