# Nombres
Grimoire possède 2 types de nombres: les entiers `int` et les réels `real`.

## Entiers

Un nombre entier n’ont pas de virgule flottante.
Ils peuvent être précédé de `0b` pour un nombre binaire, de `0x` pour un nombre héxadécimal ou de `0o` pour un nombre octal.
```grimoire
5
-8
123
0b0110
0xfb98
0o647
```

Un `_` peut être ajouté pour rendre un nombre plus lisible:
```grimoire
5_123_000
```

## Réels

Un nombre réel possède soit une virgule flottante, soit un `f` postfixé.
```grimoire
2.3
1.
.25
0f
-8f
9.35f
7.f
.6f
```

Un `_` peut être ajouté pour rendre un nombre plus lisible:
```grimoire
2_156.000_987f
```
