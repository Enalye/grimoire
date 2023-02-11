# Listes

Les listes sont des collections de valeurs.
Tous les éléments d’une même liste doivent être du même type.
```grimoire
[1, 2, 3];
```

Une liste est du type `list<T>` où `T` est le type des valeurs contenues dans la liste.
```grimoire
var x: list<int> = [1, 2, 3];
```

Le compilateur ne peut pas toujours déterminer le type de la liste, comme dans le cas d’une liste vide, dans ce cas, on explicite le type.
```grimoire
var x = list<int>[];
```

Ajouter à une liste se fait avec l’opérateur `~`.
```grimoire
var x = [1, 2, 3];
x ~= 5; // x -> [1, 2, 3, 5]
```

On peut préciser la taille initiale d’une liste.
```grimoire
var x = list<int, 5>;          // x -> [0, 0, 0, 0, 0]
var y = list<int, 4>[7, 8, 9]; // y -> [7, 8, 9, 0]
```
> Le type doit avoir une valeur par défaut.

L’accès à une élément d’une liste se fait à partir de 0.
```grimoire
var x = [7, 8, 9];
x[0] = 12; // x -> [12, 8, 9]

var y = [[1, 2, 3], [11, 12, 13], [21, 22, 23]];
y[1, 2]; // -> 13
```

Un index négatif compte à partir de la fin de la liste.
```grimoire
var x = [7, 8, 9];
x[-1]; // -> 9
```