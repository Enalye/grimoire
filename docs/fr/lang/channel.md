# Canaux

Les canaux permettent l’échange synchronisé de valeurs entre plusieurs tâches.
```grimoire
var canal: channel<int>;
```

Par défaut, un canal a une capacité de 1.
Pour changer sa capacité, on explicite lors de l’initialisation.
```grimoire
var canal = channel<int, 5>; // Capacité de 5
```

L’opérateur `<-` permet de passer ou de récupérer une valeur d’un canal.
```grimoire
var c = channel<int>;
c <- 1; //On envoie la valeur 1 dans le canal
var value = <-c; //On récupère la valeur depuis le canal
```

Si aucune valeur n’est disponible dans le canal, la tâche réceptrice est bloquée.
Si le canal est plein, la tâche expéditrice est bloquée.
```grimoire
task foo(canal: channel<string>) {
	print(<- canal); //Bloqué tant que canal est vide
}

event main() {
	var c: channel<string>;
	foo(c);
	c <- "CC le monde !";
}
```