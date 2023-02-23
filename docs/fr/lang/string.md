# Chaîne de caractères

Une chaîne de caractères (`string`) est une séquence constitué de points de code UTF-8.

Les chaînes de caractère sont entouré de guillemets `""`.
```grimoire
var x: string = "Bonjour !";
```

Elles peuvent s’étendre sur plusieurs lignes.
```grimoire
"Bonjour,
les gens."
```

Elles acceptent n’importe quel caractère UTF-8 valide.
```grimoire
"Saluton al ĉiuj, 皆さん"
```

## Caractères

Un caractère seul de type `char` s’exprime à l’aide d’apostrophes `''`.
```grimoire
var x: char = 'a';
```

## Unicode

Tout caractère unicode valide est également un caractère valide en Grimoire.
```grimoire
'🐶'
```

On peut également exprimer un caractère unicode avec `\u{}` contenant son code spécifique.
Par exemple avec le caractère U+1F436 correspondant à 🐶:
```grimoire
'\u{1F436}'
```

## Caractères d’échappement

Grimoire supporte un certain nombre de caractères d’échappement:

|Séquence|Résultat|
|-|-|
|\\'|Apostrophe|
|\\"|Guillemet|
|\\?|Point d’interrogation|
|\\\\ |Barre oblique inversée|
|\\0|Caractère nul|
|\\a|Alerte|
|\\b|Retour arrière|
|\\f|Nouvelle page|
|\\n|Nouvelle ligne|
|\\r|Retour chariot|
|\\t|Tabulation horizontale|
|\\v|Tabulation verticale|

Échapper un `"` permet d’éviter de cloturer la chaîne de caractères.
```grimoire
"Ce caractère \" est échappé"
```
Ou pour un `'` dans le cas d’un caractère seul.
```grimoire
'\''
```

## Interpolation

On peut insérer une expression au sein d’une chaîne de caractères par interpolation avec `#{}` contenant l’expression.

L’expression doit pouvoir se convertir en `string`.
```grimoire
"Bonjour, #{name}. 5 + 3 font #{5 + 3}"
```