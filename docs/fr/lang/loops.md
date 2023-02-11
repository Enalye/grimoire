# Boucles

`loop` permet de répéter un bloc de code plusieurs fois.
```grimoire
loop {
	print("Bonsoir !");
}
```
On peut limiter le nombre d’itération.
```grimoire
loop(10) {
	print("Je boucle 10 fois !");
}
```
On peut également spécifier un itérateur.
```grimoire
loop(i, 10)
	print(i); // Affiche les valeurs de 0 à 9

// Le typage de l’itérateur est optionnel
loop(i: int, 10)
	print(i);
```

## While/Do While

`while` s’exécute en boucle tant que la condition est validée.
```grimoire
var i = 0;

while(i < 10) {
	print(i);
	i ++;
}
```

`until` s’exécute en boucle tant que la condition est fausse.
```grimoire
var i = 0;

until(i > 10) {
	print(i);
	i ++;
}
```

`do` `while` ne vérifie la condition qu’après chaque itération.
```grimoire
var i = 11;

do {
	print(i); // Affiche 11
}
while(i < 10)
```

`do` `until` fonctionne pareil mais tant que la condition est fausse.
```grimoire
var i = 11;

do {
	print(i); // Affiche 11
}
until(i > 10)
```

## For

`for` itère sur chaque élément d’une liste ou d’un itérateur.
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
Pour itérer sur un objet autre qu’une liste, `for` a besoin d’appeler une fonction `func<I, T> next(I) (T?)` où `I` est l’objet iterateur, et `T` la valeur à itérer.
```grimoire
for(i, "Anticonstitutionnellement".each) {
	i.print;
}
```

# Yield

Toutes les boucles `loop`, `for`, `while`, `until`, … peuvent être annoté avec `yield`.
Les boucles s’assurent ainsi de `yield` après chaque itération.
```grimoire
loop yield(i, 10) {
    i.print;
}
```