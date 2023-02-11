# Alias
An alias allow types to be called by a different name.
```grimoire
func square(i: int) (int) {
	return i * i;
};

alias MyFunc = func(int) (int);

event onLoad() {
    MyFunc myFunc = &<MyFunc> square;
	10.myFunc.print;
}
```