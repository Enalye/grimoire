##### [Next: Event function, or how to call a function from D](event.md)
##### [Prev: Task, Grimoire's coroutine](task.md)
##### [Main Page](index.md)

# Anonymous functions/tasks

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
	int b = func(int c) int {
		return c * 2;
	}(a);
	printl(b); //Will print 14
}
```

The type of a function/task is the same as its declaration without the parameters' name:
```cpp
main {
	func(int, float) string, int myFunction = func(int a, float b) string, int { return "Hey", 2; };
}
```

You can use a global function/task as an anonymous by getting its address.
You can do so by using the & operator.
The operator & does not require the function type, except when it has no way to know it at compilation time, like when declaring with let.

```cpp
func square(int i) int {
	return i * i;
};

main {
	let f1 = &square; //Error, & has no way to know the type inside a variant at compilation time.
	let f2 = &(func(int) int)square; //Valid, an explicit type prevent this problem.
	f2 = &square; //Now valid, because it's now typed by the previous assignment.

	func(int) int f3 = &square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &square; //Valid, since f3 is already declared with a type.
}
```


# Navigation

##### [Next: Event function, or how to call a function from D](event.md)
##### [Prev: Task, Grimoire's coroutine](task.md)
##### [Main Page](index.md)