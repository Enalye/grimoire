# Native

Native types are types declared in D and opaque in Grimoire.
Their internal representation is only accessible with accessors and modifiers defined in D.

Implementation details are available [here](/en/api/library).

```grimoire
var map = @HashMap<int>();
map.set("strawberry", 12);
```

In terms of usage, a native follows the same rules of inheritance, genericity, constructors, static methods and fields as a class.

> ***Important:***
A native type can't inherit from a class but a class can inherit from a native type.