# Channels

Channels allow synchronised messaging between tasks.
```grimoire
var chan: channel<int>;
```

By default, a channel has a capacity of 1.
To change its capacity, we must explicitly declare it upon initialisation.
```grimoire
var chan = channel<int, 5>; // Capacity of 5
```

The `<-` operator allow us to send or receive values from a channel.
```grimoire
var c = channel<int>;
c <- 1; //We send the value 1 through the channel
var value = <-c; //We receive the value from the channel
```

If no value is available inside the channel, the receive operation is blocking until a value is sent.
It the channel is full, the send operation becomes blocking until a value is consumed.
```grimoire
task foo(c: channel<string>) {
	print(<-c);
}
event onLoad() {
	let c: channel<string>;
	foo(c);
	c <- "Hello World !";
}
```