# Channels

Channels are a concept that allow synchronised communication between tasks.
If you know them from Go, it's roughly the same.

Channels are created like this:
```grimoire
channel(int) c = channel(int, 5);
```
Here, we create a channel that will hold up to 5 int values.
The size (5) of the channel is optional, by default, it's 1.

To pass a value around, you need to use the <- operator
```grimoire
let c = channel(int);
c <- 1; //We send the value 1 through the channel
int value = <-c; //We receive the value from the channel
```

But a send or receive operation is blocking, you can't do it on the same task.

```grimoire
task foo(channel(int) c) {
	print(<-c);
}
event onLoad() {
	let c = channel(int);
	foo(c);
	c <- "Hello World !";
}
```
Here, foo will be blocked until something is written on the channel, then it'll print it.