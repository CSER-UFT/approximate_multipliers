import os
import re
import csv
import numpy as np

RESULTS_DIR = "./resultados"
OUTPUT_CSV = "métricas_erro.csv"

# =========================================================
# Funções para Cálculo de Erro
# =========================================================

def calculate_ed(y_true, y_pred):
    """Error Distance (ED) - Retorna o vetor com as distâncias absolutas"""
    return np.abs(y_true - y_pred)

def calculate_mae(y_true, y_pred):
    """Mean Absolute Error (MAE) - Também chamado de Mean Error Distance (MED)"""
    return np.mean(np.abs(y_true - y_pred))

def calculate_mre(y_true, y_pred):
    """Mean Relative Error (MRE)"""
    ed = np.abs(y_true - y_pred)
    # Máscara para evitar divisão por zero onde o y_true é 0
    mask = y_true != 0
    if np.any(mask):
        return np.mean(ed[mask] / y_true[mask])
    return 0.0

def calculate_ep(y_true, y_pred):
    """Error Probability (EP)"""
    return np.mean(y_true != y_pred)

def calculate_mse(y_true, y_pred):
    """Mean Squared Error (MSE)"""
    return np.mean((y_true - y_pred)**2)

# =========================================================
# Funções Auxiliares
# =========================================================

def parse_filename(filename):
    """Extrai informações do nome do arquivo."""
    name = filename.replace(".txt", "")
    
    bits_match = re.search(r"(\d+)bit", name)
    if not bits_match:
        return None
    bits = bits_match.group(1)
    
    if "exponential" in name:
        dist = "exponential"
    elif "normal" in name:
        dist = "normal"
    elif "uniform" in name:
        dist = "uniform"
    else:
        dist = "default"
        
    if "radix4_compressor" in name:
        m_type = "radix4_compressor"
    elif "approx_radix4" in name:
        m_type = "approx_radix4"
    elif "modified" in name:
        m_type = "modified"
    elif "simple" in name:
        m_type = "simple"
    elif "radix" in name:
        m_type = "radix"
    elif "compressor42" in name:
        m_type = "compressor"
    else:
        m_type = "exact"
        
    return m_type, bits, dist

def load_results(filepath):
    """Lê o arquivo .txt e extrai a terceira coluna (produto) em decimal."""
    products = []
    with open(filepath, "r") as f:
        for line in f:
            parts = line.split()
            # Pega o produto (3ª coluna) assumindo o formato: A B Produto
            if len(parts) >= 3:
                try:
                    products.append(int(parts[2], 16))
                except ValueError:
                    continue
    return np.array(products, dtype=np.float64)

# =========================================================
# Programa Principal
# =========================================================

def main():
    if not os.path.exists(RESULTS_DIR):
        print(f"Erro: Pasta {RESULTS_DIR} não encontrada.")
        return

    files = [f for f in os.listdir(RESULTS_DIR) if f.endswith(".txt")]
    
    # Agrupa os arquivos por (bits, dist)
    groups = {}
    for f in files:
        parsed = parse_filename(f)
        if not parsed:
            continue
        m_type, bits, dist = parsed
        key = (bits, dist)
        if key not in groups:
            groups[key] = {}
        groups[key][m_type] = f

    results = []

    for (bits, dist), multipliers in groups.items():
        # Usa o 'exact' como referência verdadeira
        if "exact" not in multipliers:
            print(f"Aviso: Referência 'exact' não encontrada para {bits} bits - {dist}. Pulando grupo.")
            continue
        
        print(f"Processando {bits} bits - {dist}...")
        ref_path = os.path.join(RESULTS_DIR, multipliers["exact"])
        y_true = load_results(ref_path)
        
        for m_type, filename in multipliers.items():
            if m_type == "exact":
                continue
                
            file_path = os.path.join(RESULTS_DIR, filename)
            y_pred = load_results(file_path)
            
            # Tratamento caso haja pequena variação na quantidade de linhas na simulação
            if len(y_true) != len(y_pred):
                min_len = min(len(y_true), len(y_pred))
                y_t = y_true[:min_len]
                y_p = y_pred[:min_len]
            else:
                y_t = y_true
                y_p = y_pred

            # Cálculo das 5 métricas
            ed_vec = calculate_ed(y_t, y_p)
            med = np.mean(ed_vec) # Mean Error Distance (ED médio)
            mae = calculate_mae(y_t, y_p)
            mre = calculate_mre(y_t, y_p)
            ep = calculate_ep(y_t, y_p)
            mse = calculate_mse(y_t, y_p)
            
            results.append({
                "experiment": filename.replace(".txt", ""),
                "multiplier": m_type,
                "bits": bits,
                "distribution": dist,
                "ED (MED)": med,
                "MAE": mae,
                "MRE": mre,
                "EP": ep,
                "MSE": mse
            })

    # Ordena os resultados
    results.sort(key=lambda x: (int(x["bits"]), x["distribution"], x["multiplier"]))

    # Salva no CSV
    fieldnames = ["experiment", "multiplier", "bits", "distribution", "ED (MED)", "MAE", "MRE", "EP", "MSE"]
    with open(OUTPUT_CSV, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in results:
            writer.writerow(row)

    print(f"\nMétricas calculadas e salvas em {OUTPUT_CSV}")

if __name__ == "__main__":
    main()
