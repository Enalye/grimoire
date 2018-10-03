/**
    Explicit typecast library.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.type.typecast;

import std.conv;
import lib.api;

void grLib_std_type_typecast_load() {
    //As int
    grLib_addCast(&typecast_f2i, grFloat, grInt, true);
    grLib_addCast(&typecast_b2i, grBool, grInt);

    //As float
    grLib_addCast(&typecast_i2f, grInt, grFloat, true);

    //As bool

    //As Array


    //As string
	grLib_addCast(&typecast_i2s, grInt, grString);
	grLib_addCast(&typecast_f2s, grFloat, grString);
}

//As int
private void typecast_f2i(GrCoroutine coro) {
    coro.istack ~= to!int(coro.fstack[$ - 1]);
    coro.fstack.length --;
}

private void typecast_b2i(GrCoroutine coro) {}

//As float
private void typecast_i2f(GrCoroutine coro) {
    coro.fstack ~= to!float(coro.istack[$ - 1]);
    coro.istack.length --;
}

//As bool


//As array


//As string
private void typecast_i2s(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.istack[$ - 1]);
	coro.istack.length --;
}

private void typecast_f2s(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.fstack[$ - 1]);
	coro.fstack.length --;
}