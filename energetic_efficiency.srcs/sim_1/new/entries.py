# gerar_dados_8bits.py
with open("dados_8bits.txt", "w") as f:
    for a in range(256):
        for b in range(256):
            f.write(f"{a:02X} {b:02X}\n")