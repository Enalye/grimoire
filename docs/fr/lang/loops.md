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

// Pareil qu’au dessus, mais on déclare i explicitement
loop(int i, 10)
	print(i);

// Aussi valide
loop(let i, 10)
	print(i);
```

## While/Do While

`while` vérifie à chaque itération si la condition est vraie.
```grimoire
int i = 0;

while(i < 10) {
	print(i);
	i ++;
}
```
`do` `while` ne vérifie la condition qu’après chaque itération.
```grimoire
int i = 11;

do {
	print(i); // -> "11"
}
while(i < 10)
```

## For

`for` itère sur chaque élément d’une liste ou d’un itérateur.
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
Pour itérer sur un objet autre qu’une liste, `for` a besoin d’appeler une fonction `function<I, T> next(I) (T?)` où `I` est l’objet, et `T` la valeur à itérer.
```grimoire
for(i, "Anticonstitutionnellement":each) {
	i:print;
}
```