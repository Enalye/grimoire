# Functions

Like any other language, functions behave the same. They are declared like this:
```cpp
function myFunction() {}
```
Here, the function myFunction takes no parameter, returns nothing and do nothing, which is boring..

Here is a function that takes 2 int, and returns the sum of them
```cpp
function add(int a, int b) (int) {
  return a + b;
}
```
The return type is always put after the parenthesis inside another pair of parenthesis. If there is no return type, you can put empty parenthesis `()` or nothing.
If there is no return value, you can use return alone to exit the function anywhere.
```cpp
function foo(int n) {
  if(n == 0) {
    print("n is equal to 0");
    return
  }
  print("n is different from 0");
}
```

A function can have multiple return values, the types returned must correspond to the signature of the function.
```cpp
function foo() (int, string, bool) {
	return 5, "Hello", false;
}
```