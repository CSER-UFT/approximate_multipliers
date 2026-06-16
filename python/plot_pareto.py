import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os
import re

# =========================================================
# CONFIGURAÇÕES
# =========================================================
SUMMARY_CSV = "summary.csv"
ERROR_CSV = "métricas_erro.csv"
PLOT_DIR = "./plots/tradeoff"
os.makedirs(PLOT_DIR, exist_ok=True)

sns.set_theme(style="whitegrid")

plt.rcParams.update({
    'font.size': 40,
    'axes.titlesize': 50,
    'axes.labelsize': 46,
    'xtick.labelsize': 40,
    'ytick.labelsize': 40,
    'legend.fontsize': 34,
    'legend.title_fontsize': 38,
    'figure.titlesize': 54
})

TYPE_MAP = {
    "exato": "Exato Estrutural",
    "simple": "Exato Funcional",
    "radix": "Radix-4 Booth",
    "modified": "Radix Modificado",
    "approx_radix4": "Radix-4 Booth Approx",
    "approx_radix4_LOA": "Radix-4 LOA Approx",
    "dsp_approx": "Radix-4 DSP Approx",
    "approx_modified": "Mod Radix Booth Approx",
    "ppp_approx": "Radix-4 PPP",
    "ppp_modified": "Mod Radix PPP",
    "approx_radix_comp": "Radix-4 Comp Approx",
    "approx_mod_radix_comp": "Mod Radix Comp Approx",
    "compressor": "Compressor 4:2",
    "radix4_compressor": "Radix + Compressor"
}

def classify(exp_name):
    if "dsp_approx" in exp_name: tipo = "dsp_approx"
    elif "ppp_modified" in exp_name: tipo = "ppp_modified"
    elif "ppp_approx" in exp_name: tipo = "ppp_approx"
    elif "approx_modified_radix_compressor" in exp_name: tipo = "approx_mod_radix_comp"
    elif "approx_modified_radix4" in exp_name: tipo = "approx_modified"
    elif "approx_radix_compressor" in exp_name: tipo = "approx_radix_comp"
    elif "approx_radix4_LOA" in exp_name: tipo = "approx_radix4_LOA"
    elif "approx_radix4" in exp_name: tipo = "approx_radix4"
    elif "radix4_compressor" in exp_name: tipo = "radix4_compressor"
    elif "modified" in exp_name: tipo = "modified"
    elif "simple" in exp_name: tipo = "simple"
    elif "radix" in exp_name: tipo = "radix"
    elif "compressor42" in exp_name: tipo = "compressor"
    else: tipo = "exato"

    bits_match = re.search(r"(\d+)bit", exp_name)
    bits = int(bits_match.group(1)) if bits_match else 0

    if "exponential" in exp_name: dist = "Exponencial"
    elif "normal" in exp_name: dist = "Normal"
    elif "uniform" in exp_name: dist = "Uniforme"
    else: dist = "Padrão"

    return tipo, bits, dist

def load_merged_data():
    # 1. Load Summary (Hardware)
    df_hw = pd.read_csv(SUMMARY_CSV)
    classified = df_hw['experiment'].apply(classify)
    df_hw['type_key'] = [c[0] for c in classified]
    df_hw['Bits'] = [c[1] for c in classified]
    df_hw['Distribuição'] = [c[2] for c in classified]
    df_hw['Architecture'] = df_hw['type_key'].map(TYPE_MAP)
    
    if 'Dynamic Power (W)' in df_hw.columns and 'Static Power (W)' in df_hw.columns:
        df_hw['Total Power (W)'] = df_hw['Dynamic Power (W)'] + df_hw['Static Power (W)']
    
    df_hw = df_hw[['Architecture', 'Bits', 'Distribuição', 'Total Power (W)', 'Slice LUTs']]

    # 2. Load Errors
    df_err = pd.read_csv(ERROR_CSV)
    name_map = {
        'approx_radix4': 'Radix-4 Booth Approx',
        'approx_radix4_LOA': 'Radix-4 LOA Approx',
        'ppp_approx': 'Radix-4 PPP',
        'approx_radix_comp': 'Radix-4 Comp Approx',
        'approx_modified': 'Mod Radix Booth Approx',
        'ppp_modified': 'Mod Radix PPP',
        'approx_mod_radix_comp': 'Mod Radix Comp Approx'
    }
    df_err = df_err[df_err['multiplier'].isin(name_map.keys())].copy()
    df_err['Architecture'] = df_err['multiplier'].map(name_map)
    df_err['Bits'] = df_err['bits'].astype(int)
    
    dist_map = {'exponential': 'Exponencial', 'normal': 'Normal', 'uniform': 'Uniforme', 'default': 'Padrão'}
    df_err['Distribuição'] = df_err['distribution'].map(dist_map).fillna(df_err['distribution'])
    
    df_err = df_err[['Architecture', 'Bits', 'Distribuição', 'NMED', 'MRED']]

    # 3. Merge
    df_merged = pd.merge(df_hw, df_err, on=['Architecture', 'Bits', 'Distribuição'], how='inner')
    
    # Para escala log funcionar, trocamos NMED = 0.0 (exatos) por um valor minúsculo (ex: 1e-12)
    df_merged['NMED_plot'] = df_merged['NMED'].replace(0, 1e-12)
    
    return df_merged

