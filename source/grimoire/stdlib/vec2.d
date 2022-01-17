/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.vec2;

import std.conv : to;
import std.math;
import std.algorithm.comparison : min, max;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private {
    string _vector2Symbol;
    /// Ratio to multiply with to get a value in radians from a value in degrees.
    enum double _degToRad = std.math.PI / 180.0;
    /// Ratio to multiply with to get a value in degrees from a value in radians.
    enum double _radToDeg = 180.0 / std.math.PI;
}

package void grLoadStdLibVec2(GrLibrary library, GrLocale locale) {
    string writeSymbol, vec2ZeroSymbol, vec2HalfSymbol, vec2OneSymbol, vec2UpSymbol, vec2DownSymbol, vec2LeftSymbol;
    string vec2RightSymbol, vec2AngledSymbol, absSymbol, ceilSymbol, floorSymbol, roundSymbol, unpackSymbol, zeroSymbol;
    string sumSymbol, signSymbol, lerpSymbol, distanceSymbol, distanceSquaredSymbol, lengthSymbol, lengthSquaredSymbol;
    string normalizeSymbol, normalizedSymbol, dotSymbol, crossSymbol, normalSymbol, angleSymbol, rotateSymbol;
    string rotatedSymbol, approachSymbol, reflectSymbol, refractSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _vector2Symbol = "Vector2";
        vec2ZeroSymbol = "Vector2_zero";
        vec2HalfSymbol = "Vector2_half";
        vec2OneSymbol = "Vector2_one";
        vec2UpSymbol = "Vector2_up";
        vec2DownSymbol = "Vector2_down";
        vec2LeftSymbol = "Vector2_left";
        vec2RightSymbol = "Vector2_right";
        vec2AngledSymbol = "Vector2_angled";
        zeroSymbol = "zero?";
        unpackSymbol = "unpack";
        absSymbol = "abs";
        ceilSymbol = "ceil";
        floorSymbol = "floor";
        roundSymbol = "round";
        sumSymbol = "sum";
        signSymbol = "sign";
        lerpSymbol = "interpolate";
        approachSymbol = "approach";
        reflectSymbol = "reflect";
        refractSymbol = "refract";
        distanceSymbol = "distance";
        distanceSquaredSymbol = "distance2";
        dotSymbol = "dot";
        crossSymbol = "cross";
        normalSymbol = "normal";
        angleSymbol = "angle";
        rotateSymbol = "rotate";
        rotatedSymbol = "rotated";
        lengthSymbol = "length";
        lengthSquaredSymbol = "length2";
        normalizeSymbol = "normalize";
        normalizedSymbol = "normalized";
        break;
    case fr_FR:
        _vector2Symbol = "Vecteur2";
        vec2ZeroSymbol = "Vecteur2_zéro";
        vec2HalfSymbol = "Vecteur2_moitié";
        vec2OneSymbol = "Vecteur2_un";
        vec2UpSymbol = "Vecteur2_haut";
        vec2DownSymbol = "Vecteur2_bas";
        vec2LeftSymbol = "Vecteur2_gauche";
        vec2RightSymbol = "Vecteur2_droite";
        vec2AngledSymbol = "Vecteur2_anglé";
        zeroSymbol = "zéro?";
        unpackSymbol = "déballe";
        absSymbol = "abs";
        ceilSymbol = "plafond";
        floorSymbol = "plancher";
        roundSymbol = "arrondi";
        sumSymbol = "somme";
        signSymbol = "signe";
        lerpSymbol = "interpole";
        approachSymbol = "approche";
        reflectSymbol = "reflète";
        refractSymbol = "réfracte";
        distanceSymbol = "distance";
        distanceSquaredSymbol = "distance2";
        dotSymbol = "scalaire";
        crossSymbol = "croix";
        normalSymbol = "normale";
        angleSymbol = "angle";
        rotateSymbol = "tourne";
        rotatedSymbol = "tourné";
        lengthSymbol = "longueur";
        lengthSquaredSymbol = "longueur2";
        normalizeSymbol = "normalise";
        normalizedSymbol = "normalisé";
        break;
    }

    GrType vec2Type = library.addClass(_vector2Symbol, ["x", "y"], [
            grFloat, grFloat
        ]);

    // Ctors
    library.addPrimitive(&_vec2_0, _vector2Symbol, [], [vec2Type]);
    library.addPrimitive(&_vec2_1, _vector2Symbol, [grFloat], [vec2Type]);
    library.addPrimitive(&_vec2_2, _vector2Symbol, [grFloat, grFloat], [
            vec2Type
        ]);

    // Trace
    library.addPrimitive(&_write, writeSymbol, [vec2Type]);

    // Operators
    static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnaryVec2!op, op, [vec2Type], vec2Type);
    }
    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryVec2!op, op, [vec2Type, vec2Type], vec2Type);
        library.addOperator(&_opBinaryScalarVec2!op, op, [vec2Type, grFloat], vec2Type);
        library.addOperator(&_opBinaryScalarRightVec2!op, op, [
                grFloat, vec2Type
            ], vec2Type);
    }
    static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryCompareVec2!op, op, [
                vec2Type, vec2Type
            ], grBool);
    }

    // Utility
    library.addPrimitive(&_vec2_0, vec2ZeroSymbol, [], [vec2Type]);
    library.addPrimitive(&_halfVec2, vec2HalfSymbol, [], [vec2Type]);
    library.addPrimitive(&_oneVec2, vec2OneSymbol, [], [vec2Type]);
    library.addPrimitive(&_upVec2, vec2UpSymbol, [], [vec2Type]);
    library.addPrimitive(&_downVec2, vec2DownSymbol, [], [vec2Type]);
    library.addPrimitive(&_leftVec2, vec2LeftSymbol, [], [vec2Type]);
    library.addPrimitive(&_rightVec2, vec2RightSymbol, [], [vec2Type]);

    library.addPrimitive(&_unpackVec2, unpackSymbol, [vec2Type], [
            grFloat, grFloat
        ]);

    library.addPrimitive(&_abs, absSymbol, [vec2Type], [vec2Type]);
    library.addPrimitive(&_ceil, ceilSymbol, [vec2Type], [vec2Type]);
    library.addPrimitive(&_floor, floorSymbol, [vec2Type], [vec2Type]);
    library.addPrimitive(&_round, roundSymbol, [vec2Type], [vec2Type]);

    library.addPrimitive(&_isZeroVec2, zeroSymbol, [vec2Type], [grBool]);

    // Operations
    library.addPrimitive(&_sumVec2, sumSymbol, [vec2Type], [grFloat]);
    library.addPrimitive(&_sign, signSymbol, [vec2Type], [vec2Type]);

    library.addPrimitive(&_lerp, lerpSymbol, [vec2Type, vec2Type, grFloat], [
            vec2Type
        ]);
    library.addPrimitive(&_approach, approachSymbol, [
            vec2Type, vec2Type, grFloat
        ], [vec2Type]);

    library.addPrimitive(&_reflect, reflectSymbol, [vec2Type, vec2Type], [
            vec2Type
        ]);
    library.addPrimitive(&_refract, refractSymbol, [vec2Type, vec2Type, grFloat], [
            vec2Type
        ]);

    library.addPrimitive(&_distance, distanceSymbol, [vec2Type, vec2Type], [
            grFloat
        ]);
    library.addPrimitive(&_distanceSquared, distanceSquaredSymbol, [
            vec2Type, vec2Type
        ], [
            grFloat
        ]);
    library.addPrimitive(&_dot, dotSymbol, [vec2Type, vec2Type], [grFloat]);
    library.addPrimitive(&_cross, crossSymbol, [vec2Type, vec2Type], [
            grFloat
        ]);
    library.addPrimitive(&_normal, normalSymbol, [vec2Type], [vec2Type]);
    library.addPrimitive(&_angle, angleSymbol, [vec2Type], [grFloat]);
    library.addPrimitive(&_rotate, rotateSymbol, [vec2Type, grFloat], [
            vec2Type
        ]);
    library.addPrimitive(&_rotated, rotatedSymbol, [vec2Type, grFloat], [
            vec2Type
        ]);
    library.addPrimitive(&_angled, vec2AngledSymbol, [grFloat], [vec2Type]);
    library.addPrimitive(&_length, lengthSymbol, [vec2Type], [grFloat]);
    library.addPrimitive(&_lengthSquared, lengthSquaredSymbol, [vec2Type], [
            grFloat
        ]);
    library.addPrimitive(&_normalize, normalizeSymbol, [vec2Type], [
            vec2Type
        ]);
    library.addPrimitive(&_normalized, normalizedSymbol, [vec2Type], [
            vec2Type
        ]);
}

