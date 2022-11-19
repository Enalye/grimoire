# API Implementation

Everything you need to declare new types and values is contained in a GrLibrary.
```d
GrLibrary library = new GrLibrary;
//Then add your types inside lib
```

After creating a GrLibrary and adding your custom types inside it, add it to your compiler before compilation.
```d
compiler.addLibrary(library);
```

Then, add it to your runtime.
```d
engine.addLibrary(library);
```

**Important:** All the libraries must be included in both the compiler **and** the engine and in the **same order**

* * *

## Variables API

You can declare global variables from a library using addVariable():
```d
library.addVariable("pi", grFloat, 3.141592f, true); 
```

To access the variable in runtime, you can use the getXVariable() of GrCall or GrEngine:
```d
float value = engine.getFloatVariable("PI");
```

To modify it, use the setXVariable() ones:
```d
engine.setFloatVariable("PI", 3f);
```

* * *

## Primitives API

In this language, a primitive is a function declared in D accessible from a script.
`print` for instance, is a primitive.

They must be declared before the compilation and remain unchanged in the VM.

* * *

### Primitive declaration

To declare your primitive use `addFunction`.
This function takes a callback to your primitive, the name which your primitive will be known as inside scripts,
the parameters and, optionally, the return types.
Exemple:
```d
//A function print that takes a string and returns nothing
library.addFunction(&print_a_string, "print", [grString]);
//Function mul() that takes 2 floats and returns one.
library.addFunction(&multiply, "mul", [grFloat, grFloat], [grFloat]);
```

* * *

### Implementing the primitive

The callback takes a GrCall object and return nothing.
The GrCall object contains everything you need about the current running context.

It looks like this:
```d
void myPrimitive(GrCall call) {
	writeln(call.getFloat(0));
    call.setInt(99);
}
```
Here, the primitive takes a float parameter at index 0 (first parameter), and prints it, then returns the int value 99.
getXXX methods fetch the parameters, the type must match the declaration, else they'll throw an exception.
setXXX methods returns a value on the stack, beware of the order in which you call setXXX functions.

* * *

### Applying genericity to a primitive

Grimoire provide a way to declare a primitive with generic types with `grAny`.
*grAny* takes two arguments:
- The name of the generic type,
- A predicate that checks if the provided type is correct.

The predicate takes 2 parameters:
- A `GrType` of the provided value,
- The context of the checker containing the defined generic types.

Exemple of a primitive that can define a `push` function for every type of list that uses integers.
It takes an list and a value that matches the type held by the list, and returns the list itself.
```d
library.addFunction(&_push, "push", [
    grAny("A",   // We declare a generic type called "A"
	(type, data) {
		if (type.baseType != GrType.Base.list) // This type must be an list
			return false;
		const GrType subType = grUnmangle(type.mangledType); // The subType is mangled
		data.set("T", subType);  // We define the other generic type (called "T") with the subtype of the list
		return grIsKindOfInt(subType.baseType); // We check is the baseType is good for us.
	}), grAny("T")], // "T" is already defined above, so the types must match.
	[grAny("A")]   // "A" is already defined above, it must be of the same type. Putting any predicate here is useless.
);
```

If no predicate is given to a *grAny*, the type is always validated.
The predicate of return types won't be checked, only the input signature is validated.

* * *

### Casting API

You can define a cast function inside a library
```d
library.addCast(&myCast, myObjType, grString);
```

Then, define the function itself:
```d
void myCast(GrCall call) {
    auto myObj = call.getObject(0);
    call.setString("Hello");
}
```

* * *

### Operators API

Like addCast, but using addOperator instead.
```d
library.addOperator(&myOperator, GrLibrary.Operator.add, [grFloat, grInt], grFloat);
// Or
library.addOperator(&myOperator, "+", [grFloat, grInt], grFloat);
```

Then writing the function itself.
```d
void myOperator(GrCall call) {
    call.setFloat(call.getFloat(0) + cast(int) call.getInt(1));
}
```

Note that if a default operation exists, it'll be used instead,
so overloading a `+` operator between 2 integers is going to be ignored.

* * *

## Classes API

You declare a class by calling addClass() from the GrLibrary:
```d
library.addClass("MyClass", ["foo", "bar"], [grInt, grString]);
```

There are more optional parameters for inheritance and templating:
```d
library.addClass("MyClass", [], [], ["T"], "ParentClass", [grAny("T")]);
```
This is equal to MyClass<T> inheriting from ParentClass<T>.
The `grAny("T")` ensures that the template variable "T" from MyClass is used for the parent class.

Instanciating a class is done with `createObject()` from GrCall or GrEngine:
```d
GrObject obj = call.createObject("MyClass");
```

You can then set or get fields from the GrObject with their respective set/get methods:
```d
obj.setInt("foo", 5);
string value = obj.getString("bar");
```

* * *

## Type Aliases API

Type aliases can be declared by calling `addAlias` from GrLibrary:
```d
library.addAlias("MyInt", grInt);
```

* * *

## Native types API

Native types are opaque pointers used by D, grimoire doesn't have access to their content.
As such, they can only be declared from D.
```d
library.addNative("MyType");
```

Like classes, they can inherit from another native type.
```d
library.addNative("MyType", [], "ParentType", []);
```

The second and fourth parameters are the template variable of the defined and the parent class.
```d
library.addNative("MyType", ["T"], "ParentType", [grAny("T")]);
```
Roughly means that MyType<T> inherits from ParentType<T>

* * *

## Enumerations API

Enums can be created by calling `addEnum` from GrLibrary:
```d
library.addEnum("Color", ["red", "green", "blue"]);
```