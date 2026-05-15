`timescale 1ns / 1ps

module sim_exact_32bit_simple_normal;

    // DUT sinais
    reg  [31:0] a, b;
    wire [63:0] product;

    // Arquivos
    integer in_file;
    integer out_file;
    integer r;

    // DUT
    exact_32bit_simple dut (
        .a(a),
        .b(b),
        .product(product)
    );

    // Caminhos
    reg [1023:0] input_file  = "../data/32_normal.txt";
    reg [1023:0] output_file = "../resultados/exact_32bit_simple_normal.txt";
    
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

        $display("Simulação iniciada: operador * 32_normal");

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