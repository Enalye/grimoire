# Alias de type

Un alias de type permet à un type de prendre un nom différent, permettant de raccourcir des signatures trop longues.

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