# Canaux

Les canaux permettent l’échange synchronisé de valeurs entre plusieurs tâches.
```grimoire
channel(int) canal;
```

Par défaut, un canal a une capacité de 1.
Pour changer sa capacité, on explicite lors de l’initialisation.
```grimoire
let canal = channel(int, 5); // Capacité de 5
```

L’opérateur `<-` permet de passer ou de récupérer une valeur d’un canal.
```grimoire
let c = channel(int);
c <- 1; //On envoie la valeur 1 dans le canal
int value = <-c; //On récupère la valeur depuis le canal
```

Si aucune valeur n’est disponible dans le canal, la tâche réceptrice est bloquée.
```grimoire
task foo(channel(string) canal) {
	print(<- canal); //Bloqué tant que canal est vide
}

event main() {
	channel(string) c;
	foo(c);
	c <- "CC le monde !";
}
```