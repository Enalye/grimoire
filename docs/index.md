# Introduction

Grimoire is an embedded language for D applications.
You can easily define custom functions and types from D.

## Sommaire

- Basics:
  - [Basic syntax](#syntax)
  - [First program](#first-program)
  - [Main](#main)
  - [Importing files](#importing-files)
  - [What's a variable ?](#variables)
  - [Control flow](#control-flow)

- Functions:
  - [Creating a function](#functions)
  - [Task, Grimoire's coroutine](#tasks)
  - [Template functions/tasks](#template-functions)
  - [Anonymous function/task](#anonymous-functions)
  - [Event function, or how to call a function from D](#event-functions)
  - [Type casting](#type-casting)
  - [Operators](#operators)

- Compound types:
  - [Arrays](#arrays)
  - [Enumerations](#enumerations)
  - [Classes](#classes)
  - [Channels](#channels)
  - [Type aliases](#type-aliases)
  - [Foreign types](#foreign-types)

- Errors:
  - [Error handling](#error-handling)
  - [Deferring code](#deferring-code)

- Implementation:
  - [Custom Primitives](#custom-primitives)

* * *

# Syntax

## Identifier

An identifier is a name used to identify something like a variable, a function, a type, etc.

It must not be reserved word, it can use any alphanumeric character, lower and upper cases, or underscores be it can't start with a digit.

Exemple of valid identifiers:
`_myVariable`
`MyVAR1__23`

`?` and `!` are also valid *only* if they are put at the end of an identifier:
`empty?`

## Reserved words

The following are keyword used by the language, they cannot be used as identifier (variables, functions, etc):
`use`, `pub`, `main`, `type`, `event`, `class`, `enum`, `template`, `if`, `unless`, `else`, `switch`, `select`, `case`, `while`, `do`, `until`, `for`, `loop`, `return`, `self`, `kill`, `killall`, `yield`, `break`, `continue`, `as`, `try`, `catch`, `raise`, `defer`, `void`, `task`, `func`, `int`, `float`, `bool`, `string`, `array`, `chan`, `new`, `let`, `true`, `false`, `null`, `not`, `and`, `or`, `xor`.

## Comments

Comments are text that are entierly ignored by the compiler, they serve as note for you.

```cpp
// Everything after those 2 slashes is ignored until the end of the line.

/*
Everything between / * and * / are ignored
/* Nested comments works too */
*/
```

## Numbers

Numbers can either be integers or floating point values.

An integer is defined by digits from 0 to 9.
A float is similar but must either:
- Have a decimal part separated by a `.` dot : `5.678`, `.123`
- Have a `f` at the end of the number : `1f`, `.25f`

You can also use underscores `_` inside the number (not in front) to make it more readable: `100_000`
The underscores won't be parsed by the compiler.

* * *

# First Program

Starting with the traditionnal "Hello World" :
```cpp
main {
  printl("Hello World!");
}
```
The code is composed of the keyword **main**, it's a special function that indicate the entry point of the script.
Then we have a left curly brace `{` with a right curly brace `}` some lines after.
Those curly braces delimit the scope of the statement (here, the **main**).
Everything inside those curly braces (called a **block**) will be executed when the **main** is run.
The whole `print("Hello World!");` form a single expression terminated by a semicolon.

Then we pass the "Hello World!" string to the **print** primitive and here is what the output displays: `Hello World!`.

# Main

Main is the starting point of the script, only one `main` is allowed.
It cannot be called except by D.
```d
vm.spawn(); // Call the "main" function
```

Note: the `main {}` won't be specified during this tutorial even when needed to avoid repetitions.
All operations (except type definitions and global variables) must exist within a local scope.

# Importing files

You can separate a script between multiple files.
To import them, use the `use` keyword with your file paths.
```cpp
use "foo/myscript.gr"

// With {} you can specify multiple paths.
use {
	"../lib/myotherscript.gr"
	"C:/MyScripts/script.gr"
}
```

The path is relative to the file importing it.
Two import with the same absolute path (i.e. the same file) will be included only once.

* * *

# Variables

Variable can store a value that can be used later.
A variable is defined by its type and must be declared before use.

`int a = 0;`
Here we created a variable **a** of type **int** initialized with the value **0**.

If we print the content of a with 'print(a)'. The prompt will display **0**.

All variables are initialized, if you don't assign anything, it'll have its default value.

## Basic Types
They're only a handful of basic type recognised by grimoire.
* Integer declared with **int** ex: 2 (Default value: 0)
* Floating number declared with **float** ex: 2.35f (Default value: 0f)
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
main {
  let a = 3.2; //'a' is inferred to be a float type.
  printl(a);
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

main {
  int localVar; //Declared inside the main, only accessible within the main.
}
```

### Public or private
A global variable is only visible from its own file by default.
To access it from another file, you have to declare it as public with the keyword "pub".
```cpp
pub int globalVar; //Now you can use it from another file.
```

The same is true for declared types.
```cpp
pub class A {} //The class is visible globally.
```

## Declaration List

You can also declare multiple variables at once separating each identifier with a comma. `int a, b;`

Initialization will be done in the same order:
`int a, b = 2, 3;` Here *a = 2* and *b = 3*.

If there is not enough values to assign, the other variable will be assigned the last value: `int a, b, c = 2, 3;` Here *a = 2*, *b = 3*, *c = 3*.

You can skip one or more values by leaving a blank comma, it'll then copy the last value:

`int a, b, c = 12,, 5;`
Both *a* and *b* are equal to *12* while *c* is equal to 5.

`int a, b, c, d = 12,,, 5;`
Both *a*, *b*, and *c* are equal to *12* while *c* is equal to 5.

The first value cannot be blank, you cannot do this: `int a, b, c = , 5, 2;`


Every variable on the same initialization list must be of the same type.
Ex: `int a, b = 2, "Hi"` will raise an error because *b* is expected to be **int** and you are passing a **string**.

But you can use **let** to initialize automatically different types :
`let a, b, c, d = 1, 2.3, "Hi!";`
Here:
* *a = 1* and is of type **int**,
* *b = 2.3* and is of type **float**,
* *c = "Hi!"* and is of type **string**,
* *d = "Hi!"* and is of type **string**.

# Control flow

## If/Else/Unless

`if` is a keyword that allows you to runs a portion of code only if its condition is true, "unless" do the opposite.
You can combine it with optionals `else if` or `else unless` to do the same thing, only if the previous ones aren't run.
Finally you can add an optional `else` that is run *only* if others are not run.

Exemple:
```cpp
main {
	if(5 < 2) {
		//This code won't run because 5 is never less than 2.
		printl("5 is less than 2 !");
	}

	unless(5 < 2) {
		//This one will, because unless do the opposite of if
		//It's the same thing as if(not 5 < 2) {}
		printl("5 is not less than 2...");
	}
}
```
Another one:
```cpp
main {
	let i = 5;
	if(i > 10) {
		printl("i is more than 10");
	}
	else if(i >= 5) {
		printl("i is 5 or more but less than 10");
	}
	else unless(i < 2) {
		printl("i is 2 or more, but less than 5");
	}
	else { //else must always be put at the end of the (if/unless)/else (if/unless)/else serie, but is optional.
		printl("i is 2 or less");
	}
}
```

## Switch statement

`switch` let us do comparisons a bit like `if`, but in a more concise manner.

```cpp
let i = "Hello";
switch(i)
case() { // Default case if others aren't valid.
	printl("I don't know what he said");
}
case("Hey") {
	printl("He said hey");
}
case("Hello") {
	printl("He said hello");
}
```

Contrary to `if` statement, cases can be put in any order, and will check equality between the switch value and each cases value.
A `case` without value is considered to be a default case like the `else` above, you can only have one maximum per switch statement.

## Select statement

A select is syntaxically like a switch, but differs in that it doesn't do value comparison, it checks each case for an operation that can process whithout blocking.

```cpp
select
case( /* channel operation  */ ) {

}
case() {
	/* run if the one above is blocked */
}
```

Each case contains a potentially blocking operation, the first non-blocking operation case is run.
The default case is optional, but without one, the select statement is a blocking operation, otherwise the default case will execute if when others are blocked.

```cpp
select
case(myValue = <- myChannel) { // Receive operation
	printl("Received " ~ myValue);
}
case(myOtherChannel <- "Hello") { // Send operation
	printl("Sent Hello");
}
case() {
	// Run if no one else can run.
	// If it's not present, select will blocking until one of the case is non-blocking.
	printl("Did nothing");
}
```

## Loops

A loop is a structure that can be executed several time, there are two type of loops.

### Infinite loops

An infinite loop is as the title imply, see for yourself:
```cpp
loop {
	printl("Hello !");
}
```
This script will prompt "Hello !" infinitely until the process is killed, be cautious with it.
You may want to add either a `yield` or an exit condition.

### Finite loops

Finite loops, on the other hand, have a finite number of time they will run.
Contrary to the infinite one, they take an int as a parameter, which indicate the number of loops:
```cpp
loop(10) {
	printl("I loop 10 times !");
}
```
This will only print the message 10 times.

You can also specify an iterator, which must be of type `int`.
```cpp
loop(i, 10)
	printl(i); // Prints from 0 to 9

// Same as above, but we declare i.
loop(int i, 10)
	printl(i);

// Also valid.
loop(let i, 10)
	printl(i);
```

## While/Do While

"while" and "do while" are, akin to loops, statements that can execute their code several time.
The difference is, they do not have a finite number of loop, instead, they have a condition (like "if" statements).
```cpp
int i = 0;
while(i < 10) {
	printl(i); // Here, the output is 0, 1, 2, 3, 4, 5, 6, 7, 8 and 9.
	i ++;
}
```
"do while" is the same as "while" but the condition is checked after having run the code one time.
```cpp
int i = 11;
do { //This is garanteed to run at least once, even if the condition is not met.
	printl(i); //Will print "11"
}
while(i < 10)
```

## For

"for" loops are yet another kind of loop that will automatically iterate on an array of values.
For instance:
```cpp
for(i, [1, 2, 3, 4]) {
	printl(i);
}
```
Here, the for statement will take each value of the array, then assign them to the variable "i" specified.

The variable can be already declared, or declared inside the for statement like this:

```cpp
int i;
for(i, [1, 2]) {}
```
Or,
```cpp
for(int i, [1, 2]) {}
```
If no type is specified, or declared as let, the variable will be automatically declared as `var`.

The variable type must be convertible from the array's values, or it will raise a runtime error.

* * *

# Functions

Like any other language, functions behave the same. They are declared like this:
```cpp
func myFunction() {}
```
Here, the function myFunction takes no parameter, returns nothing and do nothing, which is boring..

Here is a function that takes 2 int, and returns the sum of them
```cpp
func add(int a, int b) (int) {
  return a + b;
}
```
The return type is always put after the parenthesis inside another pair of parenthesis. If there is no return type, you can put empty parenthesis `()` or nothing.
If there is no return value, you can use return alone to exit the function anywhere.
```cpp
func foo(int n) {
  if(n == 0) {
    printl("n is equal to 0");
    return
  }
  printl("n is different from 0");
}
```

A function can have multiple return values, the types returned must correspond to the signature of the function.
```cpp
func foo() (int, string, bool) {
	return 5, "Hello", false;
}
```

* * *

# Tasks

Task are Grimoire's implementation of coroutines. They are syntaxically similar to function except from a few points:
* A task have no return type and can't return anything (You'll be able to do so with channels).
* When called, a task will not execute immediately and will not interrupt the caller's flow.
* A task will only be executed if other tasks are killed or on yield.

Syntax:
```cpp
task doThing() {
  printl("3");
  yield
  printl("5");
}

main {
  printl("1");
  doThing();
  printl("2");
  yield
  printl("4");
}
```
Here, the main will printl 1, spawn the doThing task, printl 2 then yield to the doThing task which will printl 3 then yield again to the main which will printl 4. Then the main will die so the doThing task will resume and printl 5.

To interrupt the flow of execution of the task and let other task continue, you can use the keyword **yield**.
The task will run again after all other tasks have run once.

You can also delete the task with the keyword **kill**. Also be aware that inside the scope of a task, the keyword **return** will behave the same as **kill**.

There is also **killall** which simply kills all running tasks.

*Note: The main is a special case of a task.*

* * *

# Template functions

Global functions and tasks can be defined with generic types:
```cpp
func<T> add(T a, T b)(T) {
    return a + b;
}
```
Here, `T` is a generic type that will be replaced with the actual type when generating the function.

To generate the function, you need to instanciate it with the `template` statement:
```cpp
template<int> add;
template<float> add;
```
Now, `add(int, int)(int)` and `add(float, float)(float)` have been generated and can now be called.

You can also have multiple template variables:
```cpp
pub template<int, float> add;
pub func<A, B> add(A a, B b)(B) {
    return a as B + b;
}
```

Operators can also be templated:
```cpp
template<int> operator<=>;
template<float> operator<=>;
func<T> operator<=>(T a, T b)(int) {
	if(a < b)
		return -1;
	else if(a > b)
		return 1;
    return 0;
}
```

* * *

# Anonymous functions

You can declare a function or a task inside another function (or task).
Like this:

```cpp
main {
	let f = func() {};
	let t = task() {};
}
```

You can also decide to just run it immediately:
```cpp
main {
	int a = 7;
	int b = func(int c) (int) {
		return c * 2;
	}(a);
	printl(b); //Prints 14
}
```

The type of a function/task is the same as its declaration without the parameters' name:
```cpp
main {
	func(int, float) (string, int) myFunction = func(int a, float b) (string, int) { return "Hey", 2; };
}
```

You can use a global function/task as an anonymous by getting its address.
You can do so by using the & operator.
The operator & does not require the function type, except when it has no way to know it at compilation time, like when declaring with let.

```cpp
func square(int i) (int) {
	return i * i;
};

main {
	let f1 = &square; //Error, & has no way to know the type at during compilation (square could be overloaded).
	let f2 = &(func(int) (int))square; //Valid, an explicit type prevent this problem.
	f2 = &square; //Now valid, because it's now typed by the previous assignment.

	func(int) (int) f3 = &square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &square; //Valid, since f3 is already declared with a type.
}
```

## Self

If you want to refer to the current function, but you're inside an anonymous function you can't because the function has no name.

Except `self`. Self is used to refers to the current function/task/etc even anonymous ones.

It allows you to do things like this anonymous recursive fibonacci:
```cpp
func(int n) (int) {
    if(n < 2) return n;
    return self(n - 1) + self(n - 2);
}(10):printl;
```

* * *

# Event functions

Events are like tasks that can only be spawned from D.

They are declared like tasks and can only be global:
```cpp
event foo(string msg) {
	printl(msg);
}
```

To spawn this one from D:
```d
auto mangledName = grMangleNamedFunction("foo", [grString]);
if(vm.hasEvent(mangledName)) {
    GrContext context = vm.spawnEvent(mangledName);
	context.setString("Hello World!);
}
```
Here the process is a little bit special.
First, we need to know the mangled name (name + signature) of the event with "grMangleNamedFunction".
Then, we call it.
If the event has parameters, you absolutely ***must*** push those values to the new context, else the VM will crash.

* * *

# Type casting

You can explicitly cast a value to any type with the keyword `as`, it must be followed by the desired type like this: `float a = 5 as float;`.

## Custom casting

You can define your own cast by naming a function with `as`.
It must only have one input and one output.

```cpp
class MyClass {}

main {
    let obj = new MyClass;
    printl(obj as string); // Prints "Hello"
}

func as(MyClass a) (string) {
    return "Hello";
}
```

Note that if a default convertion exists, it'll call this one instead.

## In D

To define a new cast, add it to the GrData.
```d
data.addCast(&myCast, "myObj", myObjType, grString);
```

Then, define the function itself:
```d
void myCast(GrCall call) {
    auto myObj = call.getObject("myObj");
    call.setString("Hello");
}
```

# Operators

Much like custom convertions, you can define your own operators.
The name of the function must be `operator` followed by the operation.
You also have to respect the number of input the operator uses (1 or 2).

```cpp
main {
    printl(3.5 + 2);
}

func operator+(float a, int b) (float) {
    return a + b as float;
}
```

## In D

Like addCast, but using addOperator instead.
```d
data.addOperator(&myOperator, "+", ["a", "b"], [grFloat, grInt], grFloat);
```

Then writing the function itself.
```d
void myOperator(GrCall call) {
    call.setFloat(call.getFloat("a") + cast(int) call.getInt("b"));
}
```

Note that if a default operation exists, it'll call this one instead,
so overloading a `+` operator between 2 integers is useless.

* * *

# Arrays

Array are a collection of a single type of value.

The type of an array is `array()` with the type of its content inside the parenthesis:
```cpp
array(int) myCollection = [1, 2, 3];
```

By default, a new array has the type of its first element.
So, `[1, 2, 3]` will be an `array(int)`.

You can write it explicitly by preceding the array with its type: `array(int)[1, 2, 3]`

If your new array is empty `[]`, you **have** to write the type explicitly else compilation will fail: `array(string)[]`.

To access an array element, the array index (from 0) in written between brackets:
```cpp
let a = [10, 20, 30][1]; //New array, then immediately take the index 1 of [10, 20, 30], which is 20

let b = [[1, 2, 3], [11, 12, 13], [21, 22, 23]]; //New array
let c = b[1][2]; //Here we access the element at index 1 -> [21, 22, 23], the element at index 2 -> 23
let d = b[1, 2]; //Same as above in a nicer syntax
```

When accessing an array element, you can also modify it:
```cpp
let a = [11, 12, 13];
a[0] = 9; //a now has [9, 12, 13]
```

Array and array indexes are passed by references, that mean manipulating array do not make copies.
```cpp
let a = [1, 2, [3, 4]];
let b = a[2]; //b is now a reference to the 3rd value of a
b[0] = 9;

printl(a); //Prints [1, 2, [9, 4]]
```

You can concatenate values into an array by using the concatenation operator ~
```cpp
let a = 1 ~ [2, 3, 4] ~ [5, 6] ~ 7; //a is now [1, 2, 3, 4, 5, 6, 7]
```

* * *

# Enumerations

Enumerations (or enum) are a set of named constants defined inside a single type.
They can only be compared between them and can't do any arithmetic operation.

## Definition

They are declared with the keyword enum:
```cpp
enum Color {
	red;
	green;
	blue;
}
```

Likely, you can declare it in D by calling `addEnum` on your `GrData`:
```d
data.addEnum("Color", ["red", "green", "blue"]);
```

## Accessing a field

To access a value, just type the name of the enum with
the name of the field you want separated with a dot:
```cpp
main {
	Color myColor = Color.red;

	switch(myColor)
	case(Color.red) "The color is red !":printl;
	case(Color.green) "The color is green !":printl;
	case(Color.blue) "The color is blue !":printl;
}
```

* * *

# Classes

Classes are types that can hold fields of different types.

## Definition

Declaration is made with the `class` keyword.
```cpp
class MyClass {
    int foo;
    string bar;
}
```

It is equivalent to :
```d
data.addClass("MyClass", ["foo", "bar"], [grInt, grString]);
```
In the D side of thing, you declare an object type with `addClass` to the `GrData`.

## New

To create an instance of that class (i.e. an object), you use the `new` keyword followed by the class type.
```cpp
MyClass obj = new MyClass;
```

By default, all fields will be initialized with its default value, to change that, you need to use the constructor notation.

```cpp
MyClass obj = new MyClass {
	foo = 5;
	bar = "Hello";
};
```

Unspecified fields in the constructor will still be initialized by default.

You can create an object in D by using the `createObject()` method of GrCall.
Here's a little example:

* Declaration:
```d
auto messageType = data.addClass("Message", ["greetings"], [grString]);
data.addPrimitive(&createMessage, "createMessage", [], [], [messageType]);
```

* Primitive:
```d
void createMessage(GrCall call) {
    auto obj = call.createObject("Message");
    if(obj is null) {
        call.raise("Message not declared");
        return;
    }
    obj.setString("greetings", "Hello World !");
    call.setObject(obj);
}
```

Grimoire code:
```cpp
main {
    let myObj = createMessage();
    myObj.greetings:printl;
}
```

It'll print "Hello World !".


## Accessing a field

To access a field, use the `.` notation.
```cpp
obj.foo = 5;
obj.bar = "Hello";
printl(obj.bar);
```

In D, use set and get functions.
```d
void _prim(GrCall call) {
    auto obj = call.getObject("obj");
    writeln(obj.getInt("foo"));
    obj.setInt("bar", 5);
}
```

By default, all fields are only visible to the file that declared it.
To make them visible to all files, you need to specify them as public with the "pub" keyword:
```cpp
class A {
	pub int a; // Visible globally
	int b; // Visible only to the current file
}
```

## Null

An uninitialized class variable will be initialized to null.

Like foreign types, you can assign "null" to a class type variable.

```cpp
MyClass obj = null;
if(!obj)
	"Obj is null":printl;
```

Trying to access a null object's field will raise an error.

## Inheritance

You can inherit fields from another class:
```cpp
class MyClass : ParentClass {

}
```

In D, its indicated by an optional parameter:
```d
data.addClass("MyClass", [], [], "ParentClass");
```

* * *

# Channels

Channels are a concept that allow synchronised communication between tasks.
If you know them from Go, it's roughly the same.

Channels are created like this:
```cpp
chan(int) c = chan(int, 5);
```
Here, we create a channel that will hold up to 5 int values.
The size (5) of the channel is optional, by default, it's 1.

To pass a value around, you need to use the <- operator
```cpp
let c = chan(int);
c <- 1; //We send the value 1 through the channel
int value = <-c; //We receive the value from the channel
```

But a send or receive operation is blocking, you can't do it on the same task.

```cpp
task foo(chan(int) c) {
	print(<-c);
}
main {
	let c = chan(int);
	foo(c);
	c <- "Hello World !";
}
```
Here, foo will be blocked until something is written on the channel, then it'll print it.

* * *

# Type Aliases

A type alias allow types to be named differently, making long signatures shorter.

```cpp
func square(int i) (int) {
	return i * i;
};

type MyFunc = func(int) (int);

main {
    MyFunc myFunc = &(MyFunc) square;
	10:myFunc:printl;
}
```

You can also declare aliases in D by calling `addTypeAlias` on your `GrData`:
```d
data.addTypeAlias("MyInt", grInt);
```

* * *

# Foreign types

Foreign types are opaque pointers used by D, grimoire doesn't have access to their content.
As such, they can only be declared from D.
```d
data.addForeign("MyType");
```

Like classes, they can inherit from another foreign type.
```d
data.addForeign("MyType", "ParentType");
```

* * *

# Error Handling

Error handling in Grimoire is done by raising/catching errors

To raise an error, simply write:
```cpp
raise "Error";
```
If you do nothing about it, the entire VM will panic, because the current task does nothing to catch it.

So we should probably catch it:
```cpp
main {
	try {
		raise "Error";
	}
	catch(e) {
		printl("I caught " ~ e);
	}
}
```
And everything is fine.

* * *

# Deferred statements

Code put inside a defer statement, is *garanteed* to be executed at the end of the function/task,
even if an error is thrown before the end of the scope.

```cpp
main {
	defer { printl("Inside defer !"); }
	printl("Before defer");
	raise "Error";
}
```
Here, the prompt will show "Before defer", then "Inside defer !", even if we raise an error before the end of the scope.
It's useful for handling resources that need to be freed.

* * *

# Custom Primitives

## What's a primitive

In this language, a primitive is a function declared in D accessible from a script.
`print` for instance, is a primitive.

They must be declared before the compilation anb remain unchanged in the VM.

## Primitive declaration

To declare your primitive use `addPrimitive`.
This function takes a callback to your primitive, the name which your primitive will be known as in scripts,
an array of parameters' name, the parameters' type and, optionally, an array of return value types.
Exemple:
```d
//A function print that takes a string and returns nothing
data.addPrimitive(&print_a_string, "print", ["value"], [grString]);
//Function mul() that takes 2 floats and returns one.
data.addPrimitive(&multiply, "mul", ["a", "b"], [grFloat, grFloat], [grFloat]);
```

If you want to multiply 2 things, a better idea is to declare an operator (if it doesn't already exists for your types):

```d
data.addOperator(&multiply, "*", ["a", "b"], [grFloat, grFloat], grFloat);
```
An operator declaration only take the name of the operator it surcharges, 1 or 2 parameters, and a single return type.

But if you want to convert from one type to another using a primitive, you can do so with this function:
```d
data.addCast(&cast_float_to_int, "value", grFloat, grInt);
```
Much simpler, it takes a single parameter and return value.

## The primitive itself

The callback takes a GrCall object and return nothing.
The GrCall object contains everything you need about the current running context.

It looks like this:
```d
void myPrimitive(GrCall call) {
	writeln(call.getFloat("value"));
    call.setInt(99);
}
```
Here, the primitive takes a float parameter called `"value"`, and prints it, then returns the int value 99.
getXXX methods fetch the parameters, they have the same name/type as declared, else it will throw an exception.
setXXX methods returns a value on the stack, beware of the order in which you call setXXX functions.


* * *

## Generic type

Grimoire provide a way to declare a primitive with generic types with `grAny`.
*grAny* takes two arguments:
	* The name of the generic type,
	* A predicate that checks if the provided type is correct.

The predicate takes 2 parameters:
	* A `GrType` of the provided value,
	* The context of the checker containing the defined generic types.

Exemple of a primitive that can define a `push` function for every type of array that uses integers.
It takes an array and a value that matches the type held by the array, and returns the array itself.
```d
data.addPrimitive(&_push, "push", ["array"], [
    grAny("A",   // We declare a generic type called "A"
	(type, data) {
		if (type.baseType != GrBaseType.array_) // This type must be an array
			return false;
		const GrType subType = grUnmangle(type.mangledType); // The subType is mangled
		data.set("T", subType);  // We define the other generic type (called "T") with the subtype of the array
		return grIsKindOfInt(subType.baseType); // We check is the baseType is good for us.
	}), grAny("T")], // "T" is already defined above, so the types must match.
	[grAny("A")]   // "A" is already defined above, it must be of the same type. Putting any predicate here is useless.
);
```

If no predicate is given to a *grAny*, the type is always validated.
The predicate of return types won't be checked, only the input signature is validated.