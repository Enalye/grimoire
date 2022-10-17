# Fonctions

Le mot-clé `function` permet de définir une fonction globale.
```grimoire
public function additionner(int a, int b) (int) {
    return a + b;
}

function comparerAvec0(int n) {
  if(n == 0) {
    print("n est égal à 0");
    return;
  }
  print("n est différent de 0");
}
```

Une fonction peut avoir plusieurs types de retour.
```grimoire
function donneDesValeurs() (int, string, bool) {
	return 5, "Coucou", false;
}
```

## Fonctions anonymes
```grimoire
event onLoad() {
	int a = 7;
	function(int) (int) multiplierPar2 = function(int c) (int) {
		return c * 2;
	};
	7:multiplierPar2:print; // Affiche 14
}
```

L’opérateur `@` permet de récupérer une référence à une fonction globale.
```grimoire
function auCarré(int i) (int) {
	return i * i;
};

event onLoad() {
	let f1 = @square; //Error, & has no way to know the type at during compilation (square could be overloaded).
	let f2 = @(function(int) (int))square; //Valid, an explicit type prevent this problem.
	f2 = @square; //Now valid, because it's now typed by the previous assignment.

	function(int) (int) f3 = @square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = @square; //Valid, since f3 is already declared with a type.
}
```

Le mot-clé `self` permet de récupérer une référence à la fonction actuelle.
```grimoire
// Fibonacci
function(int n) (int) {
    if(n < 2) return n;
    return self(n - 1) + self(n - 2);
}(10):print;
```

## Généricité

Les fonctions et tâches globales peuvent être défini avec des types génériques:
```grimoire
function<T> additionner(T a, T b)(T) {
    return a + b;
}

public function<A, B> additionner(A a, B b)(B) {
    return a as B + b;
}

function<T> operator<=>(T a, T b)(int) {
	if(a < b)
		return -1;
	else if(a > b)
		return 1;
    return 0;
}
```

## Contraintes

La clause `where` permet d’imposer des restrictions sur des types génériques.
```grimoire
function<T> additionner(list(T) ary, T val)
where T: Numeric {
    loop(i, ary:size) {
        ary[i] += val;
    }
}

function<T, U> saucisse(T first, U second)
where T: Class,
      U: Class,
      T: Extends<U> {
}
```