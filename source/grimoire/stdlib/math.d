/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.math;

import std.random, std.math;
import std.algorithm.comparison : clamp;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibMath(GrLibDefinition library) {
    library.setModule(["std", "math"]);

    library.setModuleDescription(GrLocale.fr_FR, "Fonctions liées aux maths.");
    library.setModuleDescription(GrLocale.en_US, "Maths related functions.");

    library.setDescription(GrLocale.fr_FR,
        "Rapport entre le diamètre du cercle et sa circonférence.");
    library.setDescription(GrLocale.en_US,
        "Ratio between the diameter of a circle and its circumference.");
    library.addVariable("PI", grFloat, GrValue(PI), true);

    library.setDescription(GrLocale.fr_FR, "Renvoie la plus petite valeur entre `a` et `b`.");
    library.setDescription(GrLocale.en_US, "Returns the smallest value between `a` and `b`.");
    library.setParameters(GrLocale.fr_FR, ["a", "b"]);
    library.setParameters(GrLocale.en_US, ["a", "b"]);
    library.addFunction(&_min_r, "min", [grFloat, grFloat], [grFloat]);
    library.addFunction(&_min_i, "min", [grInt, grInt], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la plus grande valeur entre `a` et `b`.");
    library.setDescription(GrLocale.en_US, "Returns the greatest value between `a` et `b`.");
    library.addFunction(&_max_r, "max", [grFloat, grFloat], [grFloat]);
    library.addFunction(&_max_i, "max", [grInt, grInt], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Restreint `x` entre `min` et `max`.");
    library.setDescription(GrLocale.en_US, "Restrict `x` between `min` and `max`.");
    library.setParameters(GrLocale.fr_FR, ["x", "min", "max"]);
    library.setParameters(GrLocale.en_US, ["x", "min", "max"]);
    library.addFunction(&_clamp_r, "clamp", [grFloat, grFloat, grFloat], [
            grFloat
        ]);
    library.addFunction(&_clamp_i, "clamp", [grInt, grInt, grInt], [grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une valeur aléatoire comprise entre 0 et 1 exclus.");
    library.setDescription(GrLocale.en_US, "Returns a random value between 0 and 1 excluded.");
    library.setParameters(GrLocale.fr_FR);
    library.setParameters(GrLocale.en_US);
    library.addFunction(&_rand01, "rand", [], [grFloat]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une valeur aléatoire comprise entre `min` et `max` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns a random value between `min` and `max` included.");
    library.setParameters(GrLocale.fr_FR, ["min", "max"]);
    library.setParameters(GrLocale.en_US, ["min", "max"]);
    library.addFunction(&_rand_r, "rand", [grFloat, grFloat], [grFloat]);
    library.addFunction(&_rand_i, "rand", [grInt, grInt], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Convertit `radians` en degrés .");
    library.setDescription(GrLocale.en_US, "Converts `radians` in degrees.");
    library.setParameters(GrLocale.fr_FR, ["radians"]);
    library.setParameters(GrLocale.en_US, ["radians"]);
    library.addFunction(&_deg, "deg", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Convertit `degrés`  en radians.");
    library.setDescription(GrLocale.en_US, "Converts `degrees` in radians.");
    library.setParameters(GrLocale.fr_FR, ["degrés"]);
    library.setParameters(GrLocale.en_US, ["degrees"]);
    library.addFunction(&_rad, "rad", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne le cosinus de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the cosine of `radians`.");
    library.setParameters(GrLocale.fr_FR, ["radians"]);
    library.setParameters(GrLocale.en_US, ["radians"]);
    library.addFunction(&_cos, "cos", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne le sinus de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the sine of `radians`.");
    library.addFunction(&_sin, "sin", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne la tangeante de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the tangent of `radians`.");
    library.addFunction(&_tan, "tan", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’arc cosinus de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the arc cosine of `radians`.");
    library.addFunction(&_acos, "acos", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’arc sinus de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the arc sine of `radians`.");
    library.addFunction(&_asin, "asin", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’arc tangeante de `radians`.");
    library.setDescription(GrLocale.en_US, "Returns the arc tangent of `radians`.");
    library.addFunction(&_atan, "atan", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Variation d’`atan`.");
    library.setDescription(GrLocale.en_US, "Variant of `atan`.");
    library.setParameters(GrLocale.fr_FR, ["a", "b"]);
    library.setParameters(GrLocale.en_US, ["a", "b"]);
    library.addFunction(&_atan2, "atan2", [grFloat, grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’exponentielle de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the exponential of `x`.");
    library.setParameters(GrLocale.fr_FR, ["x"]);
    library.setParameters(GrLocale.en_US, ["x"]);
    library.addFunction(&_exp, "exp", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme naturel de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the natural logarithm of `x`.");
    library.addFunction(&_log, "log", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme en base 2 de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the base 2 logarithm of `x`.");
    library.addFunction(&_log2, "log2", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme en base 10 de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the base 10 logarithm of `x`.");
    library.addFunction(&_log10, "log10", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la racine carré de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the square root of `x`.");
    library.addFunction(&_sqrt, "sqrt", [grFloat], [grFloat]);

    library.addOperator(&_pow_i, GrLibDefinition.Operator.power, [grInt, grInt], grInt);
    library.addOperator(&_pow_r, GrLibDefinition.Operator.power, [
            grFloat, grFloat
        ], grFloat);

    library.setDescription(GrLocale.fr_FR,
        "Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.");
    library.setDescription(GrLocale.en_US,
        "Interpolate between `source` and `destination` using `t` between 0 and 1.");
    library.setParameters(GrLocale.fr_FR, ["source", "destination", "t"]);
    library.setParameters(GrLocale.en_US, ["source", "destination", "t"]);
    library.addFunction(&_lerp, "lerp", [grFloat, grFloat, grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Opération inverse de lerp.
Retourne le ratio entre 0 et 1 de `valeur` par rapport à `source` et `destination`");
    library.setDescription(GrLocale.en_US, "Reverse lerp operation.
Returns the ratio between 0 and 1 of `value` from `source` to `destination`.");
    library.setParameters(GrLocale.fr_FR, ["source", "destination", "valeur"]);
    library.setParameters(GrLocale.en_US, ["source", "destination", "value"]);
    library.addFunction(&_rlerp, "rlerp", [grFloat, grFloat, grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne la valeur absolue de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the absolute value of `x`.");
    library.setParameters(GrLocale.fr_FR, ["x"]);
    library.setParameters(GrLocale.en_US, ["x"]);
    library.addFunction(&_abs_i, "abs", [grInt], [grInt]);
    library.addFunction(&_abs_r, "abs", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’arrondi de `x` à l’entier inférieur.");
    library.setDescription(GrLocale.en_US,
        "Returns the rounded value of `x` not greater than `x`.");
    library.addFunction(&_floor, "floor", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’arrondi de `x` à l’entier supérieur.");
    library.setDescription(GrLocale.en_US,
        "Returns the rounded value of `x` not smaller than `x`.");
    library.addFunction(&_ceil, "ceil", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne l’arrondi de `x` à l’entier le plus proche.");
    library.setDescription(GrLocale.en_US, "Returns the nearest rounded value of `x`.");
    library.addFunction(&_round, "round", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Retourne la partie entière de `x`.");
    library.setDescription(GrLocale.en_US, "Returns the integer part of `x`.");
    library.addFunction(&_truncate, "truncate", [grFloat], [grFloat]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si le `x` est un réel valide ou non.");
    library.setDescription(GrLocale.en_US, "Checks if `x` is a valid float value or not.");
    library.addFunction(&_isNaN, "isNaN", [grFloat], [grBool]);

    library.setDescription(GrLocale.fr_FR,
        "Approche `x` de `target` par pas de `step` sans le dépasser.
Un pas négatif l’éloigne de `target` d’autant.");
    library.setDescription(GrLocale.en_US,
        "Approach `x` up to `target` by increment of `step` without overshooting it.
A negative step distances from `target` by that much.");
    library.setParameters(GrLocale.fr_FR, ["x", "target", "step"]);
    library.setParameters(GrLocale.en_US, ["x", "target", "step"]);
    library.addFunction(&_approach_i, "approach", [grInt, grInt, grInt], [grInt]);
    library.addFunction(&_approach_r, "approach", [grFloat, grFloat, grFloat], [
            grFloat
        ]);
}

private void _min_r(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    call.setFloat(a < b ? a : b);
}

private void _min_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a < b ? a : b);
}

private void _max_r(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    call.setFloat(a > b ? a : b);
}

private void _max_i(GrCall call) {
    const GrInt a = call.getInt(0);
    const GrInt b = call.getInt(1);
    call.setInt(a > b ? a : b);
}

private void _clamp_r(GrCall call) {
    call.setFloat(clamp(call.getFloat(0), call.getFloat(1), call.getFloat(2)));
}

private void _clamp_i(GrCall call) {
    call.setInt(clamp(call.getInt(0), call.getInt(1), call.getInt(2)));
}

private void _rand01(GrCall call) {
    call.setFloat(uniform01());
}

private void _rand_r(GrCall call) {
    const GrFloat a = call.getFloat(0);
    const GrFloat b = call.getFloat(1);
    if (a < b)
        call.setFloat(uniform!"[]"(a, b));
    else
        call.setFloat(uniform!"[]"(b, a));
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
    call.setFloat(call.getFloat(0) * (180.0 / PI));
}

private void _rad(GrCall call) {
    call.setFloat(call.getFloat(0) * (PI / 180.0));
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

private void _log(GrCall call) {
    call.setFloat(log(call.getFloat(0)));
}

private void _log2(GrCall call) {
    call.setFloat(log2(call.getFloat(0)));
}

private void _log10(GrCall call) {
    call.setFloat(log10(call.getFloat(0)));
}

private void _sqrt(GrCall call) {
    call.setFloat(sqrt(call.getFloat(0)));
}

private void _pow_i(GrCall call) {
    call.setInt(pow(call.getInt(0), call.getInt(1)));
}

private void _pow_r(GrCall call) {
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

private void _abs_r(GrCall call) {
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

private void _isNaN(GrCall call) {
    call.setBool(isNaN(call.getFloat(0)));
}

private void _approach_i(GrCall call) {
    import std.algorithm : min, max;

    const GrInt value = call.getInt(0);
    const GrInt target = call.getInt(1);
    const GrInt step = call.getInt(2);
    call.setInt(value > target ? max(value - step, target) : min(value + step, target));
}

private void _approach_r(GrCall call) {
    import std.algorithm : min, max;

    const GrFloat value = call.getFloat(0);
    const GrFloat target = call.getFloat(1);
    const GrFloat step = call.getFloat(2);
    call.setFloat(value > target ? max(value - step, target) : min(value + step, target));
}
