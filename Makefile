# =========================================================
# Makefile - Fluxo completo Vivado (genérico por experimento)
# =========================================================

# Diretórios
SRC_DIR     = ./src
DATA_DIR    = ./data
RESULTS_DIR = ./resultados
TCL_DIR     = ./tcl
BUILD_DIR   = ./build

# Script TCL
RUN_TCL = $(TCL_DIR)/sim.tcl

# Lista de experimentos (testbenches)
EXPERIMENTS = \
	sim_exact_16bit_exponential \
	sim_exact_16bit_normal \
	sim_exact_16bit_uniform \
	sim_exact_16bit_simple_exponential \
	sim_exact_16bit_simple_normal \
	sim_exact_16bit_simple_uniform \
	sim_exact_32bit_exponential \
	sim_exact_32bit_normal \
	sim_exact_32bit_uniform \
	sim_exact_32bit_simple_exponential \
	sim_exact_32bit_simple_normal \
	sim_exact_32bit_simple_uniform



# =========================================================
# Targets
# =========================================================

# Executa todos os experimentos
all: $(RESULTS_DIR) $(EXPERIMENTS)

# Executa um experimento específico:
# make run TB=sim_rca_16bit_uniform
run:
	@if [ -z "$(TB)" ]; then \
		echo "Uso: make run TB=<nome_do_testbench>"; \
		exit 1; \
	fi
	vivado -mode tcl -source $(RUN_TCL) -tclargs $(TB)

# Regra genérica para cada experimento
$(EXPERIMENTS): %: $(RESULTS_DIR)
	vivado -mode tcl -source $(RUN_TCL) -tclargs $@

# Garante pasta de resultados
$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)

# Limpeza
clean:
	rm -rf $(RESULTS_DIR) $(BUILD_DIR)

# Limpeza completa (inclui projetos Vivado)
clean_all:
	rm -rf $(RESULTS_DIR) $(BUILD_DIR) *.jou *.log .Xil

.PHONY: all run clean clean_all $(EXPERIMENTS)
