# Listes

Les listes sont des collections d’un seul type de valeur.

## Créer une liste
Le type d’une liste est `array()` avec le type de contenu à l’intérieur des parenthèses:
```grimoire
array(int) myCollection = [1, 2, 3];
```

Par défaut, une nouvelle liste partage le type de son premier élément.
Ainsi, `[1, 2, 3]` sera de type `array(int)`.

On peut expliciter en précédent la liste du type attendu: `array(int)[1, 2, 3]`

Si la liste est vide `[]`, expliciter le type devient **obligatoire** ou une erreur de compilation surviendra:  `array(string)[]` ou `array(string)`.

Pour initialiser une liste avec une taille initiale, il faut suivre le type de la liste par sa taille.
Par exemple, une liste de 5 entiers devient: `array(int, 5)` qui est équivalent à `[0, 0, 0, 0, 0]`
Autre exemple: `array(int, 5)[7, 8, 9]` vaut `[7, 8, 9, 0, 0]`.

## Indexer une liste
Pour accéder à une élément de la liste, on écrit l’index (en comptant à partir de 0) entre crochets:
```grimoire
let a = [10, 20, 30][1]; //Nouvelle liste, puis prend immédiatement l’index 1 de [10, 20, 30], ce qui fait 20

let b = [[1, 2, 3], [11, 12, 13], [21, 22, 23]]; //Nouvelle liste
let c = b[1][2]; //Ici on accède l’élément à l’index 1 -> [21, 22, 23], puis à l’index 2 -> 23
let d = b[1, 2]; //Pareil qu’au dessus avec une syntaxe plus concise
```

En accédant à un élément de la liste, on peut également altérer son contenu:
```grimoire
let a = [11, 12, 13];
a[0] = 9; //a vaut maintenant [9, 12, 13]
```

Les listes et leurs index sont passés par référence, ce qui veut dire que manipuler des listes ne crée pas de copie.
```grimoire
let a = [1, 2, [3, 4]];
let b = a[2]; //b est une référence à la 3ème valeur de a
b[0] = 9;

print(a); //Affiche [1, 2, [9, 4]]
```

On peut concaténer des valeurs dans une liste avec l’opérateur `~`:
```grimoire
let a = 1 ~ [2, 3, 4] ~ [5, 6] ~ 7; //a vaut [1, 2, 3, 4, 5, 6, 7]
```