# Introduction

Grimoire is an embedded language for D applications.
You can easily define custom functions and types from D.

# Navigation

## [First Program](first_program.md)
## [Variable](variables.md)


# Function
Like any other language, functions behave the same. They are declared like this:
```cpp
func myFunction() {}
```
Here, the function myFunction takes no parameter, returns nothing and do nothing, which is boring..

Here is a function that takes 2 int, and returns the sum of them
```cpp
func add(int a, int b) int {
  return a + b;
}
```
The return type is always put after the parenthesis, if there is no return value, you can put void or leave it blank.
If there is no return type, you can use return alone to exit the function anywhere.
```cpp
func foo(int n) {
  if(n == 0) {
    print("n is equal to 0");
    return
  }
  print("n is different from 0");
}
```

# Task
Task are Grimoire's implementation of coroutines. They are syntaxically similar to function except from a few points:
* A task have no return type and can't return anything.
* When called, a task will not execute immediately and will not interrupt the caller's flow.
* A task will only be executed if other tasks are killed or on yield.

Syntax:
```cpp
task doThing() {
  print("3");
  yield
  print("5");
}

main {
  print("1");
  doThing();
  print("2");
  yield
  print("4");
}
```
Here, the main will print 1, spawn the doThing task, print 2 then yield to the doThing task which will print 3 then yield again to the main which will print 4. Then the main will die so the doThing task will resume and print 5.

To interrupt the flow of execution of the task and let other task continue, you can use the keyword **yield**.
The task will run again after all other tasks have run once.

You can also delete the task with the keyword **kill**. Also be aware that inside the scope of a task, the keyword **return** will behave the same as **kill**.

Note: The main is a special case of a task.

# Control Flow

## If/Else/Unless

## Loop

## While/Do While

## For

# Anonymous functions/tasks

# Structures

# Objects

# Channels

# Events

# Error Handling

## Try/Catch

## Deferring


