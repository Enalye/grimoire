/**
    Vec2 lib.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.math.vec2;

import std.conv: to;

import lib.api;

void grLib_std_math_vec2_load() {
    auto defVec2 = grType_addStructure("vec2", ["x", "y"], [grFloat, grFloat]);
    grType_addPrimitive(&vec2_make, "vec2", defVec2, [grFloat, grFloat]);
    grType_addCast(&vec2_typecast_fromArray, grArray, defVec2);
    grType_addCast(&vec2_typecast_toString, defVec2, grString);

    grType_addOperator(&vec2_op_sub1, "-", defVec2, [defVec2, defVec2]);
    grType_addOperator(&vec2_op_div2, "/", defVec2, [defVec2, grFloat]);
}

private void vec2_make(GrCoroutine coro) {}


private void vec2_typecast_fromArray(GrCoroutine coro) {
    const GrDynamicValue[]* array = &coro.nstack[$ - 1];
    if(array.length != 2)
        throw new Exception("No error fallback in typecast_n2vec2");
    coro.fstack ~= (*array)[0].getFloat();
    coro.fstack ~= (*array)[1].getFloat();
    coro.nstack.length --;
}

private void vec2_typecast_toString(GrCoroutine coro) {
    coro.sstack ~= "vec2(" ~ to!dstring(coro.fstack[$ - 2])
        ~ ", " ~ to!dstring(coro.fstack[$ - 1]) ~ ")";
    coro.fstack.length -= 2;
}

private void vec2_op_sub1(GrCoroutine coro) {
    coro.fstack[$ - 4] -= coro.fstack[$ - 2];
    coro.fstack[$ - 3] -= coro.fstack[$ - 1];
    coro.fstack.length -= 2;
}

private void vec2_op_div2(GrCoroutine coro) {
    coro.fstack[$ - 3] /= coro.fstack[$ - 1];
    coro.fstack[$ - 2] /= coro.fstack[$ - 1];
    coro.fstack.length --;
}