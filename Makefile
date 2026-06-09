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
	sim_approx_modified_radix4_16bit_exponential \
	sim_approx_modified_radix4_16bit_normal \
	sim_approx_modified_radix4_16bit_uniform \
	sim_approx_modified_radix4_8bit \
	sim_approx_modified_radix_compressor_16bit_exponential \
	sim_approx_modified_radix_compressor_16bit_normal \
	sim_approx_modified_radix_compressor_16bit_uniform \
	sim_approx_modified_radix_compressor_8bit \
	sim_approx_radix4_booth_16bit_exponential \
	sim_approx_radix4_booth_16bit_normal \
	sim_approx_radix4_booth_16bit_uniform \
	sim_approx_radix4_booth_8bit \
	sim_approx_radix4_LOA_16bit_exponential \
	sim_approx_radix4_LOA_16bit_normal \
	sim_approx_radix4_LOA_16bit_uniform \
	sim_approx_radix4_LOA_8bit \
	sim_approx_radix_compressor_16bit_exponential \
	sim_approx_radix_compressor_16bit_normal \
	sim_approx_radix_compressor_16bit_uniform \
	sim_approx_radix_compressor_8bit \
	sim_ppp_approx_radix4_16bit_exponential \
	sim_ppp_approx_radix4_16bit_normal \
	sim_ppp_approx_radix4_16bit_uniform \
	sim_ppp_approx_radix4_8bit \
	sim_ppp_modified_radix4_16bit_exponential \
	sim_ppp_modified_radix4_16bit_normal \
	sim_ppp_modified_radix4_16bit_uniform \
	sim_ppp_modified_radix4_8bit


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
