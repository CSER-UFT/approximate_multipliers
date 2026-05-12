# ============================================================
# run.tcl - Fluxo completo (synth + impl + sim + VCD + reports)
# Uso via Makefile:
#   vivado -mode tcl -source run.tcl -tclargs <TB_NAME>
# ============================================================

# ==============================
# Argumento (nome do experimento)
# ==============================
if {$argc < 1} {
    puts "ERRO: informe o nome do testbench (ex: sim_adder_8bit)"
    exit 1
}

set TB_NAME [lindex $argv 0]

# ==============================
# Diretórios
# ==============================
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR   [file normalize "$SCRIPT_DIR/.."]

set SRC_DIR     "$ROOT_DIR/src"
set RESULTS_DIR "$ROOT_DIR/resultados"
set BUILD_DIR   "$ROOT_DIR/build/$TB_NAME"

file mkdir $RESULTS_DIR
file mkdir $BUILD_DIR

# ==============================
# Projeto
# ==============================
set PROJECT_NAME "${TB_NAME}_proj"

create_project $PROJECT_NAME $BUILD_DIR -part xc7s50csga324-1 -force
set_property target_language Verilog [current_project]
set_property source_mgmt_mode None [current_project]

# ==============================
# Adiciona TODOS os fontes
# ==============================
# add_files "$SRC_DIR/exact_8bit.v"
# add_files "$SRC_DIR/exact_8bit_simple.v"
# add_files "$SRC_DIR/sim_exact_8bit.v"
# add_files "$SRC_DIR/sim_exact_8bit_simple.v"
add_files "$SRC_DIR/exact_16bit.v"
add_files "$SRC_DIR/exact_16bit_simple.v"
add_files "$SRC_DIR/exact_32bit.v"
add_files "$SRC_DIR/exact_32bit_simple.v"
# add_files "$SRC_DIR/sim_exact_16bit_exponential.v"
# add_files "$SRC_DIR/sim_exact_16bit_normal.v"
# add_files "$SRC_DIR/sim_exact_16bit_uniform.v"
# add_files "$SRC_DIR/sim_exact_16bit_simple_exponential.v"
# add_files "$SRC_DIR/sim_exact_16bit_simple_normal.v"
# add_files "$SRC_DIR/sim_exact_16bit_simple_uniform.v"
# add_files "$SRC_DIR/sim_exact_32bit_exponential.v"
# add_files "$SRC_DIR/sim_exact_32bit_normal.v"
# add_files "$SRC_DIR/sim_exact_32bit_uniform.v"
# add_files "$SRC_DIR/sim_exact_32bit_simple_exponential.v"
# add_files "$SRC_DIR/sim_exact_32bit_simple_normal.v"
# add_files "$SRC_DIR/sim_exact_32bit_simple_uniform.v"

# Testbench atual
add_files -fileset sim_1 "$SRC_DIR/${TB_NAME}.v"

# ==============================
# Define TOP de síntese (genérico)
# ==============================
set name_no_sim [string range $TB_NAME 4 end]

# Casos:
# sim_exact_16bit_exponential
# -> exact_16bit
#
# sim_exact_16bit_simple_exponential
# -> exact_16bit_simple

if {[string match "*simple*" $name_no_sim]} {
    regexp {(exact_[0-9]+bit_simple)} $name_no_sim -> DESIGN_TOP
} else {
    regexp {(exact_[0-9]+bit)} $name_no_sim -> DESIGN_TOP
}

set_property top $DESIGN_TOP [get_filesets sources_1]
set_property top $TB_NAME    [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# ==============================
# Síntese
# ==============================
launch_runs synth_1
wait_on_run synth_1

# ==============================
# Implementação
# ==============================
launch_runs impl_1
wait_on_run impl_1

# ==============================
# Reports (resource + timing)
# ==============================
open_run impl_1

report_utilization -file "$RESULTS_DIR/${TB_NAME}_resource.rpt"
report_timing_summary -file "$RESULTS_DIR/${TB_NAME}_timing.rpt"

# ==============================
# Simulação + VCD
# ==============================
set SAIF_FILE "$RESULTS_DIR/${TB_NAME}.saif"

launch_simulation
restart

open_saif $SAIF_FILE

log_saif [get_objects -r /$TB_NAME/*]

run all

close_saif
close_sim

puts ">>> SAIF gerado: $SAIF_FILE"

# ==============================
# Power
# ==============================
open_run impl_1
read_saif $SAIF_FILE

create_clock -name clk -period 10.0

report_power -file "$RESULTS_DIR/${TB_NAME}_power.rpt"

puts ">>> Power gerado"

# ==============================
# Fim
# ==============================
puts "=== FINALIZADO: $TB_NAME ==="

exit
