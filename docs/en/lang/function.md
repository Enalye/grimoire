# Functions

The `func` keyword declares a global function.
```grimoire
export func additionner(a: int, b: int) (int) {
    return a + b;
}

func compareWith0(n: int) {
  if(n == 0) {
    print("n is equal to 0");
    return
  }
  print("n is different from 0");
}
```

A function can have multiple return values.
```grimoire
func giveValues() (int, string, bool) {
	return 5, "Hi", false;
}
```

## Anonymous functions
```grimoire
event main() {
	var a = 7;
	var multiplyBy2 = func(c: int) (int) {
		return c * 2;
	};
	7.multiplyBy2.print; // Display 14
}
```

The `&` operator allows us to fetch a reference to a global function.
```grimoire
func square(i: int) (int) {
	return i * i;
};

event main() {
	var f1 = &square; //Error, & has no way to know the type at during compilation (square could be overloaded).
	var f2 = &<func(int) (int)> square; //Valid, an explicit type prevent this problem.
	f2 = &square; //Now valid, because it's now typed by the previous assignment.

	var f3: func(int) (int) = &square; //Error, can't know the type of f3 since f3 doesn't exist at the time of declaration.
	f3 = &square; //Valid, since f3 is already declared with a type.
}
```

The `function` keyword allows us to fetch a reference to the current function.
```grimoire
// Fibonacci
func(n: int) (int) {
    if(n < 2) return n;
    return function(n - 1) + function(n - 2);
}(10).print;
```

## Généricity

Global functions and tasks can be defined with generic types.
```grimoire
func<T> add(a: T, b: T)(T) {
    return a + b;
}

export func<A, B> add(a: A, b: B)(B) {
    return a as<B> + b;
}

func<T> operator"<=>"(a: T, b: T)(int) {
	if(a < b)
		return -1;
	else if(a > b)
		return 1;
    return 0;
}
```

## Constraints

The `where` clause enforces some restriction on generic types.
```grimoire
func<T> add(ary: list<T>, val: T)
where T: Numeric {
    loop(i, ary.size) {
        ary[i] += val;
    }
}

func<T, U> foo(first: T, second: U)
where T: Class,
      U: Class,
      T: Extends<U> {
}
```