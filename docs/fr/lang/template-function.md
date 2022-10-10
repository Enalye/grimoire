# Fonctions génériques

Les fonctions et tâches globales peuvent être défini avec des types génériques:
```grimoire
function<T> additionner(T a, T b)(T) {
    return a + b;
}
```
Ici `T` est un type générique qui sera remplacer par le bon type au moment de la génération de la fonction.

On peut également avoir plusieurs variables génériques:
```grimoire
public function<A, B> additionner(A a, B b)(B) {
    return a as B + b;
}
```

Les opérateurs peuvent aussi être génériques:
```grimoire
function<T> operator<=>(T a, T b)(int) {
	if(a < b)
		return -1;
	else if(a > b)
		return 1;
    return 0;
}
```

## Contraintes

Les contraintes sont des restrictions additionnelles imposées sur un type particulier.
Pour restraindre un type générique, on doit déclarer une clause `where`:
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