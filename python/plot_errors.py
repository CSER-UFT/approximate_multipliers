import csv
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# =========================================================
# CONFIGURAÇÕES
# =========================================================

INPUT_CSV = "métricas_erro.csv"
PLOT_DIR = "./plots/errors"
os.makedirs(PLOT_DIR, exist_ok=True)

# Cores e estilos
sns.set_theme(style="whitegrid")

# Configurações de fonte para LaTeX (Mesmas de plot_dot_results.py)
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

def plot_error_metric(df, metric, title, filename):
    """
    Gera um Cleveland Dot Plot (Gráfico de Pontos) comparando a métrica para diferentes arquiteturas.
    """
    plt.figure(figsize=(28, 26))
    
    # Marcadores específicos baseados na distribuição (formas geométricas ao invés de cores/texturas)
    marker_map = {
        "Exponencial": "o",
        "Normal": "^",
        "Uniforme": "s",
        "Padrão": "D"
    }

    # Gerar o gráfico de pontos
    ax = sns.scatterplot(
        data=df, 
        x='multiplier', 
        y=metric, 
        hue='Bits',
        style='Distribuição',
        markers=marker_map,
        palette='viridis',
        s=1200,
        linewidth=6,
        alpha=1.0
    )

    # Tornar os marcadores "vazios" (hollow) para consistência visual
    for collection in ax.collections:
        facecolors = collection.get_facecolors()
        if len(facecolors) > 0:
            collection.set_edgecolors(facecolors)
            collection.set_facecolors('none')

    # Ajustes dos Eixos
    order = df['multiplier'].unique()
    plt.gca().set_xlim(-0.5, len(order)-0.5)
    plt.gca().set_xticks(range(len(order)))
    plt.gca().set_xticklabels(order, rotation=45, ha='right')

    plt.title(title, fontweight='bold', pad=30)
    plt.xlabel("")
    plt.ylabel(metric, labelpad=40)
    
    # Configurar legenda customizada com espaço entre grupos
    handles, labels = ax.get_legend_handles_labels()
    
    new_handles = []
    new_labels = []
    
    for h, l in zip(handles, labels):
        if l == 'Distribuição':
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
        labelspacing=0.9,
        handletextpad=1
    )
    
    # Ajustar ícones da legenda para serem hollow
    legend_handles = getattr(legend, 'legend_handles', getattr(legend, 'legendHandles', []))
    for handle in legend_handles:
        if hasattr(handle, 'set_facecolor'):
            try:
                edge = handle.get_facecolor()
                handle.set_edgecolors(edge)
                handle.set_facecolors('none')
                handle.set_linewidth(6)
            except:
                pass
    
    # Verificação para escala logarítmica
    non_zero = df[df[metric] > 0][metric]
    if not non_zero.empty:
        max_val = non_zero.max()
        min_val = non_zero.min()
        if max_val / min_val > 50:
            plt.yscale('log')
            plt.ylabel(metric + " (Escala Log)", labelpad=40)

    plt.tight_layout()
    filepath = os.path.join(PLOT_DIR, filename)
    plt.savefig(filepath)
    plt.close()
    print(f"Gráfico de erro gerado: {filepath}")

def main():
    if not os.path.exists(INPUT_CSV):
        print(f"Erro: Arquivo {INPUT_CSV} não encontrado. Execute o calculate_errors.py primeiro.")
        return

    try:
        df = pd.read_csv(INPUT_CSV)
    except Exception as e:
        print(f"Erro ao ler CSV: {e}")
        return

    if df.empty:
        print("Aviso: O CSV de métricas está vazio.")
        return

    # Mapeamento de nomes
    name_map = {
        'approx_radix4': 'Radix-4 Booth Approx',
        'approx_radix4_LOA': 'Radix-4 LOA Approx',
        'ppp_approx': 'Radix-4 PPP',
        'approx_radix_comp': 'Radix-4 Comp Approx',
        'approx_modified': 'Mod Radix Booth Approx',
        'ppp_modified': 'Mod Radix PPP',
        'approx_mod_radix_comp': 'Mod Radix Comp Approx'
    }
    
    # Filtrar os multiplicadores
    df = df[df['multiplier'].isin(name_map.keys())].copy()
    
    # Aplicar o mapeamento (e garantir a ordem categórica)
    df['multiplier'] = pd.Categorical(df['multiplier'].map(name_map), categories=list(name_map.values()), ordered=True)
    df = df.sort_values(['multiplier', 'bits', 'distribution'])

    # Traduzir as distribuições e criar as colunas renomeadas para o plot
    dist_map = {
        'exponential': 'Exponencial',
        'normal': 'Normal',
        'uniform': 'Uniforme',
        'default': 'Padrão'
    }
    df['Distribuição'] = df['distribution'].map(dist_map).fillna(df['distribution'])

    # Converter bits para string categórica na nova coluna
    df['Bits'] = df['bits'].astype(str)

    # Métricas para plotar
    metrics = {
        "MAE": "Mean Absolute Error (MAE)",
        "NMED": "Normalized Mean Error Distance (NMED)",
        "MRED": "Mean Relative Error Distance (MRED)",
        "EP": "Error Probability (EP)",
        "MSE": "Mean Squared Error (MSE)"
    }

    print(f"Iniciando geração de gráficos de erro em {PLOT_DIR}...")

    for col, title in metrics.items():
        if col in df.columns:
            plot_error_metric(df, col, title, f"error_{col.lower()}.pdf")

    print("\nProcesso concluído com sucesso.")

if __name__ == "__main__":
    main()