* [Next: Task, Grimoire's coroutine](task.md)
* [Prev: Control flow](control.md)
* [Main Page](index.md)

* * *

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

* * *

* [Next: Task, Grimoire's coroutine](task.md)
* [Prev: Control flow](control.md)
* [Main Page](index.md)