# Conditions

`if` and `unless` allow a portion of code to be run only under some conditions.
```grimoire
var a = 5;

if(a < 2)
    print("a is less than 2 !");

unless(a < 2)
    print("a is at least 2 !");
```
Conditions can be chained with `else`.
```grimoire
var a = 5;

if(a > 10)
    print("a is more than 10");
else if(a >= 5)
    print("a is at least 5 but no more than 10");
else unless(i < 2)
    print("a is at least 2, but less than 5");
else
    print("a is less than 2");
```

## Switch

`switch` tries to match a value with all possible case.
```grimoire
var i = "Hello";

switch(i)
default
	print("I don't know what he said");
case("Hey")
	print("He said hey");
case("Hello")
	print("He said hello");
```

Contrary to `if` statement, cases can be put in any order.

## Select

`select` executes the first non-blocking operation.
```grimoire
select
case(value = <- myChannel) {
	print("Received " ~ value);
}
case(myOtherChannel <- "Hello") {
	print("Sent Hello");
}
```

The `default` block is run if every case is blocking.
If it's missing, `select` becomes a blocking operation.
```grimoire
select
case(value = <- myChannel) {
	print("Received " ~ value);
}
case(myOtherChannel <- "Hello") {
	print("Sent Hello");
}
default {
	print("Nothing is happening");
}
```