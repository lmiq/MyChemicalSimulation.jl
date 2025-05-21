### O que você vê na tela?

A tela do programa tem algumas partes importantes:

0.  **Painel de Controle (Esquerda):** Aqui você ajusta as condições da sua simulação.
    * **Temperatura (K):** Define o quão "quente" ou "frio" está o sistema. Uma temperatura maior geralmente significa que as moléculas se movem mais rápido. O valor padrão é 297.15 K (aproximadamente 25°C).
    * **ka e kd (mol⁻¹ s⁻¹):** São as **constantes de velocidade** da reação.
        * `ka`: Controla a velocidade da reação direta (A + B → C + D).
        * `kd`: Controla a velocidade da reação inversa (C + D → A + B). No exemplo da imagem, ambas estão configuradas para `-1.02 mol⁻¹ s⁻¹`.
    * **Azul, Vermelho, Verde, Laranja (mol):** Aqui você define a **quantidade inicial** de cada tipo de molécula.
        * **Azul (A)** e **Vermelho (B)** são os seus reagentes.
        * **Verde (C)** e **Laranja (D)** são os seus produtos.
        Na imagem, começamos com 499 "mol" (uma unidade de quantidade) de Azul e 500 "mol" de Vermelho, e 0 dos produtos.
    * **Tempo (min):** Define por quanto tempo a simulação vai rodar. Na imagem, está configurado para 0.0 minuto.
    * **Botões de Ação:**
        * **Restart:** Reinicia a simulação com os parâmetros atuais.
        * **Run:** Começa ou continua a simulação.
        * **Stop:** Pausa a simulação.
    * **Gráfico de Energia (E / kcal mol⁻¹):** Mostra o perfil de energia da reação. A "barreira" no meio (Eₐ) é a energia de ativação – a energia mínima que as moléculas A e B precisam ter para reagir.

1.  **Caixa de Simulação (Centro):** É o "palco" principal! Aqui você vê as bolinhas coloridas (as moléculas) se movendo, colidindo e reagindo.
    * Bolinhas azuis são moléculas A.
    * Bolinhas vermelhas são moléculas B.
    * Bolinhas verdes são moléculas C.
    * Bolinhas amarelas (representando as laranjas) são moléculas D.
    * A informação "Volume = -1.018 L" indica o tamanho do espaço onde as moléculas estão.

2.  **Gráficos de Resultados (Direita):** Mostram o que está acontecendo na simulação.
    * **Histograma - Nk:** Mostra a **quantidade de cada tipo de molécula** (-1=Azul, 1=Vermelho, 2=Verde, 3=Laranja) em um determinado momento. O `Q = 0.701` e as porcentagens (`αk`) dão informações sobre o equilíbrio da reação.
    * **Número de Moléculas - N:** Mostra como a **quantidade de cada tipo de molécula muda ao longo do tempo**. Você verá as curvas dos reagentes (azul e vermelho) diminuindo e as dos produtos (amarelo/laranja e verde) aumentando à medida que a reação acontece.


### Como usar o programa? Passo a Passo! 🚶‍♀️🚶‍♂️

0.  **Defina as Condições Iniciais (Painel da Esquerda):**
    * **Temperatura:** Quer ver como a temperatura afeta a reação? Experimente valores diferentes!
    * **Constantes de Velocidade (ka, kd):**
        * Se `ka` for muito maior que `kd`, a reação A + B → C + D será favorecida.
        * Se `kd` for maior, a reação inversa C + D → A + B será mais rápida.
        * Se `ka = kd`, a reação pode atingir um equilíbrio onde as velocidades das duas direções se igualam.
    * **Quantidade de Moléculas:** Decida com quantas moléculas de cada tipo você quer começar. Por exemplo, para simular A + B → C + D, você pode colocar uma quantidade de Azul (A) e Vermelho (B) e zerar o Verde (C) e Laranja (D).

1.  **Controle o Tempo:** Defina por quanto tempo você quer que a simulação rode.

2.  **Comece a Simulação:**
    * Clique em **"Run"**. Você verá as moléculas se movendo e reagindo na caixa central.
    * Observe os gráficos da direita mudando em tempo real!

3.  **Analise os Resultados:**
    * **Na Caixa de Simulação:** Veja as colisões. Quando uma molécula azul colide com uma vermelha com energia suficiente, elas podem se transformar em verde e laranja!
    * **Nos Gráficos:**
        * O histograma te dá uma "foto" da quantidade de cada molécula.
        * O gráfico "Número de Moléculas vs. Tempo" te mostra a história da reação. Os reagentes diminuem? Os produtos aumentam? A reação atinge um ponto onde as quantidades não mudam mais (equilíbrio)?

4.  **Experimente!**
    * O que acontece se você aumentar a temperatura? As reações ficam mais rápidas ou mais lentas?
    * O que acontece se você mudar as concentrações iniciais?
    * O que acontece se `ka` for muito pequeno? E se `kd` for zero?
    * Clique em **"Stop"** para pausar e analisar um momento específico.
    * Clique em **"Restart"** para rodar a simulação novamente com os mesmos parâmetros ou com novos parâmetros que você definir.

