# Lists

List are a collection of a single type of value.

## Creating an list
The type of an list is `list()` with the type of its content inside the parenthesis:
```grimoire
list(int) myCollection = [1, 2, 3];
```

By default, a new list has the type of its first element.
So, `[1, 2, 3]` will be an `list(int)`.

You can write it explicitly by preceding the list with its type: `list(int)[1, 2, 3]`

If your new list is empty `[]`, you **have** to write the type explicitly else compilation will fail: `list(string)[]` or `list(string)`.

To initialize an list with a default size, write the length of the list after its type.
For exemple a list of 5 integers would be: `list(int, 5)` which is equals to `[0, 0, 0, 0, 0]`
Another exemple: `list(int, 5)[7, 8, 9]` is equals to `[7, 8, 9, 0, 0]`.

## Indexing an list
To access an list element, the list index (from 0) in written between brackets:
```grimoire
let a = [10, 20, 30][1]; //New list, then immediately take the index 1 of [10, 20, 30], which is 20

let b = [[1, 2, 3], [11, 12, 13], [21, 22, 23]]; //New list
let c = b[1][2]; //Here we access the element at index 1 -> [21, 22, 23], the element at index 2 -> 23
let d = b[1, 2]; //Same as above in a nicer syntax
```

When accessing an list element, you can also modify it:
```grimoire
let a = [11, 12, 13];
a[0] = 9; //a now has [9, 12, 13]
```

List and list indexes are passed by references, that mean manipulating list do not make copies.
```grimoire
let a = [1, 2, [3, 4]];
let b = a[2]; //b is now a reference to the 3rd value of a
b[0] = 9;

print(a); //Prints [1, 2, [9, 4]]
```

You can concatenate values into an list by using the concatenation operator ~
```grimoire
let a = 1 ~ [2, 3, 4] ~ [5, 6] ~ 7; //a is now [1, 2, 3, 4, 5, 6, 7]
```