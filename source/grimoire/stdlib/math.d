/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.math;

import std.random, std.math;
import std.algorithm.comparison : clamp;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibMath(GrLibrary library) {
    library.addVariable("PI", grReal, PI, true);

    library.addFunction(&_min_f, "min", [grReal, grReal], [grReal]);
    library.addFunction(&_min_i, "min", [grInt, grInt], [grInt]);
    library.addFunction(&_max_f, "max", [grReal, grReal], [grReal]);
    library.addFunction(&_max_i, "max", [grInt, grInt], [grInt]);

    library.addFunction(&_clamp, "clamp", [grReal, grReal, grReal], [
            grReal
        ]);

    library.addFunction(&_rand01, "rand", [], [grReal]);
    library.addFunction(&_rand_f, "rand", [grReal, grReal], [grReal]);
    library.addFunction(&_rand_i, "rand", [grInt, grInt], [grInt]);

    library.addFunction(&_deg, "deg", [grReal], [grReal]);
    library.addFunction(&_rad, "rad", [grReal], [grReal]);

    library.addFunction(&_cos, "cos", [grReal], [grReal]);
    library.addFunction(&_sin, "sin", [grReal], [grReal]);
    library.addFunction(&_tan, "tan", [grReal], [grReal]);
    library.addFunction(&_acos, "acos", [grReal], [grReal]);
    library.addFunction(&_asin, "asin", [grReal], [grReal]);
    library.addFunction(&_atan, "atan", [grReal], [grReal]);
    library.addFunction(&_atan2, "atan2", [grReal, grReal], [grReal]);

    library.addFunction(&_exp, "exp", [grReal], [grReal]);
    library.addFunction(&_log, "log", [grReal], [grReal]);
    library.addFunction(&_log2, "log2", [grReal], [grReal]);
    library.addFunction(&_log10, "log10", [grReal], [grReal]);
    library.addFunction(&_sqrt, "sqrt", [grReal], [grReal]);
    library.addOperator(&_pow_i, GrLibrary.Operator.power, [grInt, grInt], grInt);
    library.addOperator(&_pow_f, GrLibrary.Operator.power, [grReal, grReal], grReal);

    library.addFunction(&_lerp, "lerp", [grReal, grReal, grReal], [grReal]);
    library.addFunction(&_rlerp, "rlerp", [grReal, grReal, grReal], [
            grReal
        ]);

    library.addFunction(&_abs_i, "abs", [grInt], [grInt]);
    library.addFunction(&_abs_f, "abs", [grReal], [grReal]);
    library.addFunction(&_floor, "floor", [grReal], [grReal]);
    library.addFunction(&_ceil, "ceil", [grReal], [grReal]);
    library.addFunction(&_round, "round", [grReal], [grReal]);
    library.addFunction(&_truncate, "truncate", [grReal], [grReal]);
    library.addFunction(&_positive_i, "positive?", [grInt], [grBool]);
    library.addFunction(&_positive_f, "positive?", [grReal], [grBool]);
    library.addFunction(&_negative_i, "negative?", [grInt], [grBool]);
    library.addFunction(&_negative_f, "negative?", [grReal], [grBool]);
    library.addFunction(&_zero_i, "zero?", [grInt], [grBool]);
    library.addFunction(&_zero_f, "zero?", [grReal], [grBool]);
    library.addFunction(&_nan, "invalid?", [grReal], [grBool]);
    library.addFunction(&_even, "even?", [grInt], [grBool]);
    library.addFunction(&_odd, "odd?", [grInt], [grBool]);
}

private void _min_f(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    call.setReal(a < b ? a : b);
}

private void _min_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a < b ? a : b);
}

private void _max_f(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    call.setReal(a > b ? a : b);
}

private void _max_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a > b ? a : b);
}

private void _clamp(GrCall call) {
    call.setReal(clamp(call.getReal(0), call.getReal(1), call.getReal(2)));
}

private void _rand01(GrCall call) {
    call.setReal(uniform01());
}

private void _rand_f(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    if (a < b)
        call.setReal(uniform!"[]"(a, b));
    else
        call.setReal(uniform!"[]"(b, a));
}

private void _rand_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    if (a < b)
        call.setInt(uniform!"[]"(a, b));
    else
        call.setInt(uniform!"[]"(b, a));
}

private void _deg(GrCall call) {
    call.setReal(call.getReal(0) * (180.0 / PI));
}

private void _rad(GrCall call) {
    call.setReal(call.getReal(0) * (PI / 180.0));
}

private void _cos(GrCall call) {
    call.setReal(cos(call.getReal(0)));
}

private void _sin(GrCall call) {
    call.setReal(sin(call.getReal(0)));
}

private void _tan(GrCall call) {
    call.setReal(tan(call.getReal(0)));
}

private void _acos(GrCall call) {
    call.setReal(acos(call.getReal(0)));
}

private void _asin(GrCall call) {
    call.setReal(asin(call.getReal(0)));
}

private void _atan(GrCall call) {
    call.setReal(atan(call.getReal(0)));
}

private void _atan2(GrCall call) {
    call.setReal(atan2(call.getReal(0), call.getReal(1)));
}

private void _exp(GrCall call) {
    call.setReal(exp(call.getReal(0)));
}

private void _log(GrCall call) {
    call.setReal(log(call.getReal(0)));
}

private void _log2(GrCall call) {
    call.setReal(log2(call.getReal(0)));
}

private void _log10(GrCall call) {
    call.setReal(log10(call.getReal(0)));
}

private void _sqrt(GrCall call) {
    call.setReal(sqrt(call.getReal(0)));
}

private void _pow_i(GrCall call) {
    call.setInt(pow(call.getInt(0), call.getInt(1)));
}

private void _pow_f(GrCall call) {
    call.setReal(pow(call.getReal(0), call.getReal(1)));
}

private void _lerp(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    const GrReal t = call.getReal(2);
    call.setReal(t * b + (1f - t) * a);
}

private void _rlerp(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    const GrReal v = call.getReal(2);
    if ((b - a) == 0f) {
        call.setReal(0f);
        return;
    }
    call.setReal((v - a) / (b - a));
}

private void _abs_i(GrCall call) {
    call.setInt(abs(call.getInt(0)));
}

private void _abs_f(GrCall call) {
    call.setReal(abs(call.getReal(0)));
}

private void _floor(GrCall call) {
    call.setReal(floor(call.getReal(0)));
}

private void _ceil(GrCall call) {
    call.setReal(ceil(call.getReal(0)));
}

private void _round(GrCall call) {
    call.setReal(round(call.getReal(0)));
}

private void _truncate(GrCall call) {
    call.setReal(trunc(call.getReal(0)));
}

private void _positive_i(GrCall call) {
    call.setBool(call.getInt(0) > 0);
}

private void _positive_f(GrCall call) {
    call.setBool(call.getReal(0) > 0);
}

private void _negative_i(GrCall call) {
    call.setBool(call.getInt(0) < 0);
}

private void _negative_f(GrCall call) {
    call.setBool(call.getReal(0) < 0);
}

private void _zero_i(GrCall call) {
    call.setBool(call.getInt(0) == 0);
}

private void _zero_f(GrCall call) {
    call.setBool(call.getReal(0) == 0);
}

private void _nan(GrCall call) {
    call.setBool(isNaN(call.getReal(0)));
}

private void _even(GrCall call) {
    call.setBool(!(call.getInt(0) & 0x1));
}

private void _odd(GrCall call) {
    call.setBool(call.getInt(0) & 0x1);
}
