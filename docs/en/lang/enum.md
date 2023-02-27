# Enumerations

Enumerations are a set of different alternatives that a sigle type can have.

```grimoire
enum Color {
	red;
	green;
	blue;
}
```

By default, the fields of an enumeration are assigned the value of the previous field + 1.
```grimoire
event onLoad() {
	var myColor = Color.red;

	switch(myColor)
	case(Color.red) "The color is red !".print;
	case(Color.green) "The color is green !".print;
	case(Color.blue) "The color is blue !".print;
}
```

We can change the value of a field.
```grimoire
enum Color {
    white = -1;   //-1
	red;          //0
	green;        //1
	blue = 5;     //5
	orange;       //6
}
```
> ***Note:***
The value must be a literal integer.