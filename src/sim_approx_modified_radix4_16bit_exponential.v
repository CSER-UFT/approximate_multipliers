`timescale 1ns / 1ps

module sim_approx_modified_radix4_16bit_exponential;

    // DUT sinais
    reg  [15:0] a, b;
    wire [31:0] product;

    // Arquivos
    integer in_file;
    integer out_file;

    // DUT
    approx_modified_radix4_16bit dut (
        .a(a),
        .b(b),
        .product(product)
    );

    // Caminhos
    reg [1023:0] input_file  = "/home/jeova.barbosa/approximate_multipliers/data/16_exponential.txt";
    reg [1023:0] output_file = "/home/jeova.barbosa/approximate_multipliers/resultados/approx_modified_radix4_16bit_exponential.txt";
    
    initial begin
        in_file  = $fopen(input_file, "r");
        out_file = $fopen(output_file, "w");

        if(in_file == 0) begin
            $display("Erro ao abrir entrada: %s", input_file);
            $finish;
        end
        if(out_file == 0) begin
            $display("Erro ao abrir saída: %s", output_file);
            $finish;
        end

        $display("Simulação iniciada: approx_modified_radix4 16bit exponential");

        while ($fscanf(in_file, "%h %h", a, b) == 2) begin
            #10;
            $fwrite(out_file, "%h %h %h\n", a, b, product);
        end

        $fclose(in_file);
        $fclose(out_file);

        $display("Simulação concluída.");
        $finish;
    end

endmodule
