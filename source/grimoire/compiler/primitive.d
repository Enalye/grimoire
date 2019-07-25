/**
    Primitives are hard-coded grimoire's functions, they are used the same as any other function.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import grimoire.runtime;
import grimoire.compiler.parser;
import grimoire.compiler.type;
import grimoire.compiler.mangle;

/// All primitives, used for both the compiler and the runtime.
class GrPrimitivesDatabase {
    GrPrimitive[] primitives;
}

private {
    GrPrimitivesDatabase _primitivesDatabase;
}

void grInitPrimitivesDatabase() {
    _primitivesDatabase = new GrPrimitivesDatabase;
}

void grClosePrimitivesDatabase() {
    _primitivesDatabase = null;
}

GrPrimitivesDatabase grGetPrimitivesDatabase() {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    return _primitivesDatabase;
}

/**
    Primitive.
*/
class GrPrimitive {
	GrCallback callback;
	GrType[] inSignature;
	GrType[] outSignature;
    dstring[] parameters;
	dstring name, mangledName;
	uint index;
    bool isExplicit;
    GrCall callObject;

    //alias call = callObject.call;
}

/**
    Define a new primitive.
*/
GrPrimitive grAddPrimitive(GrCallback callback, dstring name, dstring[] parameters, GrType[] inSignature, GrType[] outSignature = []) {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    GrPrimitive primitive = new GrPrimitive;
    primitive.callback = callback;
    primitive.inSignature = inSignature;
    primitive.parameters = parameters;
    primitive.outSignature = outSignature;
    primitive.name = name;
    primitive.mangledName = grMangleNamedFunction(name, inSignature);
    primitive.index = cast(uint)_primitivesDatabase.primitives.length;
    primitive.callObject = new GrCall(primitive);
    _primitivesDatabase.primitives ~= primitive;
    return primitive;
}

/**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
*/
GrPrimitive grAddOperator(GrCallback callback, dstring name, dstring[] parameters, GrType[] inSignature, GrType outType) {
    if(inSignature.length > 2uL)
        throw new Exception("The operator \'" ~ to!string(name) ~ "\' cannot take more than 2 parameters: " ~ to!string(to!dstring(parameters)));
    return grAddPrimitive(callback, "@op_" ~ name, parameters, inSignature, [outType]);
}

/**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
*/
GrPrimitive grAddCast(GrCallback callback, dstring parameter, GrType srcType, GrType dstType, bool isExplicit = false) {
    auto primitive = grAddPrimitive(callback, "@as", [parameter], [srcType, dstType], [dstType]);
    primitive.isExplicit = isExplicit;
    return primitive;
}

bool grIsPrimitiveDeclared(dstring mangledName) {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    foreach(primitive; _primitivesDatabase.primitives) {
        if(primitive.mangledName == mangledName)
            return true;
    }
    return false;
}

GrPrimitive grGetPrimitive(dstring mangledName) {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    foreach(primitive; _primitivesDatabase.primitives) {
        if(primitive.mangledName == mangledName)
            return primitive;
    }
    throw new Exception("Undeclared primitive " ~ to!string(mangledName));
}

string grGetPrimitiveDisplayById(uint id, bool showParameters = false) {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    if(id >= _primitivesDatabase.primitives.length)
        throw new Exception("Invalid primitive id.");
    GrPrimitive primitive = _primitivesDatabase.primitives[id];
    
    string result = to!string(primitive.name);
    auto nbParameters = primitive.inSignature.length;
    if(primitive.name == "@as")
        nbParameters = 1;
    result ~= "(";
    for(int i; i < nbParameters; i ++) {
        result ~= grGetPrettyType(primitive.inSignature[i]);
        if(showParameters)
            result ~= " " ~ to!string(primitive.parameters[i]);
        if((i + 2) <= nbParameters)
            result ~= ", ";
    }
    result ~= ")";
    for(int i; i < primitive.outSignature.length; i ++) {
        result ~= i ? ", " : " ";
        result ~= grGetPrettyType(primitive.outSignature[i]);
    }
    return result;
}

void grResolvePrimitiveSignature() {
    if(!_primitivesDatabase)
        throw new Exception("Primitives database not initialized");
    foreach(primitive; _primitivesDatabase.primitives) {
        primitive.callObject.setup();
    }
}