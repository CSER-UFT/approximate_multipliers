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

# Cores e estilos
sns.set_theme(style="whitegrid")

# Configurações de fonte para LaTeX
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

# Mapeamento de tipos para nomes amigáveis (Sincronizado com plot_results.py)
# A ordem aqui define a ordem no eixo Y do gráfico
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
    elif "approx_radix4_LOA" in exp_name:
        tipo = "approx_radix4_LOA"
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
    df['Bits'] = [c[1] for c in classified]
    df['Distribuição'] = [c[2] for c in classified]
    
    # Mapear para nomes amigáveis
    df['Architecture'] = df['type_key'].map(TYPE_MAP)
    
    # Nova coluna para separar exatos de aproximados
    df['is_approx'] = df['experiment'].str.contains('approx|ppp', case=False)

    # FORÇAR A ORDEM CATEGÓRICA para evitar desalinhamento no Seaborn
    order = [v for v in TYPE_MAP.values()]
    df['Architecture'] = pd.Categorical(df['Architecture'], categories=order, ordered=True)
    
    # Calcular métricas extras
    if 'Dynamic Power (W)' in df.columns and 'Static Power (W)' in df.columns:
        df['Total Power (W)'] = df['Dynamic Power (W)'] + df['Static Power (W)']
    
    if 'Total Power (W)' in df.columns:
        df['Efficiency (W/bit)'] = df['Total Power (W)'] / df['Bits'].apply(lambda x: x if x > 0 else 1)
    
    return df

def plot_dot_metric(df, metric, x_label, title, filename):
    """
    Gera um Cleveland Dot Plot com marcadores ocos (hollow).
    """
    # Remover categorias não utilizadas para evitar linhas vazias no gráfico
    df_plot = df.copy()
    if hasattr(df_plot['Architecture'], 'cat'):
        df_plot['Architecture'] = df_plot['Architecture'].cat.remove_unused_categories()

    plt.figure(figsize=(28, 26))
    
    # A ordem agora é ditada pela categoria definida no DataFrame
    order = [v for v in TYPE_MAP.values() if v in df_plot['Architecture'].unique()]
    
    # Marcadores específicos
    marker_map = {
        "Exponencial": "o",
        "Normal": "^",
        "Uniforme": "s",
        "Padrão": "D"
    }
    
    # Criar o gráfico base usando scatterplot
    # IMPORTANTE: Definimos explicitamente o eixo X como categórico e mantemos a ordem
    ax = sns.scatterplot(
        data=df_plot,
        x='Architecture',
        y=metric,
        hue='Bits',
        style='Distribuição',
        markers=marker_map,
        palette='viridis',
        s=1200,
        linewidth=6,
        alpha=1.0
    )

    # Tornar os marcadores "vazios" (hollow)
    for collection in ax.collections:
        facecolors = collection.get_facecolors()
        if len(facecolors) > 0:
            collection.set_edgecolors(facecolors)
            collection.set_facecolors('none')

    # Garantir que o eixo X respeite a ordem do TYPE_MAP e não ordene alfabeticamente
    plt.gca().set_xlim(-0.5, len(order)-0.5)
    plt.gca().set_xticks(range(len(order)))
    plt.gca().set_xticklabels(order, rotation=45, ha='right')
    
    plt.title(title, fontweight='bold', pad=30)
    plt.ylabel(x_label, labelpad=40)
    plt.xlabel("")
    
    # Configurar legenda customizada com espaço entre grupos
    handles, labels = ax.get_legend_handles_labels()
    
    new_handles = []
    new_labels = []
    
    for h, l in zip(handles, labels):
        # Se encontrarmos o início do grupo de Distribuição, inserimos um espaço em branco
        if l == 'Distribuição':
            # Handle "fantasma" invisível para criar o espaço (como um "enter")
            new_handles.append(plt.Line2D([0], [0], color='none'))
            new_labels.append("")
        elif l == 'Bits':
            new_handles.append(plt.Line2D([0], [0], color='none'))
            new_labels.append("")
        
        new_handles.append(h)
        new_labels.append(l)

    legend = plt.legend(
        new_handles, 
        new_labels,
        title="Legenda", 
        bbox_to_anchor=(1.02, 1), 
        loc='upper left',
        markerscale=1.2,
        labelspacing=0.8,
        handletextpad=1
    )
    
    # Ajustar ícones da legenda para serem hollow (após reconstruir a legenda)
    # No Matplotlib novo, os handles na legenda são acessados via legend_handles
    legend_handles = getattr(legend, 'legend_handles', getattr(legend, 'legendHandles', []))
    for handle in legend_handles:
        if hasattr(handle, 'set_facecolor'):
            # Apenas aplica o efeito hollow se for um marcador (evita mexer no spacer invisível)
            try:
                edge = handle.get_facecolor()
                handle.set_edgecolors(edge)
                handle.set_facecolors('none')
                handle.set_linewidth(6)
            except:
                pass
    
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
        ("Static Power (W)", "Potência Estática (W)", "Potência Estática", "dot_potencia_estatica.pdf"),
        ("Total Power (W)", "Potência Total (W)", "Potência Total", "dot_potencia_total.pdf"),
        ("Dynamic Power (W)", "Potência Dinâmica (W)", "Potência Dinâmica", "dot_potencia_dinamica.pdf"),
        ("Slice LUTs", "Quantidade de LUTs", "Uso de LUTs", "dot_comparacao_lut.pdf"),
        ("Slice DSPs", "Quantidade de Blocos DSP", "Uso de Blocos DSP", "dot_comparacao_dsp.pdf"),
        ("Efficiency (W/bit)", "Eficiência Energética (W/bit)", "Eficiência Energética (menor = melhor)", "dot_eficiencia.pdf")
    ]

    print(f"Iniciando geração de gráficos de pontos em {PLOT_DIR}...")
    
    # Separar os dados
    # Incluir o exato estrutural nos aproximados para servir de baseline
    df_approx = df[(df['is_approx'] | (df['type_key'] == 'exato')) & ~df['experiment'].str.contains('dsp', case=False)].copy()
    df_exact = df[~df['is_approx']].copy()
    
    # Gráfico sem separação (Todos), mas removendo multiplicadores com DSP
    df_no_dsp = df[~df['experiment'].str.contains('dsp', case=False)].copy()

    groups = [
        (df_exact, "exatos", "Exatos"),
        (df_approx, "aproximados", "Aproximados"),
        (df_no_dsp, "sem_dsp", "Todos")
    ]

    for df_subset, suffix, label in groups:
        if df_subset.empty:
            continue
            
        print(f"\nGerando gráficos para {label.lower()}...")
        for metric_col, x_label, metric_name, filename in metrics:
            if metric_col in df_subset.columns:
                new_filename = filename.replace(".pdf", f"_{suffix}.pdf")
                plot_dot_metric(df_subset, metric_col, x_label, f"Comparação de {metric_name} - {label}", new_filename)

    print("\nProcesso concluído. Gráficos salvos em ./plots")

if __name__ == "__main__":
    main()
