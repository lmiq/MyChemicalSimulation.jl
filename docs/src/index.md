# MyChemicalSimulation

Este programa é um laboratório virtual onde você pode ver como as reações químicas acontecem molécula por molécula. Ele simula uma reação do tipo **A + B → C + D**, onde duas moléculas diferentes (A e B) se encontram, reagem e formam duas novas moléculas (C e D).

```@raw html
<center>
<img src="simulate.png" width=50%>
</center>
```

## Conceitos Importantes 

* **Reação Bimolecular (A + B → C + D):** Significa que duas moléculas (A e B) precisam colidir para que a reação aconteça e formem duas novas moléculas (C e D).
* **Colisões:** As moléculas estão sempre se movendo. Para reagir, elas precisam colidir uma com a outra.
* **Energia de Ativação (Eₐ):** Não basta só colidir! As moléculas precisam colidir com uma energia mínima para que a reação ocorra. Pense nisso como uma pequena montanha que elas precisam escalar para chegar ao outro lado (os produtos). O gráfico de energia no canto inferior esquerdo mostra essa "montanha".
* **Temperatura:** A temperatura é uma medida da energia de movimento das moléculas. Quanto maior a temperatura, mais rápido elas se movem, mais frequentes e energéticas são as colisões, e maior a chance de superar a energia de ativação.
* **Constante de Velocidade (k):** É um número que diz o quão rápida é uma reação. Um `k` grande significa uma reação rápida, e um `k` pequeno significa uma reação lenta. Ela depende da temperatura e da energia de ativação.
* **Equilíbrio Químico:** Às vezes, a reação direta (A + B → C + D) e a reação inversa (C + D → A + B) acontecem ao mesmo tempo. Quando a velocidade das duas se iguala, as quantidades de reagentes e produtos param de mudar. Dizemos que a reação atingiu o **equilíbrio**.



## Instalar

Isto só precisa ser feito uma vez. 

Instale a linguagem Julia de [https://julialang.org/](https://julialang.org/)

Entre no prompt e copie e cole os comandos (isto pode demorar vários minutos,
porque vai instalar todas as dependências):

```julia-repl
julia> import Pkg; Pkg.add(url="https://github.com/lmiq/MyChemicalSimulation.jl")

julia> using MyChemicalSimulation
```

Uma vez terminado todo o processo, você verá outra vez o prompt `julia>`. 

## Atualizar

Copie este comando:
```julia-repl
julia> import Pkg; Pkg.update("MyChemicalSimulation")

```

## Como iniciar o uso

Abra o prompt de Julia e copie e cole:

```julia-repl
julia> using MyChemicalSimulation 

julia> simulate()
```

Isto deve abrir a janela interativa mostrada acima.