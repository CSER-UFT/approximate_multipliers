import numpy as np

# =========================
# CONFIGURAÇÕES
# =========================
N = 10_000

scale_16 = 2**12   # controla a distribuição (16 bits)
scale_32 = 2**24   # controla a distribuição (32 bits)

# =========================
# 16 BITS
# =========================
A16 = np.random.exponential(scale=scale_16, size=N)
B16 = np.random.exponential(scale=scale_16, size=N)

A16 = np.clip(A16, 0, 2**16 - 1).astype(np.uint16)
B16 = np.clip(B16, 0, 2**16 - 1).astype(np.uint16)

with open("16bits_exponential_distribution.txt", "w") as f:
    for a, b in zip(A16, B16):
        f.write(f"{a:04X} {b:04X}\n")

# =========================
# 32 BITS
# =========================
A32 = np.random.exponential(scale=scale_32, size=N)
B32 = np.random.exponential(scale=scale_32, size=N)

A32 = np.clip(A32, 0, 2**32 - 1).astype(np.uint32)
B32 = np.clip(B32, 0, 2**32 - 1).astype(np.uint32)

with open("32bits_exponential_distribution.txt", "w") as f:
    for a, b in zip(A32, B32):
        f.write(f"{a:08X} {b:08X}\n")
