# Introduction

Grimoire is an embedded language for D applications.
You can easily define custom functions and types from D.

## First Program

Starting with the traditionnal "Hello World" :
```cpp
main {
  print("Hello World!");
}
```
Here the programs runs within a special function called **main**.
Then we pass the "Hello World!" string to the **print** primitive.

# Variables

Variable can store a value that can be used later.
A variable is defined by its type and must be declared before use.

`int a = 0;`
Here we created a variable **a** of type **int** initialized with the value **0**.
If we print the content of a with 'print(a)'. The prompt will display **0**.

A variable must be initialized before accessing its content, else it will raise an error !

## Basic Types
They're only a handful of basic type recognised by grimoire.
* Void type
* Integer declared with **int** ex: 2
* Floating number declared with **float** ex: 2.35
* Boolean declared with **bool** ex: true, false
* String declared with **string** ex: "Hello"
* Array declared with **array** ex: [1, 2.3, [true, "Hi!"]]
* Generic type declared with **var**
* Function/Task (see anonymous function page)
* Structure type
* Custom type (User defined type in D)
* Object (TODO)
* Channel (TODO)

### Auto Type
**let** is a special keyword that let the compiler automatically infer the type of a declared variable.
Exemple:
```cpp
main {
  let a = 3.2; //'a' is inferred to be a float type.
  print(a);
}
```
let can only be used on variable declaration and cannot be part of a function signature because it's not a type !

### Generic Type
If you want your variable to be able to store any type of value, you can let your variable be a generic.
For that, you use the type **var** like `var a = "Hello";`.

You can also change its type dynamically:
```cpp
main {
  var a = 2;
  a = true;
  a = "Hi!";
}
```

## Scope
A variable can either be local or global.
* A global variable is declared outside of any function/task/etc and is accessible in everywhere in every file.
* A local variable is only accessible inside the function/task/etc where it was declared.

Exemple:
```cpp
int globalVar; //Declared outside of any scope, accessible everywhere.

main {
  int localVar; //Declared inside the main, only accessible within the main.
}
```
