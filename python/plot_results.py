import csv
import re
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
from collections import defaultdict
import os

# =========================================================
# CONFIGURAÇÕES
# =========================================================

INPUT_CSV = "summary.csv"
PLOT_DIR = "./plots"
os.makedirs(PLOT_DIR, exist_ok=True)

# =========================================================
# Funções auxiliares
# =========================================================

def classify(exp_name):
    """
    Extrai:
    - tipo: exato / simples
    - bits: 8 (por enquanto)
    """
    if "simple" in exp_name:
        tipo = "simple"
    elif "radix" in exp_name:
        tipo = "radix"
    elif "compressor42" in exp_name:
        tipo = "compressor"
    else:
        tipo = "exato"

    bits_match = re.search(r"(\d+)bit", exp_name)
    bits = int(bits_match.group(1)) if bits_match else 0
    return tipo, bits

def plot_bar(data_dict, metric_key, y_label, title, filename):
    """Gera gráfico de barras comparando exato, simples e radix por largura de bit"""
    plt.figure()
    bit_sizes = sorted({b for t in data_dict for b in data_dict[t]})
    x = range(len(bit_sizes))
    width = 0.20

    exato_vals = [data_dict["exato"].get(b, {}).get(metric_key, 0) for b in bit_sizes]
    simples_vals = [data_dict["simple"].get(b, {}).get(metric_key, 0) for b in bit_sizes]
    radix_vals = [data_dict["radix"].get(b, {}).get(metric_key, 0) for b in bit_sizes]
    compressor_vals = [data_dict["compressor"].get(b, {}).get(metric_key, 0) for b in bit_sizes]

    plt.bar([i - width for i in x], exato_vals, width=width, label="EXATO ESTRUTURAL")
    plt.bar([i for i in x], simples_vals, width=width, label="EXATO FUNCIONAL")
    plt.bar([i + width for i in x], radix_vals, width=width, label="RADIX-4")
    plt.bar([i + + width + width for i in x], compressor_vals, width=width, label="COMPRESSOR 4:2")

    plt.xticks(x, [f"{b}-bit" for b in bit_sizes])
    plt.ylabel(y_label)
    plt.title(title)
    plt.legend(fontsize=8.5)

    if metric_key == "dsp":
        plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))

    plt.tight_layout()
    filepath = os.path.join(PLOT_DIR, filename)
    plt.savefig(filepath)
    plt.close()
    print(f"Plot gerado: {filepath}")

# =========================================================
# Leitura e organização
# =========================================================

data = defaultdict(lambda: defaultdict(dict))
# data[tipo][bits] = {metrics}

with open(INPUT_CSV, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        exp = row["experiment"]
        tipo, bits = classify(exp)

        lut = int(row["Slice LUTs"])
        reg = int(row["Slice Registers"])
        dsp = int(row["Slice DSPs"])
        dyn = float(row["Dynamic Power (W)"])
        sta = float(row["Static Power (W)"])
        total = sta + dyn

        data[tipo][bits] = {
            "lut": lut,
            "reg": reg,
            "dsp": dsp,
            "dynamic": dyn,
            "static": sta,
            "total": total
        }

# =========================================================
# GRÁFICOS DE ENERGIA
# =========================================================

plot_bar(data, "total", "Potência (W)", "Comparação de Potência Total", "potencia_total.pdf")
plot_bar(data, "dynamic", "Potência (W)", "Comparação de Potência Dinâmica", "potencia_dinamica.pdf")
plot_bar(data, "static", "Potência (W)", "Comparação de Potência Estática", "potencia_estatica.pdf")

# =========================================================
# GRÁFICOS DE LUTs, Registers e Eficiência
# =========================================================

plot_bar(data, "lut", "Quantidade de LUTs", "Comparação de uso de LUTs", "comparacao_lut.pdf")
plot_bar(data, "reg", "Quantidade de Registradores", "Comparação de uso de Registradores", "comparacao_registradores.pdf")
plot_bar(data, "dsp", "Quantidade de Blocos DSP", "Comparação de uso de Blocos DSP", "comparacao_dsp.pdf")

# Eficiência energética (W/bit)
for tipo in data:
    for b in data[tipo]:
        data[tipo][b]["efficiency"] = data[tipo][b]["total"] / b if b != 0 else 0

plot_bar(data, "efficiency", "Potência por bit (W/bit)", "Eficiência Energética (menor = melhor)", "eficiencia.pdf")

print("Todos os gráficos gerados na pasta ./plots")
