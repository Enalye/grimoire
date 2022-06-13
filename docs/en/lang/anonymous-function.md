# Anonymous functions

You can declare a function or a task inside another function (or task).
Like this:

```grimoire
event onLoad() {
	let f = function() {};
	let t = task() {};
}
```

You can also decide to just run it immediately:
```grimoire
event onLoad() {
	int a = 7;
	int b = function(int c) (int) {
		return c * 2;
	}(a);
	print(b); //Prints 14
}
```

The type of a function/task is the same as its declaration without the parameters' name:
```grimoire
event onLoad() {
	function(int, real) (string, int) myFunction = function(int a, real b) (string, int) { return "Hey", 2; };
}
```

You can use a global function/task as an anonymous by getting its address.
You can do so by using the & operator.
The operator & does not require the function type, except when it has no way to know it at compilation time, like when declaring with let.

```grimoire
function square(int i) (int) {
	return i * i;
};

event onLoad() {
	let f1 = &square; //Error, & has no way to know the type at during compilation (square could be overloaded).
	let f2 = &(function(int) (int))square; //Valid, an explicit type prevent this problem.
	f2 = &square; //Now valid, because it's now typed by the previous assignment.

	function(int) (int) f3 = &square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &square; //Valid, since f3 is already declared with a type.
}
```

## Self

If you want to refer to the current function, but you're inside an anonymous function you can't because the function has no name.

Except `self`. Self is used to refers to the current function/task/etc even anonymous ones.

It allows you to do things like this anonymous recursive fibonacci:
```grimoire
function(int n) (int) {
    if(n < 2) return n;
    return self(n - 1) + self(n - 2);
}(10):print;
```