def get_pareto_front(df, x_col, y_col):
    """
    Identifica os pontos da fronteira de Pareto (onde ambos os eixos devem ser minimizados).
    """
    # Ordenar por X (Erro) crescente, e depois por Y (Hardware) crescente
    sorted_df = df.sort_values(by=[x_col, y_col])
    pareto_front = []
    min_y = float('inf')
    
    for _, row in sorted_df.iterrows():
        # Um ponto só é Pareto ótimo se tiver um Y menor que todos os pontos com X menor ou igual a ele
        if row[y_col] < min_y:
            pareto_front.append(row)
            min_y = row[y_col]
            
    return pd.DataFrame(pareto_front)

def plot_pareto(df, hw_metric, hw_label, filename):
    plt.figure(figsize=(28, 26))
    
    # Focando no cenário de 16 bits
    df_16 = df[df['Bits'] == 16].copy()
    
    if df_16.empty:
        print("Sem dados de 16 bits para Pareto.")
        return

    # Descobrir a fronteira de pareto
    pareto_df = get_pareto_front(df_16, 'NMED_plot', hw_metric)

    # Plotar a linha da Fronteira de Pareto
    plt.plot(
        pareto_df['NMED_plot'], 
        pareto_df[hw_metric], 
        color='gray', 
        linewidth=10, 
        alpha=0.5, 
        zorder=1,
        label='Fronteira de Pareto'
    )

    marker_map = {
        "Exponencial": "o",
        "Normal": "^",
        "Uniforme": "s",
        "Padrão": "D"
    }

    ax = sns.scatterplot(
        data=df_16, 
        x='NMED_plot', 
        y=hw_metric, 
        hue='Architecture',
        style='Distribuição',
        markers=marker_map,
        palette='tab10',
        s=1500,
        linewidth=6,
        alpha=0.9,
        zorder=2
    )

    # Tornar os marcadores "vazios" (hollow) e aplicar contorno preto nos que são Pareto Ótimos
    # Como matplotlib desenha todos juntos, é difícil alterar cor de borda de pontos específicos pós-scatterplot
    # Então aplicaremos a cor default hollow em todos.
    for collection in ax.collections:
        facecolors = collection.get_facecolors()
        if len(facecolors) > 0:
            collection.set_edgecolors(facecolors)
            collection.set_facecolors('none')

    plt.title(f"Trade-off: {hw_label} vs Erro Normalizado (NMED) - 16 Bits", fontweight='bold', pad=30)
    plt.xlabel("Distância Normalizada Média de Erro (NMED) - Menor é Melhor", labelpad=40)
    plt.ylabel(f"{hw_label} - Menor é Melhor", labelpad=40)
    
    plt.xscale('log')
    
    # Custom Legend
    handles, labels = ax.get_legend_handles_labels()
    
    # Procurar e limpar labels extras se necessário
    clean_handles = []
    clean_labels = []
    for h, l in zip(handles, labels):
        if l == 'Distribuição' or l == 'Architecture':
            clean_handles.append(plt.Line2D([0], [0], color='none'))
            clean_labels.append("")
        clean_handles.append(h)
        clean_labels.append(l)

    legend = plt.legend(
        clean_handles, clean_labels,
        title="Legenda", 
        bbox_to_anchor=(1.02, 1), 
        loc='upper left',
        markerscale=1.5,
        labelspacing=1.2,
        handletextpad=1.2
    )
    
    legend_handles = getattr(legend, 'legend_handles', getattr(legend, 'legendHandles', []))
    for handle in legend_handles:
        if hasattr(handle, 'set_facecolor'):
            try:
                edge = handle.get_facecolor()
                if isinstance(edge, np.ndarray) and len(edge) == 0:
                    pass
                else:
                    handle.set_edgecolors(edge)
                    handle.set_facecolors('none')
                    handle.set_linewidth(6)
            except:
                pass

    plt.tight_layout()
    filepath = os.path.join(PLOT_DIR, filename)
    plt.savefig(filepath)
    plt.close()
    print(f"Gráfico de Pareto gerado: {filepath}")

def main():
    if not os.path.exists(SUMMARY_CSV) or not os.path.exists(ERROR_CSV):
        print("Arquivos CSV não encontrados.")
        return

    df = load_merged_data()
    if df.empty:
        print("DataFrame mesclado está vazio. Verifique o mapeamento.")
        return

    print(f"Iniciando geração de gráficos de Pareto em {PLOT_DIR}...")
    plot_pareto(df, 'Total Power (W)', 'Potência Total (W)', 'pareto_potencia_vs_nmed.pdf')
    plot_pareto(df, 'Slice LUTs', 'Utilização de Área (Slice LUTs)', 'pareto_area_vs_nmed.pdf')
    print("Concluído.")

if __name__ == "__main__":
    main()