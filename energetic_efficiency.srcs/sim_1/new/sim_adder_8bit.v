`timescale 1ns / 1ps

module sim_adder_8bit;

    reg [7:0] a, b;
    reg cin;
    wire [7:0] sum;
    wire cout;

    integer in_file, out_file;

    adder_8bit dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin

        in_file = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\data\\8bits_entries.txt", "r");
        out_file = $fopen("C:\\Users\\joaop\\energetic_efficiency\\energetic_efficiency.srcs\\sim_1\\new\\results\\ripple_carry_adder\\ripple_results_8bits.txt", "w");

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
