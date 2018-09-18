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
}

private void makeVec2(GrCoroutine coro) {}
