# Chaînes de caractère

String are series of characters surrounded by quotation marks `""`.
```grimoire
"Hello !"
```

They can extend over several lines.
```grimoire
"Hello,
everyone."
```

They accept any valid UTF-8 character.
```grimoire
"Saluton al ĉiuj, 皆さん"
```

## Escape sequence
Grimoire supports some escape sequence:

|Sequence|Result|
|-|-|
|\n|End of line|
|\\\\ |\\ |
|\\"|"|

Escaping a `"` prevent the closing of the string sequence.
```grimoire
"This character \" is escapped"
```