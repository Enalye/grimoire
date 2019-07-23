* [Next: Tuple](tuple.md)
* [Prev: Event function, or how to call a function from D](event.md)
* [Main Page](index.md)

* * *

# Array

Array are a collection of value.

To create a new array, you can use the keyword "array" or use brackets "[]".
```cs
array a = [1, -2.1, false, "Hello"]; //New array initialized with 1, -2.1, false and "Hello"
array b = array; //New empty array
array c = []; //New empty array
```

To access an array element, put your index (from 0) between brackets:
```cs
let a = [10, 20, 30][1]; //New array, then immediately take the index 1 of [10, 20, 30], which is 20

let b = [[1, 2, 3], [11, 12, 13], [21, 22, 23]]; //New array
let c = b[1][2]; //Here we access the element at index 1 -> [21, 22, 23], the element at index 2 -> 23
let d = b[1, 2]; //Same as above in a nicer syntax
```

When accessing an array element, you can also modify it:
```cs
let a = [11, 12, 13];
a[0] = "Hey"; //a now has ["Hey", 12, 13]
```

Array and array indexes are passed by references, that mean manipulating array do not make copies.
```cs
let a = [1, 2, [3, 4]];
let b = a[2]; //b is now a reference to the 3rd value of a
b[0] = "Hey";

printl(a); //Prints [1, 2, ["Hey", 4]]
```

If you want to create a new copy of the array, use the copy operator ^
```cs
let a = [1, 2, [3, 4]];
let b = a[2]^; //b is now a copy of the 3rd value of a
b[0] = "Hey";

printl(a); //Prints [1, 2, [3, 4]]
```

You can concatenate values into an array by using the concatenation operator ~
```cs
let a = 1 ~ [2, 3, 4] ~ [5, 6] ~ 7; //a is now [1, 2, 3, 4, 5, 6, 7]
```


* * *

* [Next: Tuple](tuple.md)
* [Prev: Event function, or how to call a function from D](event.md)
* [Main Page](index.md)