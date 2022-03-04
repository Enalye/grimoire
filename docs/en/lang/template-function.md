# Template functions

Global functions and tasks can be defined with generic types:
```grimoire
function<T> add(T a, T b)(T) {
    return a + b;
}
```
Here, `T` is a generic type that will be replaced with the actual type when generating the function.

You can also have multiple template variables:
```grimoire
public function<A, B> add(A a, B b)(B) {
    return a as B + b;
}
```

Operators can also be templated:
```grimoire
function<T> operator<=>(T a, T b)(int) {
	if(a < b)
		return -1;
	else if(a > b)
		return 1;
    return 0;
}
```

## Constraints

Constraints are additional restrictions imposed on a particular type.
To restraint a generic type, you need to declare a `where` clause:
```grimoire
function<T> add(array(T) ary, T val)
where T: Numeric {
    loop(i, ary:size) {
        ary[i] += val;
    }
}

function<T, U> foo(T first, U second)
where T: Class,
      U: Class,
      T: Extends<U> {
}
```