# Variables

Variable can store a value that can be used later.
A variable is defined by its type and must be declared before use.

A variable is declared with `var`.
```grimoire
var a = 0;
```

The variable will automatically infer the type of the variable depending on the value assigned to it.

The type can also be explicitly annotated after its name.
```grimoire
var a: int = 0;
```

Without initialisation, you must annotate its type.
```grimoire
var a; // Error, the type of « a » is unknown
```

Without initialisation, a variable will be initialised with its default value.
If no default value exist for this type, the program won't compile.
> **Note:** The default value of a class or a native type is its default constructor.
```grimoire
class A1 {}
class A2 {}

func @A2() (A2) {
    return @A2 {};
}

event main {
    var a: float;   // 0.0 by default
    var b: A1;      // Error
    var c: A2;      // Call the constructor @A2()
}
```

## Default value

We can fetch the default value of a given type with `default<T>` where `T` is the type to get.
```grimoire
var x = default<int>; // -> 0
```

## Scope
A variable can either be local or global.
* A variable declared **outside** of any function/task/etc is **global**.
* A **local** variable is only accessible inside the **block** where it was declared.
> A block is defined by a pair of braces `{}`

```grimoire
var globalVar: int; //Declared outside of any scope, accessible everywhere.

event main() {
  var localVar: int; //Declared inside the main, only accessible within the current block.
}
```

## Redeclaration
We can redeclare a variable, it will replace the old definition in the current scope.
```grimoire
event main() {
    var x = 5;
    x.print; // -> 5

    var x = "Hello";
    x.print; // -> « Hello »
}
```

Variable shadowing is also allowed.
```grimoire
event main() {
    var x: int = 5;

    {
        var x: int = 12;
        x.print; // -> 12
    }

    x.print; // -> 5
}
```

### Visibility
A global variable is only visible from its own file by default.
To access it from another file, you have to export it with `export`.
```grimoire
export var globalVar: int; // Now you can use it from another file.
```

The same is true for declared types, or even classes’ fields. 
```grimoire
export class A {        // The class is visible globally.
    export var a: int;  // a is visible globally.
    var b: int;         // b is only visible in the file.
}
```

## Declaration List

We can declare several variables by separating them with a comma.
```grimoire
event main() {
    var a, b: int;

    a.print; // -> 0
    b.print; // -> 0
}
```

Variables' initialisation is done in the same order as the declaration.
```grimoire
event main() {
    var a, b = 2, 3;

    a.print; // -> 2
    b.print; // -> 3
}
```

If there is not enough values to assign, the other variables will get the last value.
```grimoire
event main() {
    var a, b, c = 2, 3;

    a.print; // -> 2
    b.print; // -> 3
    c.print; // -> 3
}
```

We can skip one or more values by using empty commas, it'll copy the last value.
```grimoire
event main() {
    var a, b, c = 12,, 5;

    a.print; // -> 12
    b.print; // -> 12
    c.print; // -> 5
}
```

Nevertheless, the first value cannot be empty.
```grimoire
event main() {
    var a, b, c = , 5, 2; // Error
}
```

Without type annotation, variables declared by an initialisation list are of the type of the value assigned to them.
```grimoire
event main() {
    var a, b, c, d = true, 2.3, "Hello!";

    a.print; // -> true
    b.print; // -> 2.3
    c.print; // -> "Hello!"
    d.print; // -> "Hello!"
}
```