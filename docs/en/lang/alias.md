# Type Aliases

A type alias allow types to be named differently, making long signatures shorter.

```grimoire
function square(int i) (int) {
	return i * i;
};

alias MyFunc = function(int) (int);

event onLoad() {
    MyFunc myFunc = &(MyFunc) square;
	10:myFunc:print;
}
```