# Syntaxe

## Identifieur

Un identifieur est un nom utilisé pour différencier les variables, fonctions, types, etc.

Un identifieur ne peut pas être un mot reservé, et peut utiliser n’importe quel caractère alphanumérique, mais ne peut débuter par un chiffre.

Exemple d’identifieurs valides:
`_maVariable`
`MaVAR1__23`

`?` peut être ajouter à un identifieur *seulement* à la fin:
`empty?`

## Mots reservés

Voici la liste des mot reservé par le langage, ils ne peuvent être utilisés comme identifieur:
`import`, `public`, `alias`, `event`, `class`, `enum`, `where`, `if`, `unless`, `else`, `switch`, `select`, `case`, `default`, `while`, `do`, `until`, `for`, `loop`, `return`, `self`, `die`, `exit`, `yield`, `break`, `continue`, `as`, `try`, `catch`, `throw`, `defer`, `void`, `task`, `function`, `int`, `real`, `bool`, `string`, `array`, `channel`, `new`, `let`, `true`, `false`, `null`, `not`, `and`, `or`, `bit_not`, `bit_and`, `bit_or`, `bit_xor`.



## Nombres

Les nombres peuvent être soit des entiers, soit des nombres décimaux.

Un entier est défini avec des chiffres de 0 à 9.
Un nombre décimal, lui, doit avoir soit:
- Une partie décimal séparé par un point: `5.678`, `.123`, `60.`
- Avoir un `f` à la fin du nombre : `1f`, `.25f`, `2.f`

On peut aussi utiliser des `_` au milieu d’un nombre (pas au début) pour le rendre plus lisible: `100_000`
Ces `_` seront ignorés par le compilateur.