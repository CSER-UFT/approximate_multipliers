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
    - tipo: diversas arquiteturas exatas e aproximadas
    - bits: largura de bit
    """
    if "dsp_approx" in exp_name:
        tipo = "dsp_approx"
    elif "ppp_modified" in exp_name:
        tipo = "ppp_modified"
    elif "ppp_approx" in exp_name:
        tipo = "ppp_approx"
    elif "approx_modified_radix4" in exp_name:
        tipo = "approx_modified"
    elif "approx_radix4" in exp_name:
        tipo = "approx_radix4"
    elif "radix4_compressor" in exp_name:
        tipo = "radix4_compressor"
    elif "modified" in exp_name:
        tipo = "modified"
    elif "simple" in exp_name:
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
    """Gera gráfico de barras comparando os tipos por largura de bit"""
    plt.figure(figsize=(15, 8))
    bit_sizes = sorted({b for t in data_dict for b in data_dict[t]})
    x = range(len(bit_sizes))

    # Função para obter média dos valores
    def get_val(t, b, k):
        vals = data_dict.get(t, {}).get(b, {}).get(k, [0])
        return sum(vals) / len(vals) if vals else 0
    
    types = [
        ("exato", "Exato Estrutural"),
        ("simple", "Exato Funcional"),
        ("radix", "Radix-4 Booth"),
        ("modified", "Radix Modificado"),
        ("approx_radix4", "Radix-4 Booth Approx"),
        ("dsp_approx", "Radix-4 DSP Approx"),
        ("approx_modified", "Mod Radix Booth Approx"),
        ("ppp_approx", "Radix-4 PPP"),
        ("ppp_modified", "Mod Radix PPP"),
        ("approx_radix_comp", "Radix-4 Comp Approx"),
        ("approx_mod_radix_comp", "Mod Radix Comp Approx"),
        ("compressor", "Compressor 4:2"),
        ("radix4_compressor", "Radix + Compressor")
    ]

    # Filtrar apenas tipos que possuem dados
    active_types = [t for t in types if any(get_val(t[0], b, metric_key) > 0 for b in bit_sizes)]
    
    num_types = len(active_types)
    width = 0.8 / num_types  # Distribui as barras no espaço de 0.8 unidades

    for i, (t_key, t_label) in enumerate(active_types):
        vals = [get_val(t_key, b, metric_key) for b in bit_sizes]
        offset = (i - (num_types-1)/2) * width
        plt.bar([pos + offset for pos in x], vals, width=width, label=t_label)

    plt.xticks(x, [f"{b}-bit" for b in bit_sizes])
    plt.ylabel(y_label)
    plt.title(title)
    plt.legend(fontsize=9, loc='upper left', bbox_to_anchor=(1, 1))

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

# data[tipo][bits][metrica] = list of values (to be averaged)
data = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))

with open(INPUT_CSV, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        exp = row["experiment"]
        tipo, bits = classify(exp)

        data[tipo][bits]["lut"].append(int(row["Slice LUTs"]))
        data[tipo][bits]["reg"].append(int(row["Slice Registers"]))
        data[tipo][bits]["dsp"].append(int(row["Slice DSPs"]))
        
        dyn = float(row["Dynamic Power (W)"])
        sta = float(row["Static Power (W)"])
        data[tipo][bits]["dynamic"].append(dyn)
        data[tipo][bits]["static"].append(sta)
        data[tipo][bits]["total"].append(sta + dyn)

# =========================================================
# GRÁFICOS
# =========================================================

plot_bar(data, "total", "Potência (W)", "Comparação de Potência Total", "potencia_total.pdf")
plot_bar(data, "dynamic", "Potência (W)", "Comparação de Potência Dinâmica", "potencia_dinamica.pdf")
plot_bar(data, "static", "Potência (W)", "Comparação de Potência Estática", "potencia_estatica.pdf")

# =========================================================
# GRÁFICOS DE LUTs, Registers e Eficiência
# =========================================================

plot_bar(data, "lut", "Quantidade de LUTs", "Comparação de uso de LUTs", "comparacao_lut.pdf")
#plot_bar(data, "reg", "Quantidade de Registradores", "Comparação de uso de Registradores", "comparacao_registradores.pdf")
plot_bar(data, "dsp", "Quantidade de Blocos DSP", "Comparação de uso de Blocos DSP", "comparacao_dsp.pdf")

# Eficiência energética (W/bit) - calculada sobre a média do total
for tipo in data:
    for b in data[tipo]:
        if b != 0:
            avg_total = sum(data[tipo][b]["total"]) / len(data[tipo][b]["total"])
            data[tipo][b]["efficiency"] = [avg_total / b]
        else:
            data[tipo][b]["efficiency"] = [0]

plot_bar(data, "efficiency", "Potência por bit (W/bit)", "Eficiência Energética (menor = melhor)", "eficiencia.pdf")


print("Todos os gráficos gerados na pasta ./plots")
