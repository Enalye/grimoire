##### [Prev: Deferring](defer.md)
##### [Main Page](index.md)

# Custom Primitives

## What's a primitive

In this language, a primitive is a function declared in D accessible from a script.
`print` for instance, is a primitive.

They must be declared before the compilation anb remain unchanged in the VM.

## Primitive declaration

To declare your primitive use `grAddPrimitive`.
This function takes a callback to your primitive, the name which your primitive will be known as in scripts,
an array of parameters' name, the parameters' type and, optionally, an array of return value types.
Exemple:
```cpp
//A function print that takes a string and returns nothing
grAddPrimitive(&print_a_string, "print", ["value"], [grString]);
//Function mul() that takes 2 floats and returns one.
grAddPrimitive(&multiply, "mul", ["a", "b"], [grFloat, grFloat], [grFloat]);
```

If you want to multiply 2 things, a better idea is to declare an operator (if it doesn't already exists for your types):

```cpp
grAddOperator(&multiply, "*", ["a", "b"], [grFloat, grFloat], grFloat);
```
An operator declaration only take the name of the operator it surcharges, 1 or 2 parameters, and a single return type.

But if you want to convert from one type to another using a primitive, you can do so with this function:
```cpp
grAddCast(&cast_float_to_int, "value", grFloat, grInt);
```
Much simpler, it takes a single parameter and return value.

## The primitive itself

The callback takes a GrCall object and return nothing.
The GrCall object contains everything you need about the current running context.

It looks like this:
```cpp
void myPrimitive(GrCall call) {
	writeln(call.getFloat("value"));
    call.setInt(99);
}
```
Here, the primitive takes a float parameter called `"value"`, and prints it, then returns the int value 99.
getXXX methods fetch the parameters, they have the same name/type as declared, else it will throw an exception.
setXXX methods returns a value on the stack, beware of the order in which you call setXXX functions.


# Navigation

##### [Prev: Deferring](defer.md)
##### [Main Page](index.md)
