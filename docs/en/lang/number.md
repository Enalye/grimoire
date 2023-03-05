# Number

There are 4 types of number in Grimoire: integers `int` (signed), `uint` and `byte` (both unsigned) and floating point values `float`.

> **Note**: All numbers can have a `_` inserted between digits to make a big number more readable:
```grimoire
5_123_000
```

## Integer

Integral numbers `int` represent the set of all positive natural number and their negative counterpart, they contain no fractionnal part.
They can contain a number between -2³¹ (-2 147 483 648) and 2³¹-1 (2 147 483 647).
Exceeding those values will raise an `OverflowError` error.

They can be preceded with `0b` for a binary number, `0x` for a hexadecimal number or `0o` for an octal number.
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

Contrary to signed integers, unsigned integers `uint` cannot be negative.
They can contain a number between 0 and 2³²-1 (4 294 967 295).
Exceeding those values will raise an `OverflowError` error.

They can be written with a postfix `u` or `U`.
Alternately, every literal integer greater than 2 147 483 647 is automatically unsigned.

```grimoire
5_123_000u
3_000_000_000
12U
```

## Byte

`byte` works like `uint` but on a single byte.
They can contain a number between 0 and 2⁸-1 (255).
Exceeding those values will raise an `OverflowError` error.
They can be written with a postfix `b` or `B`.

```grimoire
128b
```

## Floating point number

Floating point numbers `float` represent the set of all real number, they have a fractionnal part.
They can be written with a period `.` except at the last position, or with a postfix `f` or `F`.
```grimoire
2.3
.25
0f
-8f
9.35f
7.0f
.6f
2_156.000_987f
```