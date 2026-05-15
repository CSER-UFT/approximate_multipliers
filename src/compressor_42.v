module compressor42(
    input  a,
    input  b,
    input  c,
    input  d,
    input  cin,

    output sum,
    output carry,
    output cout
);

// Cout dependente apenas de a, b, c (lógica de Full Adder carry)
assign cout = (a & b) | (b & c) | (a & c);

wire s1 = a ^ b ^ c;

// Sum e Carry resultantes de FA(s1, d, cin)
assign sum = s1 ^ d ^ cin;
assign carry = (s1 & d) | (s1 & cin) | (d & cin);

endmodule