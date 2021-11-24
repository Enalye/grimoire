/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.math;

import std.random, std.math;
import std.algorithm.comparison : clamp;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibMath(GrLibrary library, GrLocale locale) {
    string clampSymbol, randSymbol, sqrtSymbol, floorSymbol, ceilSymbol, roundSymbol, truncateSymbol,
    positiveSymbol, negativeSymbol, zeroSymbol, nanSymbol, evenSymbol, oddSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        clampSymbol = "clamp";
        randSymbol = "random";
        sqrtSymbol = "sqrt";
        floorSymbol = "floor";
        ceilSymbol = "ceil";
        roundSymbol = "round";
        truncateSymbol = "truncate";
        positiveSymbol = "positive?";
        negativeSymbol = "negative?";
        zeroSymbol = "zero?";
        nanSymbol = "invalid?";
        evenSymbol = "even?";
        oddSymbol = "odd?";
        break;
    case fr_FR:
        clampSymbol = "restreins";
        randSymbol = "hasard";
        sqrtSymbol = "racineCarré";
        floorSymbol = "arrondiInf";
        ceilSymbol = "arrondiSup";
        roundSymbol = "arrondi";
        truncateSymbol = "tronque";
        positiveSymbol = "positif?";
        negativeSymbol = "négatif?";
        zeroSymbol = "zéro?";
        nanSymbol = "invalide?";
        evenSymbol = "pair?";
        oddSymbol = "impair?";
        break;
    }
    library.addVariable("pi", grFloat, PI, true);

    library.addPrimitive(&_min_f, "min", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_min_i, "min", [grInt, grInt], [grInt]);
    library.addPrimitive(&_max_f, "max", [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_max_i, "max", [grInt, grInt], [grInt]);

    library.addPrimitive(&_clamp, clampSymbol, [grFloat, grFloat, grFloat], [
            grFloat
        ]);

    library.addPrimitive(&_random01, randSymbol, [], [grFloat]);
    library.addPrimitive(&_random_f, randSymbol, [grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_random_i, randSymbol, [grInt, grInt], [grInt]);

    library.addPrimitive(&_cos, "cos", [grFloat], [grFloat]);
    library.addPrimitive(&_sin, "sin", [grFloat], [grFloat]);
    library.addPrimitive(&_tan, "tan", [grFloat], [grFloat]);
    library.addPrimitive(&_acos, "acos", [grFloat], [grFloat]);
    library.addPrimitive(&_asin, "asin", [grFloat], [grFloat]);
    library.addPrimitive(&_atan, "atan", [grFloat], [grFloat]);
    library.addPrimitive(&_atan2, "atan2", [grFloat, grFloat], [grFloat]);

    library.addPrimitive(&_exp, "exp", [grFloat], [grFloat]);
    library.addPrimitive(&_sqrt, sqrtSymbol, [grFloat], [grFloat]);
    library.addOperator(&_pow_i, GrLibrary.Operator.power, [grInt, grInt], grInt);
    library.addOperator(&_pow_f, GrLibrary.Operator.power, [grFloat, grFloat], grFloat);

    library.addPrimitive(&_lerp, "lerp", [grFloat, grFloat, grFloat], [grFloat]);
    library.addPrimitive(&_rlerp, "rlerp", [grFloat, grFloat, grFloat], [
            grFloat
        ]);

    library.addPrimitive(&_abs_i, "abs", [grInt], [grInt]);
    library.addPrimitive(&_abs_f, "abs", [grFloat], [grFloat]);
    library.addPrimitive(&_floor, floorSymbol, [grFloat], [grFloat]);
    library.addPrimitive(&_ceil, ceilSymbol, [grFloat], [grFloat]);
    library.addPrimitive(&_round, roundSymbol, [grFloat], [grFloat]);
    library.addPrimitive(&_truncate, truncateSymbol, [grFloat], [grFloat]);
    library.addPrimitive(&_positive_i, positiveSymbol, [grInt], [grBool]);
    library.addPrimitive(&_positive_f, positiveSymbol, [grFloat], [grBool]);
    library.addPrimitive(&_negative_i, negativeSymbol, [grInt], [grBool]);
    library.addPrimitive(&_negative_f, negativeSymbol, [grFloat], [grBool]);
    library.addPrimitive(&_zero_i, zeroSymbol, [grInt], [grBool]);
    library.addPrimitive(&_zero_f, zeroSymbol, [grFloat], [grBool]);
    library.addPrimitive(&_nan, nanSymbol, [grFloat], [grBool]);
    library.addPrimitive(&_even, evenSymbol, [grInt], [grBool]);
    library.addPrimitive(&_odd, oddSymbol, [grInt], [grBool]);
}

private void _min_f(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    call.setFloat(a < b ? a : b);
}

private void _min_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a < b ? a : b);
}

private void _max_f(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    call.setFloat(a > b ? a : b);
}

private void _max_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a > b ? a : b);
}

private void _clamp(GrCall call) {
    call.setFloat(clamp(call.getFloat(0), call.getFloat(1), call.getFloat(2)));
}

private void _random01(GrCall call) {
    call.setFloat(uniform01());
}

private void _random_f(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    if (a < b)
        call.setFloat(uniform!"[]"(a, b));
    else
        call.setFloat(uniform!"[]"(b, a));
}

private void _random_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    if (a < b)
        call.setInt(uniform!"[]"(a, b));
    else
        call.setInt(uniform!"[]"(b, a));
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

private void _pow_i(GrCall call) {
    call.setInt(pow(call.getInt(0), call.getInt(1)));
}

private void _pow_f(GrCall call) {
    call.setFloat(pow(call.getFloat(0), call.getFloat(1)));
}

private void _lerp(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    const GrFloat t = call.getFloat(2);
    call.setFloat(t * b + (1f - t) * a);
}

private void _rlerp(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    const GrFloat v = call.getFloat(2);
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
