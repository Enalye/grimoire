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

module lib.io.print;

import std.stdio: write, writeln;
import std.conv: to;
import lib.api;

void grLib_std_io_print_load() {
	grLib_addPrimitive(&prints, "print", grVoid, [grString]);
	grLib_addPrimitive(&printb, "print", grVoid, [grBool]);
	grLib_addPrimitive(&printi, "print", grVoid, [grInt]);
	grLib_addPrimitive(&printf, "print", grVoid, [grFloat]);
	grLib_addPrimitive(&printa, "print", grVoid, [grDynamic]);
	grLib_addPrimitive(&printn, "print", grVoid, [grArray]);
}

private void prints(GrCoroutine coro) {
	writeln(coro.sstack[$ - 1]);
	coro.sstack.length --;
}

private void printb(GrCoroutine coro) {
	writeln(coro.istack[$ - 1] ? "true" : "false");
	coro.istack.length --;
}

private void printi(GrCoroutine coro) {
	writeln(coro.istack[$ - 1]);
	coro.istack.length --;
}

private void printf(GrCoroutine coro) {
	writeln(coro.fstack[$ - 1]);
	coro.fstack.length --;
}

private void printa(GrCoroutine coro) {
	writeln(coro.astack[$ - 1].getString());
	coro.astack.length --;
}

private void printn(GrCoroutine coro) {
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