// Ctors ------------------------------------------
private void _vec2_0(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", 0f);
    self.setFloat("y", 0f);
    call.setObject(self);
}

private void _vec2_1(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    const GrFloat value = call.getFloat(0);
    self.setFloat("x", value);
    self.setFloat("y", value);
    call.setObject(self);
}

private void _vec2_2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", call.getFloat(0));
    self.setFloat("y", call.getFloat(1));
    call.setObject(self);
}

// Write ------------------------------------------
private void _write(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Vec2)");
        return;
    }
    _stdOut("Vec2(" ~ to!GrString(self.getFloat("x")) ~ ", " ~ to!GrString(
            self.getFloat("y")) ~ ")");
}

/// Operators ------------------------------------------
private void _opUnaryVec2(string op)(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"x\", " ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", " ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryVec2(string op)(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"x\", v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2(string op)(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"x\", v.getFloat(\"x\")" ~ op ~ "s);");
    mixin("self.setFloat(\"y\", v.getFloat(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2(string op)(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"x\", s" ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", s" ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryCompareVec2(string op)(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    mixin("call.setBool(
        v1.getFloat(\"x\")"
            ~ op ~ "v2.getFloat(\"x\") &&
        v1.getFloat(\"y\")"
            ~ op
            ~ "v2.getFloat(\"y\"));");
}

// Utility ------------------------------------------
private void _oneVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", 1f);
    self.setFloat("y", 1f);
    call.setObject(self);
}

private void _halfVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", .5f);
    self.setFloat("y", .5f);
    call.setObject(self);
}

private void _upVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("y", 1f);
    call.setObject(self);
}

private void _downVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("y", -1f);
    call.setObject(self);
}

