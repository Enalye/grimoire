# Canaux

Les canaux sont un concept qui permet la communication synchronisée entre différentes tâches.
Grosso merdo c’est la même tambouille qu’en Go.

Un canal se crée comme ceci:
```grimoire
channel(int) c = channel(int, 5);
```
Ici, on crée un canal qui peut accueillir jusqu’à 5 entiers.
Cette capacité (5), est optionnelle, par défaut elle est de 1.

Pour passer ou récupérer une valeur d’un canal, on utilise l’opérateur `<-`:
```grimoire
let c = channel(int);
c <- 1; //On envoie la valeur 1 dans le canal
int value = <-c; //On récupère la valeur depuis le canal
```

En revanche, l’envoie ou la réception est bloquant, on ne peut le faire sur la même tâche.
```grimoire
task foo(channel(string) c) {
	print(<-c);
}
event onLoad() {
	let c = channel(string);
	foo(c);
	c <- "CC le monde !";
}
```
Là, foo sera bloqué jusqu’à ce que quelque chose soit écrit dans le canal, où il l’affichera.