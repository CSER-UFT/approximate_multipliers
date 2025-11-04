`timescale 1ns / 1ps

module sim_adder_8bit;

    reg [7:0] a, b;
    reg cin;
    wire [7:0] sum;
    wire cout;

    integer file_in, file_out;
    integer scan_file;

    adder_8bit dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        cin = 0;

        file_in = $fopen("dados_8bits.txt", "r");
        if (file_in == 0) begin
            $display("Erro: não foi possível abrir arquivo de entrada.");
            $finish;
        end

        file_out = $fopen("resultados_8bits.txt", "w");

        while (!$feof(file_in)) begin
            scan_file = $fscanf(file_in, "%h %h\n", a, b);
            #10;
            $fwrite(file_out, "%02h + %02h = %02h (Cout=%b)\n", a, b, sum, cout);
        end

        $fclose(file_in);
        $fclose(file_out);

        $display("Simulação finalizada. Resultados salvos em resultados_8bits.txt.");
        $finish;
    end

endmodule
