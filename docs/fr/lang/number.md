# Nombre

Grimoire possède 2 types de nombres: les entiers `int` et les flottants `float`.

## Entier

Les nombre entiers concernent l’ensemble des nombres relatifs, ils ne possèdent pas de partie fractionnaire.
Ils peuvent être précédé de `0b` pour un nombre binaire, de `0x` pour un nombre hexadécimal ou de `0o` pour un nombre octal.
```grimoire
5
-8
123
0b0110
0xfb98
0o647
```

Un `_` peut être ajouté pour rendre un grand nombre plus lisible:
```grimoire
5_123_000
```

## Nombre à virgule flottante

Les nombres à virgule flottante désignent l’ensemble des nombres réels, ils disposent d’une partie fractionnaire.
On les note soit à l’aide d’un point `.` sauf en dernière position, soit avec un `f` postfixé.
```grimoire
2.3
.25
0f
-8f
9.35f
7.0f
.6f
```

Un `_` peut être ajouté pour rendre un grand nombre plus lisible:
```grimoire
2_156.000_987f
```