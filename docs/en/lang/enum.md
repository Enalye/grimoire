# Enumerations

Enumerations are a set of different alternatives that a sigle type can have.

```grimoire
enum Color {
	red;
	green;
	blue;
}
```

The fields of an enumeration all have an unique value.
```grimoire
event onLoad() {
	var myColor = Color.red;

	switch(myColor)
	case(Color.red) "The color is red !".print;
	case(Color.green) "The color is green !".print;
	case(Color.blue) "The color is blue !".print;
}
```