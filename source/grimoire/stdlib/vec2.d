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
    /// Ratio to multiply with to get a value in radians from a value in degrees.
    enum double _degToRad = std.math.PI / 180.0;
    /// Ratio to multiply with to get a value in degrees from a value in radians.
    enum double _radToDeg = 180.0 / std.math.PI;
}

package void grLoadStdLibVec2(GrLibrary library) {
    GrType vec2Type = library.addClass("Vector2", ["x", "y"], [
            grReal, grReal
        ]);

    // Ctors
    library.addFunction(&_vec2_0, "Vector2", [], [vec2Type]);
    library.addFunction(&_vec2_1, "Vector2", [grReal], [vec2Type]);
    library.addFunction(&_vec2_2, "Vector2", [grReal, grReal], [
            vec2Type
        ]);

    // Trace
    library.addFunction(&_print, "print", [vec2Type]);

    // Operators
    static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnaryVec2!op, op, [vec2Type], vec2Type);
    }
    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryVec2!op, op, [vec2Type, vec2Type], vec2Type);
        library.addOperator(&_opBinaryScalarVec2!op, op, [vec2Type, grReal], vec2Type);
        library.addOperator(&_opBinaryScalarRightVec2!op, op, [
                grReal, vec2Type
            ], vec2Type);
    }
    static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryCompareVec2!op, op, [
                vec2Type, vec2Type
            ], grBool);
    }

    // Utility
    library.addFunction(&_vec2_0, "Vector2_zero", [], [vec2Type]);
    library.addFunction(&_halfVec2, "Vector2_half", [], [vec2Type]);
    library.addFunction(&_oneVec2, "Vector2_one", [], [vec2Type]);
    library.addFunction(&_upVec2, "Vector2_up", [], [vec2Type]);
    library.addFunction(&_downVec2, "Vector2_down", [], [vec2Type]);
    library.addFunction(&_leftVec2, "Vector2_left", [], [vec2Type]);
    library.addFunction(&_rightVec2, "Vector2_right", [], [vec2Type]);

    library.addFunction(&_unpackVec2, "unpack", [vec2Type], [
            grReal, grReal
        ]);

    library.addFunction(&_abs, "abs", [vec2Type], [vec2Type]);
    library.addFunction(&_ceil, "abs", [vec2Type], [vec2Type]);
    library.addFunction(&_floor, "floor", [vec2Type], [vec2Type]);
    library.addFunction(&_round, "round", [vec2Type], [vec2Type]);

    library.addFunction(&_isZeroVec2, "zero?", [vec2Type], [grBool]);

    // Operations
    library.addFunction(&_sumVec2, "sum", [vec2Type], [grReal]);
    library.addFunction(&_sign, "sign", [vec2Type], [vec2Type]);

    library.addFunction(&_lerp, "lerp", [vec2Type, vec2Type, grReal], [
            vec2Type
        ]);
    library.addFunction(&_approach, "approach", [
            vec2Type, vec2Type, grReal
        ], [vec2Type]);

    library.addFunction(&_reflect, "reflect", [vec2Type, vec2Type], [
            vec2Type
        ]);
    library.addFunction(&_refract, "refract", [vec2Type, vec2Type, grReal], [
            vec2Type
        ]);

    library.addFunction(&_distance, "distance", [vec2Type, vec2Type], [
            grReal
        ]);
    library.addFunction(&_distanceSquared, "distance2", [
            vec2Type, vec2Type
        ], [
            grReal
        ]);
    library.addFunction(&_dot, "dot", [vec2Type, vec2Type], [grReal]);
    library.addFunction(&_cross, "cross", [vec2Type, vec2Type], [
            grReal
        ]);
    library.addFunction(&_normal, "normal", [vec2Type], [vec2Type]);
    library.addFunction(&_angle, "angle", [vec2Type], [grReal]);
    library.addFunction(&_rotate, "rotate", [vec2Type, grReal], [
            vec2Type
        ]);
    library.addFunction(&_rotated, "rotated", [vec2Type, grReal], [
            vec2Type
        ]);
    library.addFunction(&_angled, "Vector2_angled", [grReal], [vec2Type]);
    library.addFunction(&_length, "length", [vec2Type], [grReal]);
    library.addFunction(&_lengthSquared, "length2", [vec2Type], [
            grReal
        ]);
    library.addFunction(&_normalize, "normalize", [vec2Type], [
            vec2Type
        ]);
    library.addFunction(&_normalized, "normalized", [vec2Type], [
            vec2Type
        ]);
}

