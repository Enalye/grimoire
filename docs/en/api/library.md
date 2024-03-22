# Bibliothèques

New definitions are added through a library `GrModuleDef`.

```d
GrModuleDef library = new GrModuleDef;
```

* * *

## Variables

`addVariable()` declares global variables.

```d
library.addVariable("PI", grConst(grFloat), 3.141592); 
```

Those variables become accessible during the execution of the virtual machine.

```d
GrFloat pi = engine.getFloatVariable("PI");
engine.setFloatVariable("PI", 3.0);
```

* * *

## Functions

`addFunction()` defines new functions.

```d
library.addFunction(&multiply, "multiply", [grFloat, grFloat], [grFloat]);
```

The first parameter is a callback for a function of type `void function(GrCall)`.

```d
void multiply(GrCall call) {
	GrFloat valeur1 = call.getFloat(0);
	GrFloat valeur2 = call.getFloat(1);
    call.setFloat(valeur1 * valeur2);
}
```

`addCast` defines new type conversions.

```d
library.addCast(&myConv, grBool, grString);

void myConv(GrCall call) {
    GrBool valeur = call.getBool(0);
    call.setString(valeur ? "true" : "false");
}
```

`addOperator` overrides an operator.

```d
library.addOperator(&add, GrModuleDef.Operator.add, [grFloat, grInt], grFloat);
// Or
library.addOperator(&add, "+", [grFloat, grInt], grFloat);

void add(GrCall call) {
    call.setFloat(call.getFloat(0) + cast(GrFloat) call.getInt(1));
}
```
> ***Important:***
Note that if a default operation exists, it'll use that instead.

`addConstructor` defines a constructor for a class or a native.

```d
library.addConstructor(&myType_ctor, myType);

void myType_ctor(GrCall call) {
    call.setNative(new MyType());
}
```
> ***Important:***
A constructor must always returns the type it defines.

`addStatic` defines a static methode for a class or a native.

```d
library.addStatic(&myType_foo, myType, "foo");

void myType_foo(GrCall call) {
}
```

### Genericity

`grAny()` is a placeholder for a generic type.

```d
library.addFunction(&_push, "push",
    [grList(grAny("T")), grAny("T")],
	[grAny("T")]);
```
This code corresponds to:
```grimoire
func<T> push(a: list<T>, b: T) (T) {}
```
Constraints can also restrict the type.
```d
library.addFunction(&_print_class, "print",
    [grPure(grAny("T"))], [],
    [grConstraint("Class", grAny("T"))]);
```

`addConstraint` defines a new constraint.

```grimoire
library.addConstraint(&equals, "Equals", 1);

bool equals(GrData, GrType type, const GrType[] types) {
    return type == types[0];
}
```

* * *

## Classes

We declare a class with the method `addClass()`.
```d
library.addClass("MyClass", ["foo", "bar"], [grInt, grString]);
```

Other optional parameters exist to describe inheritance and genericity.
```d
library.addClass("MyClass", [], [], ["T"], "ParentClass", [grAny("T")]);
```

Instancating a class is done with `createObject()` on GrCall or GrEngine.
```d
GrObject obj = call.createObject("MyClass");
GrInt valeur = obj.getInt("foo");
obj.setString("bar", "Hello");
```

* * *

## Natives

Natives are opaque types, they allow Grimoire to have access to arbitrary binary types.
```d
library.addNative("MyType");
```

Like classes, they can inherit from another native type.
```d
library.addNative("MyType", [], "ParentType", []);
```

Like classes, they can have generic types
```d
library.addNative("MyType", ["T"], "ParentType", [grAny("T")]);
```

Natives can expose properties with `addProperty`, similar to a class' fields.
```d
library.addProperty(&getter, &setter, "myValue", myNativeType, grInt);

void getter(GrCall call) {
    MyType myType = call.getNative!MyType(0);
    call.setInt(myType.myValue);
}

void setter(GrCall call) {
    MyType myType = call.getNative!MyType(0);
    myType.myValue = call.getInt(1);
    call.setInt(myType.myValue);
}
```
The `setter` is optional, its absence make the property as if it was constant.

* * *

## Enumerations

Enumeration are defined with `addEnum()`.
```d
library.addEnum("Color", ["red", "green", "blue"]);
```

* * *

## Alias

Type aliases are declared with `addAlias`.
```d
library.addAlias("MyInteger", grInt);
```