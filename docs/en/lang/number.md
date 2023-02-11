# Number

There are 2 types of number in Grimoire: integers `int` and floating point values `float`.

## Integer

Integral numbers represent the set of all positive natural number and their negative counterpart, they contain no fractionnal part.
They can be preceded with `0b` for a binary number, `0x` for a hexadecimal number or `0o` for an octal number.
```grimoire
5
-8
123
0b0110
0xfb98
0o647
```

A `_` can be inserted to make a big number more readable:
```grimoire
5_123_000
```

## Floating point number

Floating point numbers represent the set of all real number, they have a fractionnal part.
They can be written with a period `.` except at the last position, or with a postfix `f`.
```grimoire
2.3
.25
0f
-8f
9.35f
7.0f
.6f
```

A `_` can be inserted to make a big number more readable:
```grimoire
2_156.000_987f
```