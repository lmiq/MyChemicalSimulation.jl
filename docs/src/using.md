# Como usar o programa? Passo a Passo!

## Defina as Condições Iniciais (Painel da Esquerda)

* **Temperatura:** Quer ver como a temperatura afeta a reação? Experimente valores diferentes!
* **Constantes de Velocidade (ka, kd):**
    * Se k₁ for muito maior que k₂, a reação A + B → C + D será favorecida.
    * Se k₂ for maior, a reação inversa C + D → A + B será favorecida.
* **Quantidade de Moléculas:** Decida com quantas moléculas de cada tipo você quer começar. Por exemplo, para simular A + B → C + D, você pode colocar uma quantidade de Azul (A) e Vermelho (B) e zerar o Verde (C) e Laranja (D).

Alternativamente à definição de k₁ e k₂, é possível escolher definir as energias de ativação Ea₁ e Ea₂. Energias de ativação e constantes de velocidade estão relacionadas através da [Equação de Arrhenius](https://pt.wikipedia.org/wiki/Equa%C3%A7%C3%A3o_de_Arrhenius), e podem ser interconvertidas, para cada tempertura.  

## Controle o Tempo

* Defina por quanto tempo você quer que a simulação rode.

## Comece a Simulação

* Clique em **"Run"**. Você verá as moléculas se movendo e reagindo na caixa central.
* Observe os gráficos da direita mudando em tempo real!

## Analise os Resultados

* **Na Caixa de Simulação:** Veja as colisões. Quando uma molécula azul colide com uma vermelha, elas podem se transformar em verde e laranja, com uma probabilidade k₁. No sentido inverso, quando uma molécula verde colide com uma molécula laranja, elas podem reagir com probabilidade k₂.

* **Nos Gráficos:**
    * O histograma mostra quantidade de cada molécula a todo instante do tempo.
    * O gráfico "Número de Moléculas vs. Tempo" te mostra a história da reação. Os reagentes diminuem? Os produtos aumentam? A reação atinge um ponto onde as quantidades não mudam mais (equilíbrio)?

## Experimente!

* O que acontece se você aumentar a temperatura? As reações ficam mais rápidas ou mais lentas?
* O que acontece se você mudar as concentrações iniciais?
* O que acontece se `ka` for muito pequeno? E se `kd` for zero?
* Clique em **"Stop"** para pausar e analisar um momento específico.
* Clique em **"Restart"** para rodar a simulação novamente com os mesmos parâmetros ou com novos parâmetros que você definir.



