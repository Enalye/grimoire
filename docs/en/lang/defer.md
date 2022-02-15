# Deferred statements

Code put inside a defer statement, is *garanteed* to be executed at the end of the function/task,
even if an error is thrown before the end of the scope.

```cpp
event main {
	defer { print("Inside defer !"); }
	print("Before defer");
	throw "Error";
}
```
Here, the prompt will show "Before defer", then "Inside defer !", even if we raise an error before the end of the scope.
It's useful for handling resources that need to be freed.