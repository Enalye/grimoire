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
    library.addVariable("pi", grFloat, PI, true);

    library.addPrimitive(&_min_f, "min", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_min_i, "min", [grInt, grInt], [grInt]);
    library.addPrimitive(&_max_f, "max", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_max_i, "max", [grInt, grInt], [grInt]);

    library.addPrimitive(&_clamp, "clamp", [grFloat, grFloat, grFloat], [
            grFloat
            ]);

    library.addPrimitive(&_random01, "rand", [], [grFloat]);
    library.addPrimitive(&_random_f, "rand", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_random_i, "rand", [grInt, grInt], [grInt]);

    library.addPrimitive(&_cos, "cos", [grFloat], [grFloat]);
    library.addPrimitive(&_sin, "sin", [grFloat], [grFloat]);
    library.addPrimitive(&_tan, "tan", [grFloat], [grFloat]);
    library.addPrimitive(&_acos, "acos", [grFloat], [grFloat]);
    library.addPrimitive(&_asin, "asin", [grFloat], [grFloat]);
    library.addPrimitive(&_atan, "atan", [grFloat], [grFloat]);
    library.addPrimitive(&_atan2, "atan2", [grFloat, grFloat], [grFloat]);

    library.addPrimitive(&_exp, "exp", [grFloat], [grFloat]);
    library.addPrimitive(&_sqrt, "sqrt", [grFloat], [grFloat]);
    library.addPrimitive(&_pow, "pow", [grFloat, grFloat], [grFloat]);

    library.addPrimitive(&_lerp, "lerp", [grFloat, grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_rlerp, "rlerp", [grFloat, grFloat, grFloat], [
            grFloat
            ]);

    library.addPrimitive(&_abs_i, "abs", [grInt], [grInt]);
    library.addPrimitive(&_abs_f, "abs", [grFloat], [grFloat]);
    library.addPrimitive(&_floor, "floor", [grFloat], [grFloat]);
    library.addPrimitive(&_ceil, "ceil", [grFloat], [grFloat]);
    library.addPrimitive(&_round, "round", [grFloat], [grFloat]);
    library.addPrimitive(&_truncate, "truncate", [grFloat], [grFloat]);
    library.addPrimitive(&_positive_i, "positive?", [grInt], [grBool]);
    library.addPrimitive(&_positive_f, "positive?", [grFloat], [grBool]);
    library.addPrimitive(&_negative_i, "negative?", [grInt], [grBool]);
    library.addPrimitive(&_negative_f, "negative?", [grFloat], [grBool]);
    library.addPrimitive(&_zero_i, "zero?", [grInt], [grBool]);
    library.addPrimitive(&_zero_f, "zero?", [grFloat], [grBool]);
    library.addPrimitive(&_nan, "nan?", [grFloat], [grBool]);
    library.addPrimitive(&_even, "even?", [grInt], [grBool]);
    library.addPrimitive(&_odd, "odd?", [grInt], [grBool]);
}

private void _min_f(GrCall call) {
    const float a = call.getFloat(0);
    const float b = call.getFloat(1);
    call.setFloat(a < b ? a : b);
}

private void _min_i(GrCall call) {
    const int a = call.getInt(0);
    const int b = call.getInt(1);
    call.setInt(a < b ? a : b);
}

private void _max_f(GrCall call) {
    const float a = call.getFloat(0);
    const float b = call.getFloat(1);
    call.setFloat(a > b ? a : b);
}

private void _max_i(GrCall call) {
    const int a = call.getInt(0);
    const int b = call.getInt(1);
    call.setInt(a > b ? a : b);
}

private void _clamp(GrCall call) {
    call.setFloat(clamp(call.getFloat(0), call.getFloat(1), call.getFloat(2)));
}

private void _random01(GrCall call) {
    call.setFloat(uniform01());
}

private void _random_f(GrCall call) {
    call.setFloat(uniform!"[]"(call.getFloat(0), call.getFloat(1)));
}

private void _random_i(GrCall call) {
    call.setInt(uniform!"[]"(call.getInt(0), call.getInt(1)));
}

private void _cos(GrCall call) {
    call.setFloat(cos(call.getFloat(0)));
}

private void _sin(GrCall call) {
    call.setFloat(sin(call.getFloat(0)));
}

private void _tan(GrCall call) {
    call.setFloat(tan(call.getFloat(0)));
}

private void _acos(GrCall call) {
    call.setFloat(acos(call.getFloat(0)));
}

private void _asin(GrCall call) {
    call.setFloat(asin(call.getFloat(0)));
}

private void _atan(GrCall call) {
    call.setFloat(atan(call.getFloat(0)));
}

private void _atan2(GrCall call) {
    call.setFloat(atan2(call.getFloat(0), call.getFloat(1)));
}

private void _exp(GrCall call) {
    call.setFloat(exp(call.getFloat(0)));
}

private void _sqrt(GrCall call) {
    call.setFloat(sqrt(call.getFloat(0)));
}

private void _pow(GrCall call) {
    call.setFloat(pow(call.getFloat(0), call.getFloat(1)));
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

private void _abs_i(GrCall call) {
    call.setInt(abs(call.getInt(0)));
}

private void _abs_f(GrCall call) {
    call.setFloat(abs(call.getFloat(0)));
}

private void _floor(GrCall call) {
    call.setFloat(floor(call.getFloat(0)));
}

private void _ceil(GrCall call) {
    call.setFloat(ceil(call.getFloat(0)));
}

private void _round(GrCall call) {
    call.setFloat(round(call.getFloat(0)));
}

private void _truncate(GrCall call) {
    call.setFloat(trunc(call.getFloat(0)));
}

private void _positive_i(GrCall call) {
    call.setBool(call.getInt(0) > 0);
}

private void _positive_f(GrCall call) {
    call.setBool(call.getFloat(0) > 0);
}

private void _negative_i(GrCall call) {
    call.setBool(call.getInt(0) < 0);
}

private void _negative_f(GrCall call) {
    call.setBool(call.getFloat(0) < 0);
}

private void _zero_i(GrCall call) {
    call.setBool(call.getInt(0) == 0);
}

private void _zero_f(GrCall call) {
    call.setBool(call.getFloat(0) == 0);
}

private void _nan(GrCall call) {
    call.setBool(isNaN(call.getFloat(0)));
}

private void _even(GrCall call) {
    call.setBool(!(call.getInt(0) & 0x1));
}

private void _odd(GrCall call) {
    call.setBool(call.getInt(0) & 0x1);
}
