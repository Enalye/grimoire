# Classes

Classes are types that can hold fields of different types.

## Definition

Declaration is made with the `class` keyword.
```grimoire
class MyClass {
    int foo;
    string bar;
}
```

## New

To create an instance of that class (i.e. an object), you use the `new` keyword followed by the class type.
```grimoire
MyClass obj = new MyClass;
```

By default, all fields will be initialized with its default value, to change that, you need to use the constructor notation.

```grimoire
MyClass obj = new MyClass {
	foo = 5;
	bar = "Hello";
};
```
Unspecified fields in the constructor will still be initialized by default.

## Accessing a field

To access a field, use the `.` notation.
```grimoire
obj.foo = 5;
obj.bar = "Hello";
print(obj.bar);
```

By default, all fields are only visible to the file that declared it.
To make them visible to all files, you need to specify them as public with the "public" keyword:
```grimoire
class A {
	public int a; // Visible globally
	int b; // Visible only to the current file
}
```

## Null

An uninitialized class variable will be initialized to null.

Like native types, you can assign "null" to a class type variable.

```grimoire
MyClass obj = null;
if(!obj)
	"Obj is null":print;
```

Trying to access a null object's field will raise an error.

## Inheritance

You can inherit fields from another class:
```grimoire
class MyClass : ParentClass {

}
```

## Template

In grimoire, you can define generic types for classes like this:
```grimoire
class MyClass<T, A> : ParentClass<T, int> {
	T myValue;
	A myOtherValue;
}
```