private void _leftVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", -1f);
    call.setObject(self);
}

private void _rightVec2(GrCall call) {
    GrObject self = call.createObject(_vector2Symbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat("x", 1f);
    call.setObject(self);
}

private void _unpackVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(self.getFloat("x"));
    call.setFloat(self.getFloat("y"));
}

private void _isZeroVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setBool(self.getFloat("x") == 0f && self.getFloat("y") == 0f);
}

// Operations ------------------------------------------
private void _abs(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", abs(self.getFloat("y")));
    v.setFloat("y", abs(self.getFloat("x")));
    call.setObject(v);
}

private void _ceil(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", ceil(self.getFloat("y")));
    v.setFloat("y", ceil(self.getFloat("x")));
    call.setObject(v);
}

private void _floor(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", floor(self.getFloat("y")));
    v.setFloat("y", floor(self.getFloat("x")));
    call.setObject(v);
}

private void _round(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", round(self.getFloat("y")));
    v.setFloat("y", round(self.getFloat("x")));
    call.setObject(v);
}

private void _sumVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(self.getFloat("x") + self.getFloat("y"));
}

private void _sign(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", self.getFloat("x") >= 0f ? 1f : -1f);
    v.setFloat("y", self.getFloat("y") >= 0f ? 1f : -1f);
    call.setObject(v);
}

private void _lerp(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    const GrFloat weight = call.getFloat(2);
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", v2.getFloat("x") * weight + v1.getFloat("x") * (1f - weight));
    v.setFloat("y", v2.getFloat("y") * weight + v1.getFloat("y") * (1f - weight));
    call.setObject(v);
}

private void _approach(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrFloat x1 = v1.getFloat("x");
    const GrFloat y1 = v1.getFloat("y");
    const GrFloat x2 = v2.getFloat("x");
    const GrFloat y2 = v2.getFloat("y");
    const GrFloat step = call.getFloat(2);
    v.setFloat("x", x1 > x2 ? max(x1 - step, x2) : min(x1 + step, x2));
    v.setFloat("y", y1 > y2 ? max(y1 - step, y2) : min(y1 + step, y2));
    call.setObject(v);
}

