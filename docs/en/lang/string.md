# String

A string of characters (`string`) is a sequence made of UTF-8 code points.

String are surrounded by double quotation marks `""`.
```grimoire
var x: string = "Hello !";
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

## Caractères

A single character of type `char` is surrounded by single quotation marks `''`.
```grimoire
var x: char = 'a';
```

## Unicode

Every single valid unicode character is also a valid Grimoire character.
```grimoire
'🐶'
```

We can also express a unicode character with `\u{}` containing its specific code.
For instance with the character U+1F436 corresponding to 🐶:
```grimoire
'\u{1F436}'
```

## Escape sequence

Grimoire supports some escape sequence:

|Sequence|Result|
|-|-|
|\\'|Single quotation mark|
|\\"|Double quotation mark|
|\\?|Question mark|
|\\\\ |Backslash|
|\\0|Nul character|
|\\a|Alert|
|\\b|Backspace|
|\\f|New page|
|\\n|New line|
|\\r|Carriage return|
|\\t|Horizontal tab|
|\\v|Vertical tab|

Escaping a `"` prevent the closing of the string sequence.
```grimoire
"This character \" is escapped"
```
Or escaping `'` in case of a single character.
```grimoire
'\''
```

## Interpolation

We can insert an expression inside of a string by interpolation with `#{}` containing the expression.

The expression must be convertible to `string`.
```grimoire
"Hello, #{name}. 5 + 3 equals #{5 + 3}"
```