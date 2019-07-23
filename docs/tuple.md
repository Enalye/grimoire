* [Next: Structure](struct.md)
* [Prev: Array](array.md)
* [Main Page](index.md)

* * *

# Tuples

Tuples are a way to combine several types into a single one.

They are declared like this:
```cpp
tuple MyTuple {
	int a;
	float b;
}
```

Each field can be accessed with ":"
```cpp
main {
	MyTuple t;
	t:a = 5;
	t:b = 8.7;
}
```

* * *

* [Next: Structure](struct.md)
* [Prev: Array](array.md)
* [Main Page](index.md)