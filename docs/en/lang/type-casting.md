# Type casting

You can explicitly cast a value to any type with the keyword `as`, it must be followed by the desired type like this: `float a = 5 as float;`.

## Custom casting

You can define your own cast by naming a function with `as`.
It must only have one input and one output.

```grimoire
class MyClass {}

event onLoad() {
    let obj = new MyClass;
    print(obj as string); // Prints "Hello"
}

function as(MyClass a) (string) {
    return "Hello";
}
```

Note that if a default convertion exists, it'll call this one instead.