# Chaînes de caractère

Les chaînes de caractère sont entouré de guillemets `""`.
```grimoire
"Bonjour !"
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

## Caractères d’échappement
Grimoire supporte un certain nombre de caractères d’échappement:

|Séquence|Résultat|
|-|-|
|\n|Retour à la ligne|
|\\\\ |\\ |
|\\"|"|

Échapper un `"` permet d’éviter de cloturer la chaîne de caractères.
```grimoire
"Ce caractère \" est échappé"
```