/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.math;

import std.random, std.math;
import std.algorithm.comparison : clamp;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibMath(GrLibrary library) {
    library.addPrimitive(&_clamp, "clamp", [grFloat, grFloat, grFloat], [
            grFloat
            ]);
    library.addPrimitive(&_random01, "rand", [], [grFloat]);
    library.addPrimitive(&_randomf, "rand", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_randomi, "rand", [grInt, grInt], [grInt]);
    library.addPrimitive(&_cos, "cos", [grFloat], [grFloat]);
    library.addPrimitive(&_sin, "sin", [grFloat], [grFloat]);
    library.addPrimitive(&_sqrt, "sqrt", [grFloat], [grFloat]);
    library.addPrimitive(&_lerp, "lerp", [grFloat, grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_rlerp, "rlerp", [grFloat, grFloat, grFloat], [
            grFloat
            ]);
}

private void _clamp(GrCall call) {
    call.setFloat(clamp(call.getFloat(0), call.getFloat(1), call.getFloat(2)));
}

private void _random01(GrCall call) {
    call.setFloat(uniform01());
}

private void _randomf(GrCall call) {
    call.setFloat(uniform!"[]"(call.getFloat(0), call.getFloat(1)));
}

private void _randomi(GrCall call) {
    call.setInt(uniform!"[]"(call.getInt(0), call.getInt(1)));
}

private void _cos(GrCall call) {
    call.setFloat(cos(call.getFloat(0)));
}

private void _sin(GrCall call) {
    call.setFloat(sin(call.getFloat(0)));
}

private void _sqrt(GrCall call) {
    call.setFloat(sqrt(call.getFloat(0)));
}

private void _lerp(GrCall call) {
    const float a = call.getFloat(0);
    const float b = call.getFloat(1);
    const float t = call.getFloat(2);
    call.setFloat(t * b + (1f - t) * a);
}

private void _rlerp(GrCall call) {
    const float a = call.getFloat(0);
    const float b = call.getFloat(1);
    const float v = call.getFloat(2);
    if ((b - a) == 0f) {
        call.setFloat(0f);
        return;
    }
    call.setFloat((v - a) / (b - a));
}