// Ctors ------------------------------------------
private void _vec2_0(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", 0f);
    self.setReal("y", 0f);
    call.setObject(self);
}

private void _vec2_1(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    const GrReal value = call.getReal(0);
    self.setReal("x", value);
    self.setReal("y", value);
    call.setObject(self);
}

private void _vec2_2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", call.getReal(0));
    self.setReal("y", call.getReal(1));
    call.setObject(self);
}

// Print ------------------------------------------
private void _print(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Vec2)");
        return;
    }
    _stdOut("Vec2(" ~ to!GrString(self.getReal("x")) ~ ", " ~ to!GrString(
            self.getReal("y")) ~ ")");
}

/// Operators ------------------------------------------
private void _opUnaryVec2(string op)(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"x\", " ~ op ~ "v.getReal(\"x\"));");
    mixin("self.setReal(\"y\", " ~ op ~ "v.getReal(\"y\"));");
    call.setObject(self);
}

private void _opBinaryVec2(string op)(GrCall call) {
    GrObject self = call.createObject("Vector2");
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
    mixin("self.setReal(\"x\", v1.getReal(\"x\")" ~ op ~ "v2.getReal(\"x\"));");
    mixin("self.setReal(\"y\", v1.getReal(\"y\")" ~ op ~ "v2.getReal(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2(string op)(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    const GrReal s = call.getReal(1);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"x\", v.getReal(\"x\")" ~ op ~ "s);");
    mixin("self.setReal(\"y\", v.getReal(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2(string op)(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject v = call.getObject(0);
    const GrReal s = call.getReal(1);
    if (!v) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"x\", s" ~ op ~ "v.getReal(\"x\"));");
    mixin("self.setReal(\"y\", s" ~ op ~ "v.getReal(\"y\"));");
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
        v1.getReal(\"x\")"
            ~ op ~ "v2.getReal(\"x\") &&
        v1.getReal(\"y\")"
            ~ op
            ~ "v2.getReal(\"y\"));");
}

// Utility ------------------------------------------
private void _oneVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", 1f);
    self.setReal("y", 1f);
    call.setObject(self);
}

private void _halfVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", .5f);
    self.setReal("y", .5f);
    call.setObject(self);
}

private void _upVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("y", 1f);
    call.setObject(self);
}

private void _downVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("y", -1f);
    call.setObject(self);
}

private void _leftVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", -1f);
    call.setObject(self);
}

private void _rightVec2(GrCall call) {
    GrObject self = call.createObject("Vector2");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("x", 1f);
    call.setObject(self);
}

private void _unpackVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setReal(self.getReal("x"));
    call.setReal(self.getReal("y"));
}

private void _isZeroVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setBool(self.getReal("x") == 0f && self.getReal("y") == 0f);
}

// Operations ------------------------------------------
private void _abs(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", abs(self.getReal("y")));
    v.setReal("y", abs(self.getReal("x")));
    call.setObject(v);
}

private void _ceil(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", ceil(self.getReal("y")));
    v.setReal("y", ceil(self.getReal("x")));
    call.setObject(v);
}

private void _floor(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", floor(self.getReal("y")));
    v.setReal("y", floor(self.getReal("x")));
    call.setObject(v);
}

private void _round(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", round(self.getReal("y")));
    v.setReal("y", round(self.getReal("x")));
    call.setObject(v);
}

private void _sumVec2(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setReal(self.getReal("x") + self.getReal("y"));
}

private void _sign(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", self.getReal("x") >= 0f ? 1f : -1f);
    v.setReal("y", self.getReal("y") >= 0f ? 1f : -1f);
    call.setObject(v);
}

private void _lerp(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    const GrReal weight = call.getReal(2);
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", v2.getReal("x") * weight + v1.getReal("x") * (1f - weight));
    v.setReal("y", v2.getReal("y") * weight + v1.getReal("y") * (1f - weight));
    call.setObject(v);
}

private void _approach(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrReal x1 = v1.getReal("x");
    const GrReal y1 = v1.getReal("y");
    const GrReal x2 = v2.getReal("x");
    const GrReal y2 = v2.getReal("y");
    const GrReal step = call.getReal(2);
    v.setReal("x", x1 > x2 ? max(x1 - step, x2) : min(x1 + step, x2));
    v.setReal("y", y1 > y2 ? max(y1 - step, y2) : min(y1 + step, y2));
    call.setObject(v);
}

