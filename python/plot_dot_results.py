import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
import os

# =========================================================
# CONFIGURAÇÕES
# =========================================================

INPUT_CSV = "summary.csv"
PLOT_DIR = "./plots"
os.makedirs(PLOT_DIR, exist_ok=True)

# Mapeamento de tipos para nomes amigáveis
TYPE_MAP = {
    "exato": "Exato Estrutural",
    "simple": "Exato Funcional",
    "radix": "Radix-4 Booth",
    "modified": "Radix Modificado",
    "approx_radix4": "Radix-4 Booth Approx",
    "dsp_approx": "Radix-4 DSP Approx",
    "approx_modified": "Mod Radix Booth Approx",
    "ppp_approx": "Radix-4 PPP",
    "ppp_modified": "Mod Radix PPP",
    "approx_radix_comp": "Radix-4 Comp Approx",
    "approx_mod_radix_comp": "Mod Radix Comp Approx",
    "compressor": "Compressor 4:2",
    "radix4_compressor": "Radix + Compressor"
}

# Cores e estilos
sns.set_theme(style="whitegrid")

def classify(exp_name):
    """
    Extrai tipo, bits e distribuição do nome do experimento.
    """
    if "dsp_approx" in exp_name:
        tipo = "dsp_approx"
    elif "ppp_modified" in exp_name:
        tipo = "ppp_modified"
    elif "ppp_approx" in exp_name:
        tipo = "ppp_approx"
    elif "approx_modified_radix_compressor" in exp_name:
        tipo = "approx_mod_radix_comp"
    elif "approx_modified_radix4" in exp_name:
        tipo = "approx_modified"
    elif "approx_radix_compressor" in exp_name:
        tipo = "approx_radix_comp"
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

    # Extrair distribuição
    if "exponential" in exp_name:
        dist = "Exponencial"
    elif "normal" in exp_name:
        dist = "Normal"
    elif "uniform" in exp_name:
        dist = "Uniforme"
    else:
        dist = "Padrão"

    return tipo, bits, dist

def load_data(filepath):
    if not os.path.exists(filepath):
        print(f"Erro: Arquivo {filepath} não encontrado.")
        return None
    
    try:
        df = pd.read_csv(filepath)
    except Exception as e:
        print(f"Erro ao ler CSV: {e}")
        return None
    
    # Aplicar classificação
    classified = df['experiment'].apply(classify)
    df['type_key'] = [c[0] for c in classified]
    df['bits'] = [c[1] for c in classified]
    df['Distribution'] = [c[2] for c in classified]
    
    # Mapear para nomes amigáveis
    df['Architecture'] = df['type_key'].map(TYPE_MAP)
    
    # Calcular métricas extras
    if 'Dynamic Power (W)' in df.columns and 'Static Power (W)' in df.columns:
        df['Total Power (W)'] = df['Dynamic Power (W)'] + df['Static Power (W)']
    
    if 'Total Power (W)' in df.columns:
        df['Efficiency (W/bit)'] = df['Total Power (W)'] / df['bits'].apply(lambda x: x if x > 0 else 1)
    
    return df

def plot_dot_metric(df, metric, x_label, title, filename):
    """
    Gera um Cleveland Dot Plot com marcadores ocos (hollow).
    """
    plt.figure(figsize=(12, 10))
    
    # Filtrar arquiteturas presentes
    present_architectures = df['Architecture'].unique()
    order = [name for name in TYPE_MAP.values() if name in present_architectures]
    
    # Marcadores específicos
    marker_map = {
        "Exponencial": "o",
        "Normal": "^",
        "Uniforme": "s",
        "Padrão": "D"
    }
    
    # Criar o gráfico base usando scatterplot
    # Definimos linewidth para a borda ser visível
    ax = sns.scatterplot(
        data=df,
        y='Architecture',
        x=metric,
        hue='bits',
        style='Distribution',
        markers=marker_map,
        palette='viridis',
        s=150,
        linewidth=2,
        alpha=1.0
    )

    # Tornar os marcadores "vazios" (hollow)
    # Transferimos a cor do preenchimento para a borda e removemos o preenchimento
    for collection in ax.collections:
        facecolors = collection.get_facecolors()
        if len(facecolors) > 0:
            collection.set_edgecolors(facecolors)
            collection.set_facecolors('none')

    # Ajustar ordem e labels do eixo Y
    plt.gca().set_yticks(range(len(order)))
    plt.gca().set_yticklabels(order)
    
    plt.title(title, fontsize=15, fontweight='bold', pad=20)
    plt.xlabel(x_label, fontsize=12)
    plt.ylabel("Arquitetura", fontsize=12)
    
    # Configurar legenda
    legend = plt.legend(title="Legenda", bbox_to_anchor=(1.02, 1), loc='upper left')
    
    # Ajustar ícones da legenda para serem hollow
    handles = getattr(legend, 'legend_handles', getattr(legend, 'legendHandles', []))
    for handle in handles:
        if hasattr(handle, 'set_facecolor'):
            handle.set_edgecolors(handle.get_facecolors())
            handle.set_facecolors('none')
            handle.set_linewidth(2)
    
    plt.tight_layout()
    filepath = os.path.join(PLOT_DIR, filename)
    plt.savefig(filepath)
    plt.close()
    print(f"Gráfico gerado: {filepath}")

def main():
    df = load_data(INPUT_CSV)
    if df is None or df.empty:
        return

    metrics = [
        ("Total Power (W)", "Potência Total (W)", "Potência Total", "dot_potencia_total.pdf"),
        ("Dynamic Power (W)", "Potência Dinâmica (W)", "Potência Dinâmica", "dot_potencia_dinamica.pdf"),
        ("Slice LUTs", "Quantidade de LUTs", "Uso de LUTs", "dot_comparacao_lut.pdf"),
        ("Slice DSPs", "Quantidade de Blocos DSP", "Uso de Blocos DSP", "dot_comparacao_dsp.pdf"),
        ("Efficiency (W/bit)", "Eficiência Energética (W/bit)", "Eficiência Energética (menor = melhor)", "dot_eficiencia.pdf")
    ]

    print(f"Iniciando geração de gráficos de pontos em {PLOT_DIR}...")
    
    for metric_col, x_label, metric_name, filename in metrics:
        if metric_col in df.columns:
            plot_dot_metric(df, metric_col, x_label, f"Comparação de {metric_name}", filename)

    print("\nProcesso concluído. Gráficos salvos em ./plots")

if __name__ == "__main__":
    main()
