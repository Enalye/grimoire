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
        sqrtSymbol = "root";
        ceilSymbol = "ceil";
        floorSymbol = "floor";
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
        sqrtSymbol = "racine";
        ceilSymbol = "plafond";
        floorSymbol = "plancher";
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
    library.addVariable("pi", grReal, PI, true);

    library.addPrimitive(&_min_f, "min", [grReal, grReal], [grReal]);
    library.addPrimitive(&_min_i, "min", [grInt, grInt], [grInt]);
    library.addPrimitive(&_max_f, "max", [grReal, grReal], [grReal]);
    library.addPrimitive(&_max_i, "max", [grInt, grInt], [grInt]);

    library.addPrimitive(&_clamp, clampSymbol, [grReal, grReal, grReal], [
            grReal
        ]);

    library.addPrimitive(&_random01, randSymbol, [], [grReal]);
    library.addPrimitive(&_random_f, randSymbol, [grReal, grReal], [grReal]);
    library.addPrimitive(&_random_i, randSymbol, [grInt, grInt], [grInt]);

    library.addPrimitive(&_cos, "cos", [grReal], [grReal]);
    library.addPrimitive(&_sin, "sin", [grReal], [grReal]);
    library.addPrimitive(&_tan, "tan", [grReal], [grReal]);
    library.addPrimitive(&_acos, "acos", [grReal], [grReal]);
    library.addPrimitive(&_asin, "asin", [grReal], [grReal]);
    library.addPrimitive(&_atan, "atan", [grReal], [grReal]);
    library.addPrimitive(&_atan2, "atan2", [grReal, grReal], [grReal]);

    library.addPrimitive(&_exp, "exp", [grReal], [grReal]);
    library.addPrimitive(&_sqrt, sqrtSymbol, [grReal], [grReal]);
    library.addOperator(&_pow_i, GrLibrary.Operator.power, [grInt, grInt], grInt);
    library.addOperator(&_pow_f, GrLibrary.Operator.power, [grReal, grReal], grReal);

    library.addPrimitive(&_lerp, "lerp", [grReal, grReal, grReal], [grReal]);
    library.addPrimitive(&_rlerp, "rlerp", [grReal, grReal, grReal], [
            grReal
        ]);

    library.addPrimitive(&_abs_i, "abs", [grInt], [grInt]);
    library.addPrimitive(&_abs_f, "abs", [grReal], [grReal]);
    library.addPrimitive(&_floor, floorSymbol, [grReal], [grReal]);
    library.addPrimitive(&_ceil, ceilSymbol, [grReal], [grReal]);
    library.addPrimitive(&_round, roundSymbol, [grReal], [grReal]);
    library.addPrimitive(&_truncate, truncateSymbol, [grReal], [grReal]);
    library.addPrimitive(&_positive_i, positiveSymbol, [grInt], [grBool]);
    library.addPrimitive(&_positive_f, positiveSymbol, [grReal], [grBool]);
    library.addPrimitive(&_negative_i, negativeSymbol, [grInt], [grBool]);
    library.addPrimitive(&_negative_f, negativeSymbol, [grReal], [grBool]);
    library.addPrimitive(&_zero_i, zeroSymbol, [grInt], [grBool]);
    library.addPrimitive(&_zero_f, zeroSymbol, [grReal], [grBool]);
    library.addPrimitive(&_nan, nanSymbol, [grReal], [grBool]);
    library.addPrimitive(&_even, evenSymbol, [grInt], [grBool]);
    library.addPrimitive(&_odd, oddSymbol, [grInt], [grBool]);
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

private void _random01(GrCall call) {
    call.setReal(uniform01());
}

private void _random_f(GrCall call) {
    const GrReal a = call.getReal(0);
    const GrReal b = call.getReal(1);
    if (a < b)
        call.setReal(uniform!"[]"(a, b));
    else
        call.setReal(uniform!"[]"(b, a));
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
