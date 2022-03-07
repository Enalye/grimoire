# Structures de contrôle

## Conditions

`if` est un mot-clé permettant d’exécuter une portion de code seulement si sa condition est vérifiée, `unless` fait le contraire.
Ils se combinent en `else if` et `else unless` pour ajouter d’autres conditions, seulement si les précédentes conditions ne se sont pas vérifiées.
Enfin, on peut ajouter un `else` optionnel exécuté *seulement* si les autres ne le sont pas.

Exemple:
```grimoire
event onLoad() {
	if(5 < 2) {
		//Ce code ne s’exécutera pas car 5 n’est jamais inférieur à 2.
		print("5 vaut moins que 2 !");
	}

	unless(5 < 2) {
		//Celui ci oui, car unless fait l’opposé de if.
		//Ça revient à faire if(not 5 < 2) {}
		print("5 ne vaut pas moins que 2...");
	}
}
```
Un autre:
```grimoire
event onLoad() {
	let i = 5;
	if(i > 10) {
		print("i vaut plus que 10");
	}
	else if(i >= 5) {
		print("i vaut 5 ou plus mais moins que 10");
	}
	else unless(i < 2) {
		print("i vaut 2 ou plus, mais moins que 5");
	}
	else { //else doit toujours se trouver en fin d’une série (if/unless)/else (if/unless)/else, mais il est optionnel.
		print("i vaut 2 ou moins");
	}
}
```

## Le commutateur Switch

`switch` permet d’exécuter du code de manière conditionnelle à l’instar de `if`, mais de manière plus compacte.

```grimoire
let i = "Salut";
switch(i)
default { // Cas par défaut si les autres sont pas valides.
	print("Il a pas dit bonjour");
}
case("Wesh") {
	print("Il a dit wesh mais c’est pas pareil");
}
case("Salut") {
	print("Il a dit bonjour");
}
```

Contrairement au `if`, les cas peuvent se répartir dans n’importe quel ordre et vérifiera l’égalité entre la valeur du switch et chaque cas.

Un `default` est un cas optionnel qui se comporte un peu comme le `else` ci-dessus.
On ne peut avoir qu’un seul cas par défaut par switch.

## Le commutateur Select

Syntaxiquement, un select ressemble à un switch, mais diffère du fait qu’il ne compare pas des valeurs, il vérifie chaque cas jusqu’à ce qu’un des cas puisse s’exécuter sans bloquer.

```grimoire
select
case( /* opération potentiellement bloquante sur un canal */ ) {

}
default {
	/* s’exécute si l’opération du haut est bloquée */
}
```

Chaque cas contient une opération potentiellement bloquante, la première opération qui ne bloque pas est exécuté.
La cas par défaut est optionnel, mais sans elle, select devient une opération bloquante. Sinon, le cas par défaut est exécuté quand les autres sont bloqués.
```grimoire
select
case(myValue = <- myChannel) { // Réception
	print("Reçu " ~ myValue);
}
case(myOtherChannel <- "Salut") { // Envoi
	print("Envoyé Salut");
}
default {
	// Exécuté si aucun autre cas ne l’est
    // Si absent, select bloquera jusqu’à ce qu’un des cas ne bloque plus.
	print("Il se passe rien");
}
```

## Les boucles

Une boucle est un bout de code qui est exécuté plusieurs fois, il y a plusieurs types de boucles.

### Les boucles infinies

Les boucles infinies n’ont pas de condition d’arrêt:
```grimoire
loop {
	print("Bonsoir !");
}
```
Ce script affichera *"Bonsoir !"* indéfiniement jusqu’à ce que le processus soit tué, soyez vigilant avec ça.
On préférera l’ajout d’un `yield` pour interrompre la boucle à chaque itération, ou ajouter une condition de sortie.

### Les boucles finies

Les boucles finies ont, pour leur part, un nombre fini d’itérations.
Contrairement aux boucles infinies, elles prennent un entier en paramètre, qui indique le nombre de fois qu’elles seront exécutées:
```grimoire
loop(10) {
	// "Je boucle 10 fois !" sera affiché seulement 10 fois
	print("Je boucle 10 fois !");
}
```

On peut également spécifier un itérateur qui sera de type entier.
```grimoire
loop(i, 10)
	print(i); // Affiche les valeurs de 0 à 9

// Pareil qu’au dessus, mais on déclare i explicitement
loop(int i, 10)
	print(i);

// Aussi valide
loop(let i, 10)
	print(i);
```

## Les boucles While/Do While

`while` et `do while` sont, comme les boucles, des structures qui exécutent leur code plusieurs fois.
La différence est qu’elles n’ont pas de nombre déterminé d’itérations.
Elles ont, en revanche, une condition (comme les `if`).
```grimoire
int i = 0;
while(i < 10) {
	print(i); // Ici, ça affichera 0, 1, 2, 3, 4, 5, 6, 7, 8 et 9.
	i ++;
}
```
`do while` est la même que `while` mais la condition n’est vérifié qu’après avoir exécuté le code une fois.
```grimoire
int i = 11;
do { //Garantit de s’exécuter au moins une fois, même si la condition n’est pas vérifiée.
	print(i); //Affichera "11"
}
while(i < 10)
```

## La boucle For

Les boucles `for` sont encore un autre type de boucle qui itérera automatiquement sur une liste d’élément ou sur un itérateur.
Par exemple:
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
Ici, le `for` prend chaque valeur de la liste et l’assigne à la variable `i` spécifiée.

La variable peut être déjà déclarée, ou déclarée à l’intérieur du `for` comme ceci:
```grimoire
int i;
for(i, [1, 2]) {}
```
Or,
```grimoire
for(int i, [1, 2]) {}
```
Si aucun type n’est spécifié, ou déclaré avec `let`, la variable prendra automatiquement la bonne valeur.

La variable doit pouvoir se convertir en la valeur de la liste ou de l’itérateur, sinon une erreur surviendra.

### Les itérateurs

`for` peut aussi itérer sur des objets ou type étrangers appelés itérateurs.
En grimoire, un itérateur est défini comme tout objet (ou type étranger) où il existe une fonction particulière `next` telle que:
> `function next(Iterator) (bool, VALUE)`

Cette fonction `next` prend l’iterateur en paramètre et retourne un `bool` et la valeur actuelle.
Le `bool` vaut `false` quand l’intérateur a fini d’itérer, `true` dans le cas contraire.

```grimoire
// La fonction each() prend une chaîne de caratères et retourne
// un itérateur qui parcourt chaque caractère.
for(i, "Anticonstitutionnellement":each) {
	i:print;
}
```