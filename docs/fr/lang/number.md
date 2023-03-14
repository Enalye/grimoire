# Nombre

Grimoire possède 2 types de nombres:
- Les entiers: `int`, `uint`, `byte`.
- Les flottants: `float` et `double`.

> **Note**: Tous les nombres peuvent avoir un `_` inséré entre des chiffres pour rendre un grand nombre plus lisible:
```grimoire
5_123_000
```

## Entier

Les nombre entiers `int` concernent l’ensemble des nombres relatifs, ils ne possèdent pas de partie fractionnaire.
Ils peuvent contenir un nombre entre -2³¹ (-2 147 483 648) et 2³¹-1 (2 147 483 647).
Dépasser ces valeurs déclenche une erreur `OverflowError`.

Ils peuvent être précédé de `0b` pour un nombre binaire, de `0x` pour un nombre hexadécimal ou de `0o` pour un nombre octal.
```grimoire
5
-8
123
-1_000
0b0110_1111
0xfb98
0o647
```

## Entier non-signé

À la différence des entiers signés, les entiers non-signés `uint` ne peuvent pas être négatif.
Ils peuvent contenir un nombre entre 0 et 2³²-1 (4 294 967 295).
Dépasser ces valeurs déclenche une erreur `OverflowError`.

On le note en affixant un nombre entier de `u` ou `U`.
Alternativement, tout entier littéral supérieur à 2 147 483 647 est automatiquement non-signé.

```grimoire
5_123_000u
3_000_000_000
12U
```

## Octet

`byte` fonctionne comme `uint`, mais sur 1 octet seulement.
Il peut contenir un nombre entre 0 et 2⁸-1 (255).
Dépasser ces valeurs déclenche une erreur `OverflowError`.
On le note en affixant un nombre entier de `b` ou `B`.

```grimoire
128b
```

## Nombre à virgule flottante

Les nombres à virgule flottante désignent l’ensemble des nombres réels, ils disposent d’une partie fractionnaire.
On les note soit à l’aide d’un point `.` sauf en dernière position, soit avec un suffixe (`f`, `F`, `d` ou `D`).

Un `float` est un flottant en simple précision, il nécessite obligatoirement un `f` ou un `F` postfixé pour être noté.

Un `double` est un flottant avec le double de la précision d’un `float`, on peut le noter avec un `d` ou `D` postfixé ou sans suffixe.
```grimoire
2.3             // double
.25             // double
0f              // float
-8f             // float
-8d             // double
9.35F           // float
7.0f            // float
.6f             // float
.0D             // double
2_156.000_987f  // float
```
