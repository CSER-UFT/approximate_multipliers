`timescale 1ns / 1ps

module sim_approx_radix_compressor_32bit_normal;

    reg  [31:0] a, b;
    wire [63:0] product;

    integer in_file, out_file;

    approx_radix_compressor_32bit dut (
        .a(a), .b(b), .product(product)
    );

    reg [1023:0] input_file  = "/home/jeova.barbosa/approximate_multipliers/data/32_normal.txt";
    reg [1023:0] output_file = "/home/jeova.barbosa/approximate_multipliers/resultados/approx_radix_compressor_32bit_normal.txt";
    
    initial begin
        in_file  = $fopen(input_file, "r");
        out_file = $fopen(output_file, "w");

        if(in_file == 0 || out_file == 0) $finish;

        while ($fscanf(in_file, "%h %h", a, b) == 2) begin
            #10;
            $fwrite(out_file, "%h %h %h\n", a, b, product);
        end

        $fclose(in_file); $fclose(out_file);
        $finish;
    end
endmodule
