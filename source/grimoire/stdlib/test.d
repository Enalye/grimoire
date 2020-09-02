/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.test;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib)
void grLoadStdLibTest(GrData data) {
	data.addPrimitive(&_assert, "assert", ["value"], [grBool]);
	data.addPrimitive(&_assert_msg, "assert", ["value", "msg"], [grBool, grString]);
}

private void _assert(GrCall call) {
    const bool value = call.getBool("value");
    if(!value)
        call.raise("Assertion Failure");
}

private void _assert_msg(GrCall call) {
    const bool value = call.getBool("value");
    if(!value)
        call.raise(call.getString("msg"));
}