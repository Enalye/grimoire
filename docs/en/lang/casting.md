# Casting

The `as` operator convert one value to a different type.
```grimoire
var a: float = 5 as<float>;
```

## Custom casting

You can define your own cast function by naming it `as`.

It can only have one input and one output value.

```grimoire
class MyClass {}

event onLoad() {
    var obj = @MyClass;
    print(obj as<string>); // Prints "Hello"
}

func as(MyClass a) (string) {
    return "Hello";
}
```

Note that if a default convertion exists, it'll be called instead.