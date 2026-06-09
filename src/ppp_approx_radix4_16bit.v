`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Booth com Perfuração de Produtos Parciais (PPP) - 16 bits
 */
module ppp_approx_radix4_16bit (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] product
);

integer i;

reg [16:0] extended_b;
reg signed [32:0] pp;
reg signed [32:0] result;

wire signed [32:0] a_ext = {17'd0, a};

always @(*) begin
    result = 33'd0;
    extended_b = {b, 1'b0};

    for (i = 0; i < 8; i = i + 1) begin
        // Perfuração: Ignora os 2 primeiros PPs (menor peso)
        if (i < 2) begin
            pp = 33'd0;
        end else begin
            case (extended_b[2*i +: 3])
                3'b000, 3'b111: pp = 33'd0;
                3'b001, 3'b010: pp = a_ext << (2*i);
                3'b011:         pp = (a_ext << (2*i + 1));
                3'b100:         pp = -(a_ext << (2*i + 1));
                3'b101, 3'b110: pp = -(a_ext << (2*i));
                default:        pp = 33'd0;
            endcase
        end
        result = result + pp;
    end

    if (b[15]) begin
        result = result + (a_ext << 16);
    end
end

assign product = result[31:0];

endmodule
