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

Each case contains a potentially blocking operation, the first non-blocking operation case is run.
The default case is optional, but without one, the select statement will be a blocking operation, otherwise the default case will execute when others are blocked.

```grimoire
select
case(myValue = <- myChannel) { // Receive operation
	print("Received " ~ myValue);
}
case(myOtherChannel <- "Hello") { // Send operation
	print("Sent Hello");
}
default {
	// Run if no one else can run.
	// If it's not present, select will blocking until one of the case is non-blocking.
	print("Did nothing");
}
```

## Loops

A loop is a structure that can be executed several time, there are two type of loops.

### Infinite loops

Infinite loops are infinite:
```grimoire
loop {
	print("Hello !");
}
```
This script will prompt *"Hello !"* infinitely until the process is killed, be cautious with it.
You may want to add either a `yield` to interrupt the loop each time or add an exit condition.

### Finite loops

Finite loops, on the other hand, have a finite number of time they will run.
Contrary to the infinite one, they take an int as a parameter, which indicate the number of loops:
```grimoire
loop(10) {
	// "I loop 10 times !" will only be printed times.
	print("I loop 10 times !");
}
```

You can also specify an iterator, which must be of type `int`.
```grimoire
loop(i, 10)
	print(i); // Prints from 0 to 9

// Same as above, but we declare i.
loop(int i, 10)
	print(i);

// Also valid.
loop(let i, 10)
	print(i);
```

## While/Do While

`while` and `do while` are, akin to loops, statements that can execute their code several time.
The difference is, they do not have a finite number of loop, instead, they have a condition (like `if` statements).
```grimoire
int i = 0;
while(i < 10) {
	print(i); // Here, the output is 0, 1, 2, 3, 4, 5, 6, 7, 8 and 9.
	i ++;
}
```
`do while` is the same as `while` but the condition is checked after having run the code one time.
```grimoire
int i = 11;
do { //This is garanteed to run at least once, even if the condition is not met.
	print(i); //Will print "11"
}
while(i < 10)
```

## For

`for` loops are yet another kind of loop that will automatically iterate on an array of values.
For instance:
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
Here, the for statement will take each value of the array, then assign them to the variable "i" specified.

The variable can be already declared, or declared inside the for statement like this:

```grimoire
int i;
for(i, [1, 2]) {}
```
Or,
```grimoire
for(int i, [1, 2]) {}
```
If no type is specified, or declared as let, the variable will be automatically declared as `var`.

The variable type must be convertible from the array's values, or it will raise a runtime error.

### Iterators

`for` can also iterate on special object or foreign called iterators.
In grimoire, an iterator is defined by the fact that a function that satisfies this signature exists:
> `function next(Iterator) (bool, VALUE)`

A function `next` must exists that takes the iterator and returns a `bool` and the current value.
The `bool` must be false when the iterator has finished iterating, true otherwise.

```grimoire
// The each() function takes the string and return
// an IterString object that iterate over the string
for(i, "Hello World":each) {
	i:print;
}
```