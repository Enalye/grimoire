/**
    Conv lib.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.type.conv;

import std.conv;
import lib.api;

void grLib_std_type_conv_load() {
    grLib_addCast(&conv_f2i, grFloat, grInt);
    grLib_addCast(&conv_i2f, grInt, grFloat);
	grLib_addCast(&conv_i2s, grString, grInt);
	grLib_addCast(&conv_f2s, grString, grFloat);
}

private void conv_f2i(GrCoroutine coro) {
    coro.istack ~= to!int(coro.fstack[$ - 1]);
    coro.fstack.length --;
}

private void conv_i2f(GrCoroutine coro) {
    coro.fstack ~= to!float(coro.istack[$ - 1]);
    coro.istack.length --;
}

private void conv_i2s(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.istack[$ - 1]);
	coro.istack.length --;
}

private void conv_f2s(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.fstack[$ - 1]);
	coro.fstack.length --;
}