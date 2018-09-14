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

module script.std.all;

import std.exception;
import std.conv;
import std.stdio;

import script.parser;
import script.vm;
import script.coroutine;
import script.any;
import script.array;
import script.type;
import script.mangle;
import script.primitive;
import script.std.vec2;

bool isLoaded = false;

void loadStandardLibrary() {
	bindPrimitive(&prints, "print", sVoidType, [sStringType]);
	bindPrimitive(&printb, "print", sVoidType, [sBoolType]);
	bindPrimitive(&printi, "print", sVoidType, [sIntType]);
	bindPrimitive(&printf, "print", sVoidType, [sFloatType]);
	bindPrimitive(&printa, "print", sVoidType, [sAnyType]);
	bindPrimitive(&printn, "print", sVoidType, [sArrayType]);
	bindPrimitive(&toStringi, "to_string", sStringType, [sIntType]);
	bindPrimitive(&toStringf, "to_string", sStringType, [sFloatType]);
	bindPrimitive(&toInta, "to_int", sIntType, [sAnyType]);
	bindPrimitive(&toAnyi, "to_any", sAnyType, [sIntType]);

    bindOperator(&opTest, "+", sFloatType, [sIntType, sFloatType]);
    loadVec2Library();
	isLoaded = true;
}

void opTest(Coroutine coro) {
    coro.fstack[$ - 1] = coro.fstack[$ - 1] + cast(float)coro.istack[$ - 1];
}

void prints(Coroutine coro) {
	writeln(coro.sstack[$ - 1]);
	coro.sstack.length --;
}

void printb(Coroutine coro) {
	writeln(coro.istack[$ - 1] ? "true" : "false");
	coro.istack.length --;
}

void printi(Coroutine coro) {
	writeln(coro.istack[$ - 1]);
	coro.istack.length --;
}

void printf(Coroutine coro) {
	writeln(coro.fstack[$ - 1]);
	coro.fstack.length --;
}

void printa(Coroutine coro) {
	writeln(coro.astack[$ - 1].getString());
	coro.astack.length --;
}

void printn(Coroutine coro) {
    string result = "[";
    int i;
    foreach(value; coro.nstack[$ - 1]) {
        result ~= to!string(value.getString());
        if((i + 2) <= coro.nstack[$ - 1].length)
            result ~= ", ";
        i ++;
    }
    result ~= "]";
    writeln(result); 
	coro.nstack.length --;
}

void toStringi(Coroutine coro) {
	coro.sstack ~= to!dstring(coro.istack[$ - 1]);
	coro.istack.length --;
}

void toStringf(Coroutine coro) {
	coro.sstack ~= to!dstring(coro.fstack[$ - 1]);
	coro.fstack.length --;
}

void toInta(Coroutine coro) {
	coro.istack ~= (coro.astack[$ - 1]).getInteger();
	coro.astack.length --;
}

void toAnyi(Coroutine coro) {
	AnyValue value;
	value.setInteger(coro.istack[$ - 1]);
	coro.astack ~= value;
	coro.istack.length --;
}
