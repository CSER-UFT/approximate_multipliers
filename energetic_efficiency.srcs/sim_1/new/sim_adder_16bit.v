`timescale 1ns / 1ps

module sim_adder_16bit;

    reg [15:0] a, b;
    reg cin;
    wire [15:0] sum;
    wire cout;

    integer file_in, file_out;
    integer scan_file;

    adder_16bit dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        cin = 0;
        
        file_in = $fopen("dados_16bits_uniforme.txt", "r");
        if (file_in == 0) begin
            $display("Erro ao abrir arquivo de entrada.");
            $finish;
        end

        file_out = $fopen("resultados_16bits.txt", "w");

        while (!$feof(file_in)) begin
            scan_file = $fscanf(file_in, "%h %h\n", a, b);
            #10;
            $fwrite(file_out, "%04h + %04h = %04h (Cout=%b)\n", a, b, sum, cout);
        end

        $fclose(file_in);
        $fclose(file_out);

        $display("Simulação finalizada. Resultados salvos em resultados_16bits.txt.");
        $finish;
    end

endmodule
