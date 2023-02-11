## Loops

`loop` allows us to repeat a block of code several times.
```grimoire
loop {
	print("Hi !");
}
```
We can limit the number of iteration.
```grimoire
loop(10) {
	print("I loop 10 times !");
}
```
We can also specify an iterator.
```grimoire
loop(i, 10)
	print(i); // Display values from 0 to 9

// The type of the iterator is optional
loop(i: int, 10)
	print(i);
```

## While/Do While

`while` loops while its condition is checked.
```grimoire
var i = 0;

while(i < 10) {
	print(i);
	i ++;
}
```

`until` loops while its condition is not checked.
```grimoire
var i = 0;

until(i > 10) {
	print(i);
	i ++;
}
```

`do` `while` only checks its condition after each iteration.
```grimoire
var i = 11;

do {
	print(i); // Display 11
}
while(i < 10)
```

`do` `until` is the same but while the condition is not checked.
```grimoire
var i = 11;

do {
	print(i); // Display 11
}
until(i > 10)
```

## For

`for` iterates on each element of a list or of an iterator.
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
To iterator on an object other than a list, `for` needs to call a function `func<I, T> next(I) (T?)` where `I` is the iterator object, and `T` the value to iterate on.
```grimoire
for(i, "Hello everyone !".each) {
	i.print;
}
```

# Yield

All the loops `loop`, `for`, `while`, `until`, … can be annotated with `yield`.
Those loops are guaranteed to `yield` after each iteration.
```grimoire
loop yield(i, 10) {
    i.print;
}
```