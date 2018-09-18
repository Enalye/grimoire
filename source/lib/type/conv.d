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
	grLib_addPrimitive(&toStringi, "to_string", grString, [grInt]);
	grLib_addPrimitive(&toStringf, "to_string", grString, [grFloat]);
	grLib_addPrimitive(&toInta, "to_int", grInt, [grDynamic]);
	grLib_addPrimitive(&toAnyi, "to_any", grDynamic, [grInt]);
}

private void toStringi(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.istack[$ - 1]);
	coro.istack.length --;
}

private void toStringf(GrCoroutine coro) {
	coro.sstack ~= to!dstring(coro.fstack[$ - 1]);
	coro.fstack.length --;
}

private void toInta(GrCoroutine coro) {
	coro.istack ~= (coro.astack[$ - 1]).getInteger();
	coro.astack.length --;
}

private void toAnyi(GrCoroutine coro) {
	GrDynamicValue value;
	value.setInteger(coro.istack[$ - 1]);
	coro.astack ~= value;
	coro.istack.length --;
}
