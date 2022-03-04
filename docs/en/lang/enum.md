# Enumerations

Enumerations (or enum) are a set of named constants defined inside a single type.
They can only be compared between them and can't do any arithmetic operation.

## Definition

They are declared with the keyword enum:
```grimoire
enum Color {
	red;
	green;
	blue;
}
```

## Accessing a field

To access a value, just type the name of the enum with
the name of the field you want separated with a dot:
```grimoire
event onLoad() {
	Color myColor = Color.red;

	switch(myColor)
	case(Color.red) "The color is red !":print;
	case(Color.green) "The color is green !":print;
	case(Color.blue) "The color is blue !":print;
}
```