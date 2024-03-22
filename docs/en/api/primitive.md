# Primitive

Primitives added in `GrModuleDef` are defined as `void function(GrCall)`.

```grimoire
void myPrimitive(GrCall call) {

}
```

## Input parameters

A primitive fetches its parameters with `get` functions from `GrCall`, the index matches the order of the parameters.

```grimoire
void myPrimitive(GrCall call) {
    call.getInt(0) + call.getInt(1);
}
```

## Output parameters

Sams as `get` functions, we returns values with `set` functions from `GrCall`.
We are to call those the same order as its output parameters.

```grimoire
void myPrimitive(GrCall call) {
    call.setInt(12);
}
```

## Parameters' types

We can dynamically know the type of the parameters with `getInType` and `getOutType`.
Those parameters are in a mangled form (use `grUnmangle` to obtain a `GrType`).

```grimoire
void myPrimitive(GrCall call) {
    call.getInType(0);
    call.getOutType(0);
}
```

## Error handling

In case of error, we call `raise`. It's recommanded to exit the primitive and to not do any operation after `raise`.

```grimoire
void myPrimitive(GrCall call) {
    if(call.isNull(0)) {
        call.raise("Error");
        return;
    }
}
```