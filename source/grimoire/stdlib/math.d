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
    library.setModule("math");

    library.setModuleDescription(GrLocale.fr_FR, "Fonctions liées aux maths.");
    library.setModuleDescription(GrLocale.en_US, "Maths related functions.");

    library.setDescription(GrLocale.fr_FR,
        "Rapport entre le diamètre du cercle et sa circonférence.");
    library.setDescription(GrLocale.en_US,
        "Ratio between the diameter of a circle and its circumference.");
    library.addVariable("PI", grDouble, GrValue(cast(GrDouble) PI), true);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une valeur aléatoire comprise entre 0 et 1 exclus.");
    library.setDescription(GrLocale.en_US, "Returns a random value between 0 and 1 excluded.");
    library.setParameters(GrLocale.fr_FR);
    library.setParameters(GrLocale.en_US);
    library.addFunction(&_rand01, "rand", [], [grDouble]);

    GrType type;
    static foreach (T; ["Int", "UInt", "Float", "Double"]) {
        mixin("type = gr", T, ";");

        library.setDescription(GrLocale.fr_FR, "Renvoie la plus petite valeur entre `a` et `b`.");
        library.setDescription(GrLocale.en_US, "Returns the smallest value between `a` and `b`.");
        library.setParameters(GrLocale.fr_FR, ["a", "b"]);
        library.setParameters(GrLocale.en_US, ["a", "b"]);
        library.addFunction(&_min!T, "min", [type, type], [type]);

        library.setDescription(GrLocale.fr_FR, "Renvoie la plus grande valeur entre `a` et `b`.");
        library.setDescription(GrLocale.en_US, "Returns the greatest value between `a` et `b`.");
        library.addFunction(&_max!T, "max", [type, type], [type]);

        library.setDescription(GrLocale.fr_FR, "Restreint `x` entre `min` et `max`.");
        library.setDescription(GrLocale.en_US, "Restrict `x` between `min` and `max`.");
        library.setParameters(GrLocale.fr_FR, ["x", "min", "max"]);
        library.setParameters(GrLocale.en_US, ["x", "min", "max"]);
        library.addFunction(&_clamp!T, "clamp", [type, type, type], [type]);

        library.setDescription(GrLocale.fr_FR,
            "Retourne une valeur aléatoire comprise entre `min` et `max` inclus.");
        library.setDescription(GrLocale.en_US,
            "Returns a random value between `min` and `max` included.");
        library.setParameters(GrLocale.fr_FR, ["min", "max"]);
        library.setParameters(GrLocale.en_US, ["min", "max"]);
        library.addFunction(&_rand!T, "rand", [type, type], [type]);

        static if (T == "Float" || T == "Double") {
            library.setDescription(GrLocale.fr_FR, "Convertit `radians` en degrés .");
            library.setDescription(GrLocale.en_US, "Converts `radians` in degrees.");
            library.setParameters(GrLocale.fr_FR, ["radians"]);
            library.setParameters(GrLocale.en_US, ["radians"]);
            library.addFunction(&_deg!T, "deg", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Convertit `degrés`  en radians.");
            library.setDescription(GrLocale.en_US, "Converts `degrees` in radians.");
            library.setParameters(GrLocale.fr_FR, ["degrés"]);
            library.setParameters(GrLocale.en_US, ["degrees"]);
            library.addFunction(&_rad!T, "rad", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne le cosinus de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the cosine of `radians`.");
            library.setParameters(GrLocale.fr_FR, ["radians"]);
            library.setParameters(GrLocale.en_US, ["radians"]);
            library.addFunction(&_cos!T, "cos", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne le sinus de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the sine of `radians`.");
            library.addFunction(&_sin!T, "sin", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne la tangeante de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the tangent of `radians`.");
            library.addFunction(&_tan!T, "tan", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne l’arc cosinus de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the arc cosine of `radians`.");
            library.addFunction(&_acos!T, "acos", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne l’arc sinus de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the arc sine of `radians`.");
            library.addFunction(&_asin!T, "asin", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne l’arc tangeante de `radians`.");
            library.setDescription(GrLocale.en_US, "Returns the arc tangent of `radians`.");
            library.addFunction(&_atan!T, "atan", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Variation d’`atan`.");
            library.setDescription(GrLocale.en_US, "Variant of `atan`.");
            library.setParameters(GrLocale.fr_FR, ["a", "b"]);
            library.setParameters(GrLocale.en_US, ["a", "b"]);
            library.addFunction(&_atan2!T, "atan2", [type, type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne l’exponentielle de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the exponential of `x`.");
            library.setParameters(GrLocale.fr_FR, ["x"]);
            library.setParameters(GrLocale.en_US, ["x"]);
            library.addFunction(&_exp!T, "exp", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme naturel de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the natural logarithm of `x`.");
            library.addFunction(&_log!T, "log", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme en base 2 de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the base 2 logarithm of `x`.");
            library.addFunction(&_log2!T, "log2", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Renvoie le logarithme en base 10 de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the base 10 logarithm of `x`.");
            library.addFunction(&_log10!T, "log10", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Renvoie la racine carré de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the square root of `x`.");
            library.addFunction(&_sqrt!T, "sqrt", [type], [type]);
        }

        library.addOperator(&_pow!T, GrLibDefinition.Operator.power, [
                type, type
            ], type);

        static if (T == "Float" || T == "Double") {
            library.setDescription(GrLocale.fr_FR,
                "Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1.");
            library.setDescription(GrLocale.en_US,
                "Interpolate between `source` and `destination` using `t` clamped between 0 and 1.");
            library.setParameters(GrLocale.fr_FR, ["source", "destination", "t"]);
            library.setParameters(GrLocale.en_US, ["source", "destination", "t"]);
            library.addFunction(&_lerp!T, "lerp", [type, type, type], [type]);

            library.setDescription(GrLocale.fr_FR,
                "Interpole entre `source` et `destination` en fonction de `t` compris entre 0 et 1 avec extrapolation.");
            library.setDescription(GrLocale.en_US,
                "Interpolate between `source` and `destination` using `t` between 0 and 1 with extrapolation.");
            library.setParameters(GrLocale.fr_FR, ["source", "destination", "t"]);
            library.setParameters(GrLocale.en_US, ["source", "destination", "t"]);
            library.addFunction(&_ulerp!T, "ulerp", [type, type, type], [type]);

            library.setDescription(GrLocale.fr_FR, "Opération inverse de lerp.
Retourne le ratio entre 0 et 1 de `valeur` par rapport à `source` et `destination`");
            library.setDescription(GrLocale.en_US, "Reverse lerp operation.
Returns the ratio between 0 and 1 of `value` from `source` to `destination`.");
            library.setParameters(GrLocale.fr_FR, [
                    "source", "destination", "valeur"
                ]);
            library.setParameters(GrLocale.en_US, [
                    "source", "destination", "value"
                ]);
            library.addFunction(&_rlerp!T, "rlerp", [type, type, type], [type]);
        }

        static if (T != "UInt") {
            library.setDescription(GrLocale.fr_FR, "Retourne la valeur absolue de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the absolute value of `x`.");
            library.setParameters(GrLocale.fr_FR, ["x"]);
            library.setParameters(GrLocale.en_US, ["x"]);
            library.addFunction(&_abs!T, "abs", [type], [type]);
        }

        static if (T == "Float" || T == "Double") {
            library.setDescription(GrLocale.fr_FR,
                "Retourne l’arrondi de `x` à l’entier inférieur.");
            library.setDescription(GrLocale.en_US,
                "Returns the rounded value of `x` not greater than `x`.");
            library.addFunction(&_floor!T, "floor", [type], [type]);

            library.setDescription(GrLocale.fr_FR,
                "Retourne l’arrondi de `x` à l’entier supérieur.");
            library.setDescription(GrLocale.en_US,
                "Returns the rounded value of `x` not smaller than `x`.");
            library.addFunction(&_ceil!T, "ceil", [type], [type]);

            library.setDescription(GrLocale.fr_FR,
                "Retourne l’arrondi de `x` à l’entier le plus proche.");
            library.setDescription(GrLocale.en_US, "Returns the nearest rounded value of `x`.");
            library.addFunction(&_round!T, "round", [type], [type]);

            library.setDescription(GrLocale.fr_FR, "Retourne la partie entière de `x`.");
            library.setDescription(GrLocale.en_US, "Returns the integer part of `x`.");
            library.addFunction(&_truncate!T, "truncate", [type], [type]);

            library.setDescription(GrLocale.fr_FR,
                "Vérifie si le `x` est un réel valide ou non.");
            library.setDescription(GrLocale.en_US, "Checks if `x` is a valid float value or not.");
            library.addFunction(&_isNaN!T, "isNaN", [type], [grBool]);
        }

        library.setDescription(GrLocale.fr_FR,
            "Approche `x` de `target` par pas de `step` sans le dépasser.
Un pas négatif l’éloigne de `target` d’autant.");
        library.setDescription(GrLocale.en_US,
            "Approach `x` up to `target` by increment of `step` without overshooting it.
A negative step distances from `target` by that much.");
        library.setParameters(GrLocale.fr_FR, ["x", "target", "step"]);
        library.setParameters(GrLocale.en_US, ["x", "target", "step"]);
        library.addFunction(&_approach!T, "approach", [type, type, type], [type]);
    }
}

private void _rand01(GrCall call) {
    call.setDouble(uniform01());
}

private void _min(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");
    mixin("call.set", T, "(a < b ? a : b);");
}

private void _max(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");
    mixin("call.set", T, "(a > b ? a : b);");
}

private void _clamp(string T)(GrCall call) {
    mixin("call.set", T, "(clamp(call.get", T, "(0), call.get", T, "(1), call.get", T, "(2)));");
}

private void _rand(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");

    if (a < b) {
        mixin("call.set", T, "(uniform!\"[]\"(a, b));");
    }
    else {
        mixin("call.set", T, "(uniform!\"[]\"(b, a));");
    }
}

private void _deg(string T)(GrCall call) {
    mixin("call.set", T, "(call.get", T, "(0) * (180.0 / PI));");
}

private void _rad(string T)(GrCall call) {
    mixin("call.set", T, "(call.get", T, "(0) * (PI / 180.0));");
}

private void _cos(string T)(GrCall call) {
    mixin("call.set", T, "(cos(call.get", T, "(0)));");
}

private void _sin(string T)(GrCall call) {
    mixin("call.set", T, "(sin(call.get", T, "(0)));");
}

private void _tan(string T)(GrCall call) {
    mixin("call.set", T, "(tan(call.get", T, "(0)));");
}

private void _acos(string T)(GrCall call) {
    mixin("call.set", T, "(acos(call.get", T, "(0)));");
}

private void _asin(string T)(GrCall call) {
    mixin("call.set", T, "(asin(call.get", T, "(0)));");
}

private void _atan(string T)(GrCall call) {
    mixin("call.set", T, "(atan(call.get", T, "(0)));");
}

private void _atan2(string T)(GrCall call) {
    mixin("call.set", T, "(atan2(call.get", T, "(0), call.get", T, "(1)));");
}

private void _exp(string T)(GrCall call) {
    mixin("call.set", T, "(exp(call.get", T, "(0)));");
}

private void _log(string T)(GrCall call) {
    mixin("call.set", T, "(log(call.get", T, "(0)));");
}

private void _log2(string T)(GrCall call) {
    mixin("call.set", T, "(log2(call.get", T, "(0)));");
}

private void _log10(string T)(GrCall call) {
    mixin("call.set", T, "(log10(call.get", T, "(0)));");
}

private void _sqrt(string T)(GrCall call) {
    mixin("call.set", T, "(sqrt(call.get", T, "(0)));");
}

private void _pow(string T)(GrCall call) {
    mixin("call.set", T, "(pow(call.get", T, "(0), call.get", T, "(1)));");
}

private void _lerp(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");
    mixin("const Type t = call.get", T, "(2);");
    if (t <= 0) {
        mixin("call.set", T, "(a);");
        return;
    }
    if (t >= 1) {
        mixin("call.set", T, "(b);");
        return;
    }
    mixin("call.set", T, "(t * b + (1f - t) * a);");
}

private void _ulerp(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");
    mixin("const Type t = call.get", T, "(2);");
    mixin("call.set", T, "(t * b + (1f - t) * a);");
}

private void _rlerp(string T)(GrCall call) {
    mixin("alias Type = Gr", T, ";");
    mixin("const Type a = call.get", T, "(0);");
    mixin("const Type b = call.get", T, "(1);");
    mixin("const Type v = call.get", T, "(2);");
    if (b == a) {
        mixin("call.set", T, "(0);");
        return;
    }
    mixin("call.set", T, "((v - a) / (b - a));");
}

private void _abs(string T)(GrCall call) {
    mixin("call.set", T, "(abs(call.get", T, "(0)));");
}

private void _floor(string T)(GrCall call) {
    mixin("call.set", T, "(floor(call.get", T, "(0)));");
}

private void _ceil(string T)(GrCall call) {
    mixin("call.set", T, "(ceil(call.get", T, "(0)));");
}

private void _round(string T)(GrCall call) {
    mixin("call.set", T, "(round(call.get", T, "(0)));");
}

private void _truncate(string T)(GrCall call) {
    mixin("call.set", T, "(trunc(call.get", T, "(0)));");
}

private void _isNaN(string T)(GrCall call) {
    mixin("call.setBool(isNaN(call.get", T, "(0)));");
}

private void _approach(string T)(GrCall call) {
    import std.algorithm : min, max;

    mixin("alias Type = Gr", T, ";");
    mixin("const Type value = call.get", T, "(0);");
    mixin("const Type target = call.get", T, "(1);");
    mixin("const Type step = call.get", T, "(2);");
    mixin("call.set", T,
        "(value > target ? max(value - step, target) : min(value + step, target));");
}
