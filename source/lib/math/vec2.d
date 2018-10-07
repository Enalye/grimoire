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
    grType_addPrimitive(&vec2_make, "vec2", ["x", "y"], [grFloat, grFloat], defVec2);
    grType_addCast(&vec2_typecast_fromArray, "ary", grArray, defVec2);
    grType_addCast(&vec2_typecast_toString, "v", defVec2, grString);

    grType_addOperator(&vec2_op_sub, "-", ["v1", "v2"], [defVec2, defVec2], defVec2);
    grType_addOperator(&vec2_op_div_f, "/", ["v", "f"], [defVec2, grFloat], defVec2);
}

private void vec2_make(GrCall call) {
    //Notify we don't change the stack state and return the parameters.
    call.hasResult = true;
}


private void vec2_typecast_fromArray(GrCall call) {
    const auto array = call.getArray("ary");
    if(array.length != 2)
        throw new Exception("No error fallback in typecast_n2vec2");
    call.setFloat(array[0].getFloat());
    call.setFloat(array[1].getFloat());
}

private void vec2_typecast_toString(GrCall call) {
   call.setString("vec2(" ~ to!dstring(call.getFloat("v.x"))
        ~ ", " ~ to!dstring(call.getFloat("v.y")) ~ ")");
}

private void vec2_op_sub(GrCall call) {
    auto v1x = call.getFloat("v1.x");
    auto v1y = call.getFloat("v1.y");
    auto v2x = call.getFloat("v2.x");
    auto v2y = call.getFloat("v1.y");
    call.setFloat(v1x - v2x);
    call.setFloat(v1y - v2y);
}

private void vec2_op_div_f(GrCall call) {
    auto vx = call.getFloat("v.x");
    auto vy = call.getFloat("v.y");
    auto f = call.getFloat("f");
    call.setFloat(vx / f);
    call.setFloat(vy / f);
}