# Fonctions et tâches anonymes

On peut déclarer une fonction ou tâche à l’intérieur d’une autre fonction (ou tâche).
Comme ceci:

```grimoire
event onLoad() {
	let f = function() {};
	let t = task() {};
}
```

Elles peuvent également s’exécuter immédiatement:
```grimoire
event onLoad() {
	int a = 7;
	int b = function(int c) (int) {
		return c * 2;
	}(a);
	print(b); //Prints 14
}
```

Le type d’une fonction ou tâche est le même que sa déclaration sans les noms des paramètres:
```grimoire
event onLoad() {
	function(int, real) (string, int) myFunction = function(int a, real b) (string, int) { return "Hey", 2; };
}
```

On peut utiliser une fonction ou tâche globale en tant qu’anonyme en récupérant son adresse à l’aide de l’opérateur &.
L’opérateur & ne requière pas le type de la fonction, sauf quand le compilateur n’a aucun moyen de deviner le type, comme lors d’une déclaration avec let.

```grimoire
function square(int i) (int) {
	return i * i;
};

event onLoad() {
	let f1 = &square; //Error, & has no way to know the type at during compilation (square could be overloaded).
	let f2 = &(function(int) (int))square; //Valid, an explicit type prevent this problem.
	f2 = &square; //Now valid, because it's now typed by the previous assignment.

	function(int) (int) f3 = &square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &square; //Valid, since f3 is already declared with a type.
}
```

## Self

Si on souhaite référencer la fonction actuelle, mais en étant à l’intérieur d’une fonction anonyme, il nous faut alors utiliser le mot-clé `self`:

It allows you to do things like this anonymous recursive fibonacci:
```grimoire
function(int n) (int) {
    if(n < 2) return n;
    return self(n - 1) + self(n - 2);
}(10):print;
```