# Lists

Lists are a collection of values.
All the element in a list must be of the same type.
```grimoire
[1, 2, 3];
```

A list is of type `list<T>` or `[T]` where `T` is the type of the values contained within.
```grimoire
var x: list<int> = [1, 2, 3];
var x: [int] = [1, 2, 3];
```

The compiler may not be able to know the type of the list if it's empty.
In this case, we anotate its type.
```grimoire
var x = list<int>[];
```

To append to a list, we use the `~` operator.
```grimoire
var x = [1, 2, 3];
x ~= 5; // x -> [1, 2, 3, 5]
```

We can specify the list's initial size.
```grimoire
var x = list<int, 5>;          // x -> [0, 0, 0, 0, 0]
var y = list<int, 4>[7, 8, 9]; // y -> [7, 8, 9, 0]
```
> The type must have a default value.

Accessing an element from a list is 0-indexed.
```grimoire
var x = [7, 8, 9];
x[0] = 12; // x -> [12, 8, 9]

var y = [[1, 2, 3], [11, 12, 13], [21, 22, 23]];
y[1, 2]; // -> 13
```

A negative index starts from the end of the list.
```grimoire
var x = [7, 8, 9];
x[-1]; // -> 9
```