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

## 2. Multiplicadores Aproximados: Descrição Técnica

Nesta seção, detalhamos a lógica de hardware e as simplificações matemáticas aplicadas em cada arquitetura aproximada. Essas descrições servem como base para a fundamentação teórica do projeto.

### A. Partial Product Perforation (PPP)
*   **Técnica:** Perfuração de Produtos Parciais.
*   **Lógica de Hardware:** Em um multiplicador Radix-4, são gerados $N/2$ produtos parciais. Na arquitetura PPP, os produtos parciais de menor peso (LSBs) são omitidos (forçados a zero).
*   **Implementação:** Neste projeto, os **2 primeiros produtos parciais** (correspondentes às iterações $i=0$ e $i=1$ do algoritmo de Booth) são ignorados.
*   **Impacto:** Como os produtos parciais de menor peso contribuem menos para a magnitude do resultado final, o erro introduzido é desprezível (erro relativo quase nulo), mas a área e a árvore de redução são simplificadas.

### B. Hybrid Radix-4 Booth Approximation
*   **Técnica:** Codificação de Booth Aproximada com Segmentação.
*   **Lógica de Hardware:** O algoritmo Radix-4Booth exato exige a geração do termo $2A$ (um shift à esquerda do multiplicando). Isso requer hardware adicional ou roteamento extra.
*   **Aproximação:** Para reduzir a complexidade, as operações de codificação para $2A$ e $-2A$ são simplificadas para $1A$ e $-1A$, respectivamente.
*   **Abordagem Híbrida:** Para equilibrar precisão e economia, essa simplificação é aplicada apenas aos **primeiros 4 produtos parciais** ($i < 4$). Do quinto produto parcial em diante, a codificação é mantida exata ($2A$ é gerado corretamente).
*   **Impacto:** Reduz a lógica de geração de produtos parciais nos bits menos significativos, onde o erro tem menor impacto no resultado total.

### C. Approximate Compressor 4:2
*   **Técnica:** Redução de Árvore com Lógica Incompleta.
*   **Lógica de Hardware:** Um compressor 4:2 exato reduz 4 bits de entrada (mais um `cin`) para 2 bits de saída (`sum` e `carry`), mantendo a integridade aritmética.
*   **Aproximação:** A lógica interna é simplificada para reduzir o caminho crítico e o número de portas XOR.
    - O `sum` é mantido como o XOR das 4 entradas (exato para $cin=0$).
    - O `carry` é simplificado para uma lógica `OR` entre as combinações das entradas, ignorando carrys de ordem superior.
    - O sinal `cout` é forçado a `0`, eliminando a propagação horizontal de carry.
*   **Impacto:** Economiza área e potência em aplicações ASIC, mas introduz um erro significativo em cada nível da árvore de redução.

### D. Approximate Modified Radix-4 (Híbrido)
*   **Técnica:** Combinação de *Gating* de Potência e Codificação Aproximada.
*   **Lógica de Hardware:** Esta arquitetura combina duas técnicas:
    1.  **Modified Radix (Gating):** Uma lógica de detecção de faixa (*Range Detection*) analisa os bits significativos do multiplicador ($b$). Se o multiplicador for pequeno, as unidades de hardware que processariam os produtos parciais superiores são desligadas (gated), forçando-os a zero.
    2.  **Booth Aproximado:** Aplica a simplificação de $2A \to 1A$ nos produtos parciais inferiores.
*   **Impacto:** Visa maximizar a economia de potência dinâmica em cenários onde os dados de entrada possuem magnitudes variadas, ao custo de um erro estrutural fixo.

### E. Approximate Radix + Compressor
*   **Técnica:** Aproximação em Duas Camadas.
*   **Lógica de Hardware:** Utiliza a Codificação de Booth Híbrida (item B) para gerar os produtos parciais e, em seguida, utiliza a Árvore de Compressores Aproximados (item C) para realizar a soma desses produtos.
*   **Impacto:** É a arquitetura mais agressiva em termos de simplificação, acumulando erros tanto na fase de geração quanto na fase de redução de produtos parciais.

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
