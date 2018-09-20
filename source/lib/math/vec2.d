/**
    Vec2 lib.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module lib.math.vec2;

import lib.api;

void grLib_std_math_vec2_load() {
    auto defVec2 = grType_addStructure("vec2", ["x", "y"], [grFloat, grFloat]);
    grType_addPrimitive(&makeVec2, "vec2", defVec2, [grFloat, grFloat]);
    grType_addCast(&typecast_n2vec2, grArray, defVec2);
}

private void makeVec2(GrCoroutine coro) {}


private void typecast_n2vec2(GrCoroutine coro) {
    const GrDynamicValue[]* array = &coro.nstack[$ - 1];
    if(array.length != 2)
        throw new Exception("No error fallback in typecast_n2vec2");
    coro.fstack ~= (*array)[0].getFloat();
    coro.fstack ~= (*array)[1].getFloat();
    coro.nstack.length --;
}