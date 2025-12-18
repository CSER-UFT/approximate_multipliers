import random

N = 10000
file_name = "32bits_uniform_distribution.txt"

with open(file_name, "w") as f:
    for _ in range(N):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        f.write(f"{a:08X} {b:08X}\n")

file_name_2 = "32bits_normal_distribution.txt"

MEAN = 0x7FFFFFFF
STD = 0x1FFFFFFF

with open(file_name_2, "w") as f:
    for _ in range(N):
        # normal
        a = int(random.gauss(MEAN, STD))
        b = int(random.gauss(MEAN, STD))

        # limitar ao range de 32 bits
        a = max(0, min(a, 0xFFFFFFFF))
        b = max(0, min(b, 0xFFFFFFFF))

        f.write(f"{a:08X} {b:08X}\n")