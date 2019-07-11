module grimoire.lib.test.assertion;

import grimoire;

static this() {
	grAddPrimitive(&_assert, "assert", ["value"], [grBool]);
	grAddPrimitive(&_assert_msg, "assert", ["value", "msg"], [grBool, grString]);
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