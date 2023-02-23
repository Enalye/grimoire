# Classes

Classes are types that can hold fields of different types.
Unlike many programming languages, classes in Grimoire contain no methods.

```grimoire
class Animal {
    var name: string;
    var numberOfLegs: int;
    var speed: float;
}
```

A class is instanciated with the `@` operator.
```grimoire
var doggo = @Animal {};
```
A class doesn't have a default value, it must then be initialised.
```grimoire
var doggo: Animal; // Compilation error
```

Initialisation of a class's fields is done between curly braces `{}`.
```grimoire
Animal doggo = @Animal {
	name = "Rex";
	numberOfLegs = 4;
    speed = 30f;
};
```
An uninitialised field will be initialised with its default value.
If it doesn't have one, a compilation error will occur.

## Constructor

The creation of an object can be done with a constructor.
```grimoire
event main() {
    var doggo = @Animal("Rex");
}

func @Animal(name: string) (Animal) {
    return @Animal {
        name = name;
        numberOfLegs = 4;
        speed = 30f;
    };
}
```

> ***Important:***
A constructor without parameters becomes automatically the class default value.

## Static method

Static methods are functions that are owned by a type.
```grimoire
func @Animal.bark() (string) {
    return "woof !";
}

var x = @Animal.bark();
```

## Specialization

A class can inherit another.
```grimoire
class Dog : Animal {
    var typeOfDog: string;
}
```
It'll have all the fields of the parent class and can be used instead of the parent class (polymorphism).
```grimoire
Animal animal = @Dog {};
```

## Genericity

Classes can use placeholder types that'll be defined later.
```grimoire
class MyClass<T, A> : ParentClass<T, int> {
	var myValue: T;
	var myOtherValue: A;
}

var x: MyClass<int, string> = @MyClass<int, string> {};
```

## Accessing a field

The `.` operator let us access a class field.
```grimoire
doggo.speed = 12.7;
doggo.name = "Rex";
print(doggo.name);
```

By default, all fields are only visible to the file that declared it.
To make them visible from other files, you need to export them with the `export` keyword:
```grimoire
class A {
	export var a: int; // Visible globally
	var b: int; // Visible only to the current file
}
```