private void _reflect(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrFloat x1 = v1.getFloat("x");
    const GrFloat y1 = v1.getFloat("y");
    const GrFloat x2 = v2.getFloat("x");
    const GrFloat y2 = v2.getFloat("y");
    const GrFloat dotNI2 = 2.0 * x1 * x2 + y1 * y2;
    v.setFloat("x", x1 - dotNI2 * x2);
    v.setFloat("y", y1 - dotNI2 * y2);
    call.setObject(v);
}

private void _refract(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrFloat x1 = v1.getFloat("x");
    const GrFloat y1 = v1.getFloat("y");
    const GrFloat x2 = v2.getFloat("x");
    const GrFloat y2 = v2.getFloat("y");
    const GrFloat eta = call.getFloat(2);

    const GrFloat dotNI = (x1 * x2 + y1 * y2);
    GrFloat k = 1.0 - eta * eta * (1.0 - dotNI * dotNI);
    if (k < .0) {
        v.setFloat("x", 0f);
        v.setFloat("y", 0f);
    }
    else {
        const GrFloat s = (eta * dotNI + sqrt(k));
        v.setFloat("x", eta * x1 - s * x2);
        v.setFloat("y", eta * y1 - s * y2);
    }
    call.setObject(v);
}

private void _distance(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    const GrFloat px = v1.getFloat("x") - v2.getFloat("x");
    const GrFloat py = v1.getFloat("y") - v2.getFloat("y");
    call.setFloat(std.math.sqrt(px * px + py * py));
}

private void _distanceSquared(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    const GrFloat px = v1.getFloat("x") - v2.getFloat("x");
    const GrFloat py = v1.getFloat("y") - v2.getFloat("y");
    call.setFloat(px * px + py * py);
}

private void _dot(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(v1.getFloat("x") * v2.getFloat("x") + v1.getFloat("y") * v2.getFloat("y"));
}

private void _cross(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(v1.getFloat("x") * v2.getFloat("y") - v1.getFloat("y") * v2.getFloat("x"));
}

private void _normal(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", -self.getFloat("y"));
    v.setFloat("y", self.getFloat("x"));
    call.setObject(v);
}

private void _angle(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(std.math.atan2(self.getFloat("y"), self.getFloat("x")) * _radToDeg);
}

private void _rotate(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrFloat radians = call.getFloat(1) * _degToRad;
    const GrFloat px = self.getFloat("x"), py = self.getFloat("y");
    const GrFloat c = std.math.cos(radians);
    const GrFloat s = std.math.sin(radians);
    self.setFloat("x", px * c - py * s);
    self.setFloat("y", px * s + py * c);
    call.setObject(self);
}

private void _rotated(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrFloat radians = call.getFloat(1) * _degToRad;
    const GrFloat px = self.getFloat("x"), py = self.getFloat("y");
    const GrFloat c = std.math.cos(radians);
    const GrFloat s = std.math.sin(radians);

    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", px * c - py * s);
    v.setFloat("y", px * s + py * c);
    call.setObject(v);
}

private void _angled(GrCall call) {
    const GrFloat radians = call.getFloat(0) * _degToRad;
    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", std.math.cos(radians));
    v.setFloat("y", std.math.sin(radians));
    call.setObject(v);
}

private void _length(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrFloat x = self.getFloat("x");
    const GrFloat y = self.getFloat("y");
    call.setFloat(std.math.sqrt(x * x + y * y));
}

private void _lengthSquared(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrFloat x = self.getFloat("x");
    const GrFloat y = self.getFloat("y");
    call.setFloat(x * x + y * y);
}

private void _normalize(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrFloat x = self.getFloat("x");
    const GrFloat y = self.getFloat("y");
    const GrFloat len = std.math.sqrt(x * x + y * y);
    if (len == 0) {
        self.setFloat("x", len);
        self.setFloat("y", len);
        return;
    }
    self.setFloat("x", x / len);
    self.setFloat("y", y / len);
    call.setObject(self);
}

private void _normalized(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrFloat x = self.getFloat("x");
    GrFloat y = self.getFloat("y");
    const GrFloat len = std.math.sqrt(x * x + y * y);

    if (len == 0) {
        x = len;
        y = len;
        return;
    }
    x /= len;
    y /= len;

    GrObject v = call.createObject(_vector2Symbol);
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setFloat("x", x);
    v.setFloat("y", y);
    call.setObject(v);
}
