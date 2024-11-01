# Fonctions

Le mot-clé `func` permet de définir une fonction globale.
```grimoire
export func additionner(a: int, b: int) (int) {
    return a + b;
}

func comparerAvec0(n: int) {
  if(n == 0) {
    print("n est égal à 0");
    return;
  }
  print("n est différent de 0");
}
```

Une fonction peut avoir plusieurs types de retour.
```grimoire
func donneDesValeurs() (int, string, bool) {
	return 5, "Coucou", false;
}
```

## Fonctions anonymes
```grimoire
event main() {
	var a = 7;
	var multiplierPar2 = func(c: int) (int) {
		return c * 2;
	};
	7.multiplierPar2.print; // Affiche 14
}
```

L’opérateur `&` permet de récupérer une référence à une fonction globale.
```grimoire
func auCarré(i: int) (int) {
	return i * i;
};

event main() {
	var f1 = &aucarré; //Error, & has no way to know the type at during compilation (aucarré could be overloaded).
	var f2 = &<func(int) (int)> aucarré; //Valid, an explicit type prevent this problem.
	f2 = &aucarré; //Now valid, because it's now typed by the previous assignment.

	var f3: func(int) (int) = &aucarré; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &aucarré; //Valid, since f3 is already declared with a type.
}
```

Le mot-clé `function` permet de récupérer une référence à la fonction actuelle.
```grimoire
// Fibonacci
func(n: int) (int) {
    if(n < 2) return n;
    return function(n - 1) + function(n - 2);
}(10).print;
```

## Généricité

Les fonctions et tâches globales peuvent être défini avec des types génériques.
```grimoire
func<T> additionner(a: T, b: T)(T) {
    return a + b;
}

export func<A, B> additionner(a: A, b: B)(B) {
    return a as<B> + b;
}

func<T> operator"<=>"(a: T, b: T)(int) {
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
func<T> additionner(ary: list<T>, val: T)
where T: Numeric {
    loop(i, ary.size) {
        ary[i] += val;
    }
}

func<T, U> saucisse(first: T, second: U)
where T: Class,
      U: Class,
      T: Extends<U> {
}
```