# Estudo de Multiplicadores Exatos e Aproximados

Este repositório contém uma análise comparativa de diversas arquiteturas de multiplicadores, focando em trade-offs entre precisão aritmética (erro) e consumo de potência.

## 1. Multiplicadores Exatos

### Abordagens Estruturais
- **Exact Simple (* operator):** Utiliza a implementação nativa da ferramenta de síntese (Vivado). Em FPGAs, isso geralmente resulta em instâncias altamente otimizadas que utilizam blocos de hardware dedicados (DSPs).
    - **Gargalo:** Opacidade da estrutura e dependência total da ferramenta.
- **Exact Structural:** Implementação baseada em árvore de redução Wallace/Dadda com somadores completos.
    - **Gargalo:** Caminho crítico longo no somador final de propagação de carry (CPA).
- **Compressor 4:2:** Utiliza compressores 4:2 para reduzir os produtos parciais em menos estágios que somadores tradicionais.
    - **Gargalo:** Complexidade de roteamento e atraso intrínseco das portas XOR.
- **Radix-4 Booth:** Reduz o número de produtos parciais pela metade (N/2) através da codificação Booth.
    - **Gargalo:** Lógica de codificação e a necessidade de gerar o termo 2A (shift à esquerda).
- **Modified Radix-4:** Semelhante ao Booth, mas inclui uma lógica de gating para desativar produtos parciais baseada na magnitude dos operandos.
    - **Gargalo:** Overhead da lógica de detecção de faixa (range detection).

---

## 2. Multiplicadores Aproximados

Nesta seção, exploramos como simplificações estruturais impactam o resultado final.

### Abordagens de Aproximação
1.  **Partial Product Perforation (PPP):**
    - **Descrição:** Ignora-se os produtos parciais de menor peso (LSBs). No código, os dois primeiros produtos parciais são forçados a zero.
    - **Relação com Resultado:** O erro inserido é **muito baixo** (NMED na ordem de 10^-10), pois afeta apenas os bits menos significativos. É uma das técnicas mais eficientes testadas.
2.  **Hybrid Radix-4 Booth Approximation:**
    - **Descrição:** Utiliza uma abordagem híbrida na codificação de Booth. Para os produtos parciais menos significativos (iterações $i < 4$), os casos que exigiriam `2A` ou `-2A` são aproximados para `1A` ou `-1A`. Para as iterações superiores ($i \ge 4$), a codificação é mantida exata.
    - **Relação com Resultado:** Esta técnica reduz o erro médio em comparação com a aproximação total, concentrando a imprecisão apenas nos bits de menor peso, similar à filosofia do PPP.
3.  **Approximate Compressor 4:2:**
    - **Descrição:** Altera a lógica interna do compressor. Elimina-se a dependência do cin e cout (forçando cout = 0), quebrando a cadeia de carry. Além disso, substitui portas XOR complexas por lógica AND/OR simplificada.
    - **Relação com Resultado:** O erro é **extremamente alto** (NMED ~0.25). Ao quebrar a cadeia de carry em múltiplos níveis da árvore de redução, o resultado final diverge massivamente do valor real.

---

## 3. Análise de Potência vs. Erro

Com base nos relatórios de potência (_power.rpt, linha 63) para a distribuição **Uniforme (32 bits)**, temos os seguintes valores aproximados de **Total On-Chip Power (W)**:

| Multiplicador | Erro (NMED) | Potência Total (W) | Vale a pena? |
| :--- | :--- | :--- | :--- |
| **Exact Simple (*)** | 0.0 | 0.122 | **Referência** |
| **Exact Structural** | 0.0 | 0.142 | Não (em FPGA) |
| **PPP Approx Radix-4** | 10^-10 | 0.144 | **Sim**, para economia de área (se comparado ao estrutural) |
| **Approx Radix-4 Booth** | ~0.04 | 0.147 | Talvez, em arquiteturas específicas |
| **Approx Modified Radix Compressor** | ~0.25 | 0.170 | **Não** |

### Conclusão Estrutural
Os multiplicadores baseados em **Compressores Aproximados** e **Modified Radix** apresentaram os piores resultados. Além de um erro catastrófico (devido à quebra da cadeia de carry), eles consumiram **mais potência** que o multiplicador exato simples. Isso ocorre porque o multiplicador exato (*) é mapeado em DSPs altamente otimizados na FPGA, enquanto as versões estruturais/aproximadas são mapeadas em LUTs (Look-Up Tables), que são menos eficientes para aritmética pesada.

O **PPP (Partial Product Perforation)** se destacou como a melhor abordagem de aproximação, mantendo o erro em níveis insignificantes para a maioria das aplicações de processamento de sinal, com um custo de potência estável.
