`timescale 1ps/1ps

module sim_cla_16bit;

    reg  [15:0] a, b;
    reg cin;
    wire [15:0] sum;
    wire cout;

    integer in_file, out_file;

    cla_16bit DUT (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin

        in_file = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\data\\dados_16bits_uniforme.txt", "r");
        out_file = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\results\\carry_lookahead_adder\\cla_results_16bits.txt", "w");

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
