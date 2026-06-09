`timescale 1ns / 1ps

/**
 * Multiplicador Radix-4 Booth com Somador Aproximado LOA - 8 bits
 */
module approx_radix4_LOA_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

integer i;

reg [8:0] extended_b;
reg signed [16:0] pp;
reg signed [16:0] result;

wire signed [16:0] a_ext = {9'd0, a};

always @(*) begin
    result = 17'd0;
    extended_b = {b, 1'b0};

    for (i = 0; i < 4; i = i + 1) begin
        case (extended_b[2*i +: 3])
            3'b000, 3'b111: pp = 17'd0;
            3'b001, 3'b010: pp = a_ext << (2*i);
            3'b011:         pp = (a_ext << (2*i + 1));
            3'b100:         pp = -(a_ext << (2*i + 1));
            3'b101, 3'b110: pp = -(a_ext << (2*i));
            default:        pp = 17'd0;
        endcase
        
        // LOA: lower 4 bits
        result = { (result[16:4] + pp[16:4] + (result[3] & pp[3])), (result[3:0] | pp[3:0]) };
    end

    if (b[7]) begin
        pp = (a_ext << 8);
        result = { (result[16:4] + pp[16:4] + (result[3] & pp[3])), (result[3:0] | pp[3:0]) };
    end
end

assign product = result[15:0];

endmodule
