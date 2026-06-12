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

# Configurações de fonte para LaTeX
plt.rcParams.update({
    'font.size': 22,
    'axes.titlesize': 26,
    'axes.labelsize': 24,
    'xtick.labelsize': 22,
    'ytick.labelsize': 22,
    'legend.fontsize': 20,
    'legend.title_fontsize': 22,
    'figure.titlesize': 28
})

def plot_error_metric(df, metric, title, filename):
    """
    Gera um gráfico de barras comparando a métrica para diferentes cenários.
    Usa escala logarítmica se a variação for muito grande.
    """
    plt.figure(figsize=(14, 8))
    
    # Criamos uma coluna combinada para o eixo X
    # Ordenar primeiro para garantir consistência
    df_plot = df.sort_values(['bits', 'distribution']).copy()
    df_plot['scenario'] = df_plot['bits'].astype(str) + "-bit\n" + df_plot['distribution']

    # Gerar o gráfico de barras
    ax = sns.barplot(
        data=df_plot, 
        x='scenario', 
        y=metric, 
        hue='multiplier',
        palette='magma'
    )

    plt.title(title, fontweight='bold')
    plt.xlabel("Cenário (Bits e Distribuição)")
    plt.ylabel(metric)
    plt.legend(title="Arquitetura", bbox_to_anchor=(1.02, 1), loc='upper left', borderaxespad=0.)
    
    # Verificação para escala logarítmica
    # Se o valor máximo for muito maior que o mínimo (não zero)
    non_zero = df_plot[df_plot[metric] > 0][metric]
    if not non_zero.empty:
        max_val = non_zero.max()
        min_val = non_zero.min()
        if max_val / min_val > 100:
            plt.yscale('log')
            plt.ylabel(metric + " (Escala Log)")

    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.xticks(rotation=0)
    plt.tight_layout()
    
    filepath = os.path.join(PLOT_DIR, filename)
    plt.savefig(filepath)
    plt.close()
    print(f"Gráfico de erro gerado: {filepath}")

def main():
    if not os.path.exists(INPUT_CSV):
        print(f"Erro: Arquivo {INPUT_CSV} não encontrado. Execute o calculate_errors.py primeiro.")
        return

    # Carregar dados
    try:
        df = pd.read_csv(INPUT_CSV)
    except Exception as e:
        print(f"Erro ao ler CSV: {e}")
        return

    if df.empty:
        print("Aviso: O CSV de métricas está vazio.")
        return

    # Mapeamento de nomes para melhor legibilidade
    name_map = {
        'approx_radix4': 'Radix-4 Booth Approx',
        'approx_radix4_LOA': 'Radix-4 LOA Approx',
        'dsp_approx': 'Radix-4 DSP Approx',
        'ppp_approx': 'Radix-4 PPP',
        'approx_radix_comp': 'Radix-4 Comp Approx',
        'approx_modified': 'Mod Radix Booth Approx',
        'ppp_modified': 'Mod Radix PPP',
        'approx_mod_radix_comp': 'Mod Radix Comp Approx'
    }
    
    # Filtrar apenas os multiplicadores aproximados que estão no name_map
    df = df[df['multiplier'].isin(name_map.keys())].copy()
    
    # Aplicar o mapeamento
    df['multiplier'] = df['multiplier'].map(name_map)

    # Métricas para plotar
    metrics = {
        "MAE": "Mean Absolute Error (MAE/MED)",
        "NMED": "Normalized Mean Error Distance (NMED)",
        "MRED": "Mean Relative Error Distance (MRED)",
        "EP": "Error Probability (EP)",
        "MSE": "Mean Squared Error (MSE)"
    }

    print(f"Iniciando geração de gráficos de erro em {PLOT_DIR}...")

    for col, title in metrics.items():
        if col in df.columns:
            # Filtramos valores 0 para o gráfico não ficar poluído com os casos exatos se houver muitos
            # Mas mantemos os multiplicadores que queremos comparar
            plot_error_metric(df, col, title, f"error_{col.lower().replace(' ', '_').replace('(', '').replace(')', '')}.pdf")

    print("\nProcesso concluído com sucesso.")

if __name__ == "__main__":
    main()