private void _reflect(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrReal x1 = v1.getReal("x");
    const GrReal y1 = v1.getReal("y");
    const GrReal x2 = v2.getReal("x");
    const GrReal y2 = v2.getReal("y");
    const GrReal dotNI2 = 2.0 * x1 * x2 + y1 * y2;
    v.setReal("x", x1 - dotNI2 * x2);
    v.setReal("y", y1 - dotNI2 * y2);
    call.setObject(v);
}

private void _refract(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    const GrReal x1 = v1.getReal("x");
    const GrReal y1 = v1.getReal("y");
    const GrReal x2 = v2.getReal("x");
    const GrReal y2 = v2.getReal("y");
    const GrReal eta = call.getReal(2);

    const GrReal dotNI = (x1 * x2 + y1 * y2);
    GrReal k = 1.0 - eta * eta * (1.0 - dotNI * dotNI);
    if (k < .0) {
        v.setReal("x", 0f);
        v.setReal("y", 0f);
    }
    else {
        const GrReal s = (eta * dotNI + sqrt(k));
        v.setReal("x", eta * x1 - s * x2);
        v.setReal("y", eta * y1 - s * y2);
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
    const GrReal px = v1.getReal("x") - v2.getReal("x");
    const GrReal py = v1.getReal("y") - v2.getReal("y");
    call.setReal(std.math.sqrt(px * px + py * py));
}

private void _distanceSquared(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    const GrReal px = v1.getReal("x") - v2.getReal("x");
    const GrReal py = v1.getReal("y") - v2.getReal("y");
    call.setReal(px * px + py * py);
}

private void _dot(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    call.setReal(v1.getReal("x") * v2.getReal("x") + v1.getReal("y") * v2.getReal("y"));
}

private void _cross(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise(_paramError);
        return;
    }
    call.setReal(v1.getReal("x") * v2.getReal("y") - v1.getReal("y") * v2.getReal("x"));
}

private void _normal(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", -self.getReal("y"));
    v.setReal("y", self.getReal("x"));
    call.setObject(v);
}

private void _angle(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setReal(std.math.atan2(self.getReal("y"), self.getReal("x")) * _radToDeg);
}

private void _rotate(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrReal radians = call.getReal(1) * _degToRad;
    const GrReal px = self.getReal("x"), py = self.getReal("y");
    const GrReal c = std.math.cos(radians);
    const GrReal s = std.math.sin(radians);
    self.setReal("x", px * c - py * s);
    self.setReal("y", px * s + py * c);
    call.setObject(self);
}

private void _rotated(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrReal radians = call.getReal(1) * _degToRad;
    const GrReal px = self.getReal("x"), py = self.getReal("y");
    const GrReal c = std.math.cos(radians);
    const GrReal s = std.math.sin(radians);

    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", px * c - py * s);
    v.setReal("y", px * s + py * c);
    call.setObject(v);
}

private void _angled(GrCall call) {
    const GrReal radians = call.getReal(0) * _degToRad;
    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", std.math.cos(radians));
    v.setReal("y", std.math.sin(radians));
    call.setObject(v);
}

private void _length(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrReal x = self.getReal("x");
    const GrReal y = self.getReal("y");
    call.setReal(std.math.sqrt(x * x + y * y));
}

private void _lengthSquared(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrReal x = self.getReal("x");
    const GrReal y = self.getReal("y");
    call.setReal(x * x + y * y);
}

private void _normalize(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    const GrReal x = self.getReal("x");
    const GrReal y = self.getReal("y");
    const GrReal len = std.math.sqrt(x * x + y * y);
    if (len == 0) {
        self.setReal("x", len);
        self.setReal("y", len);
        return;
    }
    self.setReal("x", x / len);
    self.setReal("y", y / len);
    call.setObject(self);
}

private void _normalized(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    GrReal x = self.getReal("x");
    GrReal y = self.getReal("y");
    const GrReal len = std.math.sqrt(x * x + y * y);

    if (len == 0) {
        x = len;
        y = len;
        return;
    }
    x /= len;
    y /= len;

    GrObject v = call.createObject("Vector2");
    if (!v) {
        call.raise(_classError);
        return;
    }
    v.setReal("x", x);
    v.setReal("y", y);
    call.setObject(v);
}
