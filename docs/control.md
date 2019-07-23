##### [Next: Creating a function](function.md)
##### [Prev: What's a variable ?](variable.md)
##### [Main Page](index.md)

# Control flow

## If/Else/Unless

"if" is a keyword that allows you to runs a portion of code only if its condition is true, "unless" do the opposite.
You can combine it with optionals "else if" or "else unless" to do the same thing, only if the previous ones aren't run.
Finally you can add an optional "else" that is run *only* if others are not run.

Exemple:
```cpp
main {
	if(5 < 2) {
		//This code won't run because 5 is never less than 2.
		printl("5 is less than 2 !");
	}

	unless(5 < 2) {
		//This one will, because unless do the opposite of if
		//It's the same thing as if(not 5 < 2) {}
		printl("5 is not less than 2...");
	}
}
```
Another one:
```cpp
main {
	let i = 5;
	if(i > 10) {
		printl("i is more than 10");
	}
	else if(i >= 5) {
		printl("i is 5 or more but less than 10");
	}
	else unless(i < 2) {
		printl("i is 2 or more, but less than 5");
	}
	else { //else must always be put at the end of the (if/unless)/else (if/unless)/else serie, but it's optional.
		printl("i is 2 or less");
	}
}
```

## Switch statement

"switch" let us do comparisons a bit like "if", but in a more concise manner.

```cpp
let i = "Hello";
switch(i)
case {
	printl("I don't know what he said");
}
case("Hey") {
	printl("He said hey");
}
case("Hello") {
	printl("He said hello");
}
```

Contrary to "if" statement, cases can be put in any order, and will check equality between the switch value and each cases value.
A case without value is considered to be a default case like the "else" above, you can only have one maximum per switch statement.

## Select statement

TODO: write about channels and select

## Loops

A loop is a structure that can be executed several time, there are two type of loops.

### Infinite loops

An infinite loop is as the title imply, see for yourself:
```cpp
main {
	loop {
		printl("Hello !");
	}
}
```
This script will prompt "Hello !" infinitely until process is killed, be cautious with it.
You may want to add either a `yield` or an exit condition.

### Finite loops

Finite loops, on the other hand, have a finite number of time they will run.
Contrary to the infinite one, they take an int as a parameter, which indicate the number of loops:
```cpp
main {
	loop(10) {
		printl("I loop 10 times !");
	}
}
```
This will only print the message 10 times.

## While/Do While

"while" and "do while" are, akin to loops, statements that can execute their code several time.
The difference is, they do not have a finite number of loop, instead, they have a condition (like "if" statements).
```cpp
main {
	int i = 0;
	while(i < 10) {
		printl(i); // Here, the output is 0, 1, 2, 3, 4, 5, 6, 7, 8 and 9.
		i ++;
	}
}
```
"do while" is the same as "while" but the condition is checked after having run the code one time.
```cpp
main {
	int i = 11;
	do { //This is garanteed to run at least once, even if the condition is not met.
		printl(i); //Will print "11"
	}
	while(i < 10);
}
```

## For

"for" loops are yet another kind of loop that will automatically iterate on an array of values.
For instance:
```cpp
main {
	for(i, [1, 2, 3, 4]) {
		printl(i);
	}
}
```
Here, the for statement will take each value of the array, then assign them to the variable "i" specified.

The variable can be already declared, or declared inside the for statement like this:

```cpp
main {
	int i;
	for(i, [1, 2]) {}
}
```
Or,
```cpp
main {
	for(int i, [1, 2]) {}
}
```
If no type is specified, or declared as let, the variable will be automatically declared as `var`.

The variable type must be convertible from the array's values, or it will raise a runtime error.


# Navigation

##### [Next: Creating a function](function.md)
##### [Prev: What's a variable ?](variable.md)
##### [Main Page](index.md)