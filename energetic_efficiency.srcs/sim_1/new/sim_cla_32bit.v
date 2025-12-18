`timescale 1ns / 1ps

module sim_cla_32bit;

    reg [31:0] a, b;
    reg cin;
    wire [31:0] sum;
    wire cout;

    integer in_file, out_file;

    cla_32bit dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        in_file  = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\data\\entradas_32bits_uniforme.txt", "r");
        out_file = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\results\\carry_lookahead_adder\\cla_results_32bits.txt", "w");

        if (in_file == 0) begin
            $display("ERRO: não conseguiu abrir o arquivo de entrada.");
            $finish;
        end

        cin = 0;

        while(!$feof(in_file)) begin
            $fscanf(in_file, "%h %h\n", a, b);

            #1;

            $fwrite(out_file, "%h %b\n", sum, cout);
        end

        $fclose(in_file);
        $fclose(out_file);

        $display("Simulação finalizada com sucesso!");
        $finish;
    end

endmodule
