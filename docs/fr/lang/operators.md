# Operators

Much like custom convertions, you can define your own operators by naming it accordingly.
You also have to respect the number of inputs the operator uses (1 or 2).

```grimoire
event onLoad() {
    print(3.5 + 2);
}

function operator+(real a, int b) (real) {
    return a + b as real;
}
```

Overridable operators are:

| Operator | Symbol | Note |
| --- | --- | --- |
| `+` | Plus | Prefix unary operator |
| `-` | Minus | Prefix unary operator |
| `+` | Add | Binary operator |
| `-` | Substract | Binary operator |
| `*` | Multiply | Binary operator |
| `/` | Divide | Binary operator |
| `~` | Concatenate | Binary operator |
| `%` | Remainder | Binary operator |
| `**` | Power | Binary operator |
| `==` | Equal | Binary operator |
| `===` | Double Equal | Binary operator |
| `<=>` | Three Way Comparison | Binary operator |
| `!=` | Not Equal | Binary operator |
| `>=` | Greater or Equal | Binary operator |
| `>` | Greater | Binary operator |
| `<=` | Lesser or Equal | Binary operator |
| `<` | Lesser | Binary operator |
| `<<` | Left Shift | Binary operator |
| `>>` | Right Shift | Binary operator |
| `->` | Interval | Binary operator |
| `=>` | Arrow | Binary operator |
| `<-` | Receive | Prefix unary operator |
| `<-` | Send | Binary operator |
| `&`, `bit_and` | Bitwise And | Binary operator |
| `|`, `bit_or` | Bitwise Or | Binary operator |
| `^`, `bit_xor` | Bitwise Xor | Binary operator |
| `~`, `bit_not` | Bitwise Not | Prefix unary operator |
| `&&`, `and` | Logical And | Binary operator |
| `||`, `or` | Logical Or | Binary operator |
| `!`, `not` | Logical Not | Prefix unary operator |