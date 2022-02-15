# Syntax

## Identifier

An identifier is a name used to identify something like a variable, a function, a type, etc.

It must not be reserved word, it can use any alphanumeric character, lower and upper cases, or underscores be it can't start with a digit.

Exemple of valid identifiers:
`_myVariable`
`MyVAR1__23`

`?` can be added to an identifier *only* if it's put at the end:
`empty?`

## Reserved words

The following are keyword used by the language, they cannot be used as identifier (variables, functions, etc):
`import`, `public`, `alias`, `event`, `class`, `enum`, `template`, `if`, `unless`, `else`, `switch`, `select`, `case`, `default`, `while`, `do`, `until`, `for`, `loop`, `return`, `self`, `die`, `exit`, `yield`, `break`, `continue`, `as`, `try`, `catch`, `throw`, `defer`, `void`, `task`, `function`, `int`, `real`, `bool`, `string`, `array`, `channel`, `new`, `let`, `true`, `false`, `null`, `not`, `and`, `or`, `bit_not`, `bit_and`, `bit_or`, `bit_xor`.



## Numbers

Numbers can either be integers or floating point values.

An integer is defined by digits from 0 to 9.
A real is similar but must either:
- Have a decimal part separated by a `.` dot : `5.678`, `.123`, `60.`
- Have a `f` at the end of the number : `1f`, `.25f`, `2.f`

You can also use underscores `_` inside the number (not in front) to make it more readable: `100_000`
The underscores won't be parsed by the compiler.