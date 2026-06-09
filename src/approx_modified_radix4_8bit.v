`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Modificado com Codificador de Booth Aproximado - 8 bits
 */
module approx_modified_radix4_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

    reg signed [16:0] result;
    reg signed [16:0] pp;
    reg [8:0] extended_b;
    reg [1:0] range_b;
    integer i;

    wire signed [16:0] a_ext = {9'd0, a};

    always @(*) begin
        result = 17'd0;
        extended_b = {b, 1'b0};

        // Detecção de Faixa Segura (Modified Radix)
        if (b[7:5] != 3'b000)      range_b = 3;
        else if (b[4:3] != 2'b00)   range_b = 2;
        else if (b[2:1] != 2'b00)   range_b = 1;
        else                        range_b = 0;

        for (i = 0; i < 4; i = i + 1) begin
            if (i <= range_b) begin
                case (extended_b[2*i +: 3])
                    3'b000, 3'b111: pp = 17'd0;
                    3'b001, 3'b010: pp = a_ext << (2*i);
                    3'b011:         pp = (i < 1) ? (a_ext << (2*i)) : (a_ext << (2*i + 1));
                    3'b100:         pp = (i < 1) ? -(a_ext << (2*i)) : -(a_ext << (2*i + 1));
                    3'b101, 3'b110: pp = -(a_ext << (2*i));
                    default:        pp = 17'd0;
                endcase
            end else begin
                pp = 17'd0;
            end
            result = result + pp;
        end

        if (b[7]) begin
            result = result + (a_ext << 8);
        end
    end

    assign product = result[15:0];

endmodule
