/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
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

class GrPrimitive {
	void function(GrCoroutine) callback;
	GrType[] signature;
	GrType returnType;
	dstring name, mangledName;
	uint index;
}

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