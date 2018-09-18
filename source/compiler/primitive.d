/**
    Primitives are hard-coded grimoire's functions, they are used the same as any other function.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import runtime.all;
import compiler.parser;
import compiler.type;
import compiler.mangle;


GrPrimitive[] primitives;

/**
    Primitive.
*/
class GrPrimitive {
	void function(GrCoroutine) callback;
	GrType[] signature;
	GrType returnType;
	dstring name, mangledName;
	uint index;
}

/**
    Define a new primitive.
*/
void grType_addPrimitive(void function(GrCoroutine) callback, dstring name, GrType retType, GrType[] signature) {
	GrPrimitive primitive = new GrPrimitive;
	primitive.callback = callback;
	primitive.signature = signature;
	primitive.returnType = retType;
	primitive.name = name;
	primitive.mangledName = grType_mangleNamedFunction(name, signature);
	primitive.index = cast(uint)primitives.length;
	primitives ~= primitive;
}

/**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
*/
void grType_addOperator(void function(GrCoroutine) callback, dstring name, GrType retType, GrType[] signature) {
	grType_addPrimitive(callback, "@op_" ~ name, retType, signature);
}

bool isPrimitiveDeclared(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return true;
	}
	return false;
}

GrPrimitive grType_getPrimitive(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return primitive;
	}
	throw new Exception("Undeclared primitive " ~ to!string(mangledName));
}