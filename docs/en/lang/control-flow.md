# Control flow

## If/Else/Unless

`if` is a keyword that allows you to run a portion of code only if its condition is verified, `unless` do the opposite.
You can combine it with optional `else if` or `else unless` to do the same thing, only if the previous ones aren't run.
Finally you can add an optional `else` that is run *only* if others are not run.

Exemple:
```grimoire
event onLoad() {
	if(5 < 2) {
		//This code won't run because 5 is never less than 2.
		print("5 is less than 2 !");
	}

	unless(5 < 2) {
		//This one will, because unless do the opposite of if
		//It's the same thing as if(not 5 < 2) {}
		print("5 is not less than 2...");
	}
}
```
Another one:
```grimoire
event onLoad() {
	let i = 5;
	if(i > 10) {
		print("i is more than 10");
	}
	else if(i >= 5) {
		print("i is 5 or more but less than 10");
	}
	else unless(i < 2) {
		print("i is 2 or more, but less than 5");
	}
	else { //else must always be put at the end of the (if/unless)/else (if/unless)/else serie, but is optional.
		print("i is 2 or less");
	}
}
```

## Switch statement

`switch` let us do comparisons a bit like `if`, but in a more concise manner.

```grimoire
let i = "Hello";
switch(i)
default { // Default case if others aren't valid.
	print("I don't know what he said");
}
case("Hey") {
	print("He said hey");
}
case("Hello") {
	print("He said hello");
}
```

Contrary to `if` statement, cases can be put in any order, and will check equality between the switch value and each cases value.

A `default` is an optional statement that behave a bit like the `else` statement above, you can only have one default case per switch statement.

## Select statement

A select is syntaxically like a switch, but differs in that it doesn't do value comparison, it checks each case for an operation that can process whithout blocking.

```grimoire
select
case( /* channel operation  */ ) {

}
default {
	/* run if the one above is blocked */
}
```

Each case contains a potentially blocking operation, the first non-blocking operation case is run.
The default case is optional, but without one, the select statement will be a blocking operation, otherwise the default case will execute when others are blocked.

```grimoire
select
case(myValue = <- myChannel) { // Receive operation
	print("Received " ~ myValue);
}
case(myOtherChannel <- "Hello") { // Send operation
	print("Sent Hello");
}
default {
	// Run if no one else can run.
	// If it's not present, select will blocking until one of the case is non-blocking.
	print("Did nothing");
}
```

## Loops

A loop is a structure that can be executed several time, there are two type of loops.

### Infinite loops

Infinite loops are infinite:
```grimoire
loop {
	print("Hello !");
}
```
This script will prompt *"Hello !"* infinitely until the process is killed, be cautious with it.
You may want to add either a `yield` to interrupt the loop each time or add an exit condition.

### Finite loops

Finite loops, on the other hand, have a finite number of time they will run.
Contrary to the infinite one, they take an int as a parameter, which indicate the number of loops:
```grimoire
loop(10) {
	// "I loop 10 times !" will only be printed times.
	print("I loop 10 times !");
}
```

You can also specify an iterator, which must be of type `int`.
```grimoire
loop(i, 10)
	print(i); // Prints from 0 to 9

// Same as above, but we declare i.
loop(int i, 10)
	print(i);

// Also valid.
loop(let i, 10)
	print(i);
```

## While/Do While

`while` and `do while` are, akin to loops, statements that can execute their code several time.
The difference is, they do not have a finite number of loop, instead, they have a condition (like `if` statements).
```grimoire
int i = 0;
while(i < 10) {
	print(i); // Here, the output is 0, 1, 2, 3, 4, 5, 6, 7, 8 and 9.
	i ++;
}
```
`do while` is the same as `while` but the condition is checked after having run the code one time.
```grimoire
int i = 11;
do { //This is garanteed to run at least once, even if the condition is not met.
	print(i); //Will print "11"
}
while(i < 10)
```

## For

`for` loops are yet another kind of loop that will automatically iterate on an list of values.
For instance:
```grimoire
for(i, [1, 2, 3, 4]) {
	print(i);
}
```
Here, the for statement will take each value of the list, then assign them to the variable "i" specified.

The variable can be already declared, or declared inside the for statement like this:

```grimoire
int i;
for(i, [1, 2]) {}
```
Or,
```grimoire
for(int i, [1, 2]) {}
```
If no type is specified, or declared as let, the variable will be automatically declared as `var`.

The variable type must be convertible from the list's values, or it will raise a runtime error.

### Iterators

`for` can also iterate on special object or native called iterators.
In grimoire, an iterator is defined by the fact that a function that satisfies this signature exists:
> `function next(Iterator) (bool, VALUE)`

A function `next` must exists that takes the iterator and returns a `bool` and the current value.
The `bool` must be false when the iterator has finished iterating, true otherwise.

```grimoire
// The each() function takes the string and return
// an IterString object that iterate over the string
for(i, "Hello World":each) {
	i:print;
}
```