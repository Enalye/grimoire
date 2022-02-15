# Variables

Variable can store a value that can be used later.
A variable is defined by its type and must be declared before use.

`int a = 0;`
Here we created a variable **a** of type **int** initialized with the value **0**.

If we print the content of the variable with 'print(a)'. The prompt will display **0**.

All variables are initialized, if you don't assign anything, it'll have its default value.

## Basic Types
They're only a handful of basic type recognised by grimoire.
* Integer declared with **int** ex: 2 (Default value: 0)
* Floating point number declared with **real** ex: 2.35f (Default value: 0f)
* Boolean declared with **bool** ex: true, false (Default value: false)
* String declared with **string** ex: "Hello" (Default value: "")
* [Array](#arrays) (Default value: [])
* [Function](#functions) (Default value: empty function)
* [Task](#tasks) (Default value: empty task)
* [Channel](#channels) (Default value: size 1 channel)
* [Class](#classes) (Default value: null)
* [Foreign](#foreign-types) (Default value: null)
* [Enumerations](#enumerations) (Default value: the first value)

### Auto Type
**let** is a special keyword that let the compiler automatically infer the type of a declared variable.
Example:
```cpp
event main {
  let a = 3.2; //'a' is inferred to be a real type.
  print(a);
}
```
let can only be used on variable declaration and cannot be part of a function signature because it's not a type !

Variables declared this way **must** be initialized.

## Scope
A variable can either be local or global.
* A global variable is declared outside of any function/task/etc and is accessible in everywhere in every file.
* A local variable is only accessible inside the function/task/etc where it was declared.

Example:
```cpp
int globalVar; //Declared outside of any scope, accessible everywhere.

event main {
  int localVar; //Declared inside the main, only accessible within the main.
}
```

### Public or private
A global variable is only visible from its own file by default.
To access it from another file, you have to declare it as public with the keyword `public`.
```cpp
public int globalVar; //Now you can use it from another file.
```

The same is true for declared types, or even classes’ fields. 
```cpp
public class A { //The class is visible globally.
    public int a; //a is visible globally.
    int b; //b is only visible in the file.
}
```

## Declaration List

You can also declare multiple variables at once separating each identifier with a comma.
> `int a, b;`

Initialization will be done in the same order:
> `int a, b = 2, 3;`
Here *a = 2* and *b = 3*.

If there is not enough values to assign, the other variable will be assigned the last value:
> `int a, b, c = 2, 3;`
Here *a = 2*, *b = 3*, *c = 3*.

You can skip one or more values by leaving a blank comma, it'll then copy the last value:

> `int a, b, c = 12,, 5;`
Both *a* and *b* are equal to *12* while *c* is equal to 5.

> `int a, b, c, d = 12,,, 5;`
Both *a*, *b*, and *c* are equal to *12* while *c* is equal to 5.

The first value cannot be blank, you **can't** do this:
> `int a, b, c = , 5, 2;`


Every variable on the same initialization list must be of the same type.
Ex: `int a, b = 2, "Hi"` will raise an error because *b* is expected to be **int** and you are passing a **string**.

But you can use **let** to initialize automatically different types :
> `let a, b, c, d = 1, 2.3, "Hi!";`

Here:
* *a = 1* and is of type **int**,
* *b = 2.3* and is of type **real**,
* *c = "Hi!"* and is of type **string**,
* *d = "Hi!"* and is of type **string**.