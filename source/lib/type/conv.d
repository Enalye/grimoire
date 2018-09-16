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
