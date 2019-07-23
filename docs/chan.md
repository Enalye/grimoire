* [Next: Error Handling](error.md)
* [Prev: Structure](struct.md)
* [Main Page](index.md)

* * *

# Channels

Channels are a concept that allow synchronised communication between tasks.
If you know them from Go, it's roughly the same.

Channels are created like this:
```cs
chan(int) c = chan(int, 5);
```
Here, we create a channel that will hold up to 5 int values.
The size (5) of the channel is optional, by default, it's 1.

To pass a value around, you need to use the <- operator
```cs
let c = chan(int);
c <- 1; //We send the value 1 through the channel
int value = <-c; //We receive the value from the channel
```

But a send or receive operation is blocking, you can't do it on the same task.

```cs
task foo(chan(int) c) {
	print(<-c);
}
main {
	let c = chan(int);
	foo(c);
	c <- "Hello World !";
}
```
Here, foo will be blocked until something is written on the channel, then it'll print it.

## Select statement

A select is syntaxically like a switch, but differs in that it doesn't do value comparison, it checks each case for an operation that can process.

```cpp
select
case { printl("Nothing is ready"); }
case(i = <- c) { printl("received: " ~ i as string); } 
case(c <- "Hey") { printl("sent value 'Hey'"); } 
```
The default case is optional, but without one, the select statement is a blocking operation, else the default case will execute if nothing is ready.

* * *

* [Next: Error Handling](error.md)
* [Prev: Structure](struct.md)
* [Main Page](index.md)