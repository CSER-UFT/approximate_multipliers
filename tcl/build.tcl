# Set project name and part
set project_name "approximate_multipliers"
set part_name "xc7s50csga324-1"

# Create project
create_project $project_name . -part $part_name -force
set_property target_language Verilog [current_project]

# Add design sources
add_files -norecurse ./src/exact_8bit_simple.v
add_files -norecurse ./src/exact_8bit.v
add_files -norecurse ./src/exact_16bit_simple.v
add_files -norecurse ./src/exact_16bit.v
add_files -norecurse ./src/exact_32bit_simple.v
add_files -norecurse ./src/exact_32bit.v

# Add testbench sources
add_files -norecurse ./src/sim_exact_8bit_simple.v
add_files -norecurse ./src/sim_exact_8bit.v
add_files -norecurse ./src/sim_exact_16bit_exponential.v
add_files -norecurse ./src/sim_exact_16bit_normal.v
add_files -norecurse ./src/sim_exact_16bit_uniform.v
add_files -norecurse ./src/sim_exact_16bit_simple_exponential.v
add_files -norecurse ./src/sim_exact_16bit_simple_normal.v
add_files -norecurse ./src/sim_exact_16bit_simple_uniform.v
add_files -norecurse ./src/sim_exact_32bit_exponential.v
add_files -norecurse ./src/sim_exact_32bit_normal.v
add_files -norecurse ./src/sim_exact_32bit_uniform.v
add_files -norecurse ./src/sim_exact_32bit_simple_exponential.v
add_files -norecurse ./src/sim_exact_32bit_simple_normal.v
add_files -norecurse ./src/sim_exact_32bit_simple_uniform.v

# Synthesize design exact
synth_design -top exact_8bit
write_checkpoint -force ./resultados/exact_8bit_synth.dcp
report_utilization -file ./resultados/exact_8bit_utilization.rpt
report_timing -file ./resultados/exact_8bit_timing.rpt
report_power -file ./resultados/exact_8bit_power.rpt

synth_design -top exact_16bit
write_checkpoint -force ./resultados/exact_16bit_synth.dcp
report_utilization -file ./resultados/exact_16bit_utilization.rpt
report_timing -file ./resultados/exact_16bit_timing.rpt
report_power -file ./resultados/exact_16bit_power.rpt

synth_design -top exact_32bit
write_checkpoint -force ./resultados/exact_32bit_synth.dcp
report_utilization -file ./resultados/exact_32bit_utilization.rpt
report_timing -file ./resultados/exact_32bit_timing.rpt
report_power -file ./resultados/exact_32bit_power.rpt


# Synthesize design simples
synth_design -top exact_8bit_simple
write_checkpoint -force ./resultados/exact_8bit_simple_synth.dcp
report_utilization -file ./resultados/exact_8bit_simple_utilization.rpt
report_timing -file ./resultados/exact_8bit_simple_timing.rpt
report_power -file ./resultados/exact_8bit_simple_power.rpt

synth_design -top exact_16bit_simple
write_checkpoint -force ./resultados/exact_16bit_simple_synth.dcp
report_utilization -file ./resultados/exact_16bit_simple_utilization.rpt
report_timing -file ./resultados/exact_16bit_simple_timing.rpt
report_power -file ./resultados/exact_16bit_simple_power.rpt

synth_design -top exact_32bit_simple
write_checkpoint -force ./resultados/exact_32bit_simple_ynth.dcp
report_utilization -file ./resultados/exact_32bit_simple_utilization.rpt
report_timing -file ./resultados/exact_32bit_simple_timing.rpt
report_power -file ./resultados/exact_32bit_simple_power.rpt

# synth_design -top cla_32bit
# write_checkpoint -force ./results/cla_32bit_synth.dcp
# report_utilization -file ./results/cla_32bit_utilization.rpt
# report_timing -file ./results/cla_32bit_timing.rpt

# Implement design
place_design
route_design
# write_bitstream -force ./results/design.bit

exit
