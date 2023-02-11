# Optionals

By default, every type must have a value in Grimoire.
To note the probable absence of a value, we use an optional type.
An optional type is written with a `?`.
```grimoire
var x: int? = 5;
```

The default value of an optional type is `null`.
```grimoire
var x: string?;
x.print; // -> null
```

Likewise, we can assign `null` to an optional type.
```grimoire
var x: float? = 5f;
x = null;
```

If the compiler is unable to infer the type of `null`, we have to write it.
```grimoire
var x = null<int>;
null<float>.print;
```

# The « ? » operator

L’opérateur `?` permet de récupérer la valeur contenue dans un optionnel.
```grimoire
var x: int? = 5;
var y: int = x?;
```

> **Note:** Si la valeur de l’optionnel est `null`, une erreur sera lancé.

# The « ?? » operator

The `??` operator fetch the value wrapped in an optional if it isn't `null`, otherwise it returns the right-hand value.
```grimoire
var x: int?;
var y: int = x ?? 3;
```

# Optional field access with « .? »

The `.?` operator is the same as a field access done with `.` but applied to an optional.
If the object is `null`, then the expression is skipped.
```grimoire
class MyClass {
    var x: int;
}

event main() {
    var myClass: MyClass?;
    myClass.?x = 5;
}
```

# Optional function call with « .? » and « :? »

The `.?` and `:?` operators are equivalent to a method call done with `.` and `:` respectively, but applied to an optional.
If the object is `null`, then the expression is skipped.
```grimoire
func add(a: int, b: int) (int) {
    return a + b;
}

event main() {
    var a: int?;
    a.?add(10).print;
}
```