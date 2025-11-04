import numpy as np

np.random.seed(42)

a_uniform = np.random.randint(0, 2**16, 10000, dtype=np.uint16)
b_uniform = np.random.randint(0, 2**16, 10000, dtype=np.uint16)

with open("dados_16bits_uniforme.txt", "w") as f:
    for a, b in zip(a_uniform, b_uniform):
        f.write(f"{a:04X} {b:04X}\n")

print("✅ Arquivo 'dados_16bits_uniforme.txt' gerado.")

mean, std = 32768, 8192
a_normal = np.clip(np.random.normal(mean, std, 10000), 0, 65535).astype(np.uint16)
b_normal = np.clip(np.random.normal(mean, std, 10000), 0, 65535).astype(np.uint16)

with open("dados_16bits_normal.txt", "w") as f:
    for a, b in zip(a_normal, b_normal):
        f.write(f"{a:04X} {b:04X}\n")

print("✅ Arquivo 'dados_16bits_normal.txt' gerado.")
