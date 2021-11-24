/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.vec2;

import std.conv : to;
import std.math;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private {
    string _vec2iTypeName, _vec2fTypeName;
    /// Ratio to multiply with to get a value in radians from a value in degrees.
    enum double _degToRad = std.math.PI / 180.0;
    /// Ratio to multiply with to get a value in degrees from a value in radians.
    enum double _radToDeg = 180.0 / std.math.PI;
}

package void grLoadStdLibVec2(GrLibrary library, GrLocale locale) {
    library.addClass("Vec2", ["x", "y"], [
            grAny("T", (t, d) {
                return (t.baseType == grInt) || (t.baseType == grFloat);
            }), grAny("T")
            ], ["T"]);

    GrType vec2iType = library.addTypeAlias("Vec2i", grGetClassType("Vec2", [
                grInt
            ]));
    GrType vec2fType = library.addTypeAlias("Vec2f", grGetClassType("Vec2", [
                grFloat
            ]));

    _vec2iTypeName = grMangleComposite("Vec2", [grInt]);
    _vec2fTypeName = grMangleComposite("Vec2", [grFloat]);

    // Ctors
    library.addPrimitive(&_vec2i_1, "Vec2", [grInt], [vec2iType]);
    library.addPrimitive(&_vec2f_1, "Vec2", [grFloat], [vec2fType]);
    library.addPrimitive(&_vec2i_2, "Vec2", [grInt, grInt], [vec2iType]);
    library.addPrimitive(&_vec2f_2, "Vec2", [grFloat, grFloat], [vec2fType]);

    library.addPrimitive(&_vec2i_0, "Vec2i", [], [vec2iType]);
    library.addPrimitive(&_vec2i_1, "Vec2i", [grInt], [vec2iType]);
    library.addPrimitive(&_vec2i_2, "Vec2i", [grInt, grInt], [vec2iType]);

    library.addPrimitive(&_vec2f_0, "Vec2f", [], [vec2fType]);
    library.addPrimitive(&_vec2f_1, "Vec2f", [grFloat], [vec2fType]);
    library.addPrimitive(&_vec2f_2, "Vec2f", [grFloat, grFloat], [vec2fType]);

    // Cast
    library.addCast(&_vec2i_vec2f, vec2iType, vec2fType);
    library.addCast(&_vec2f_vec2i, vec2fType, vec2iType);

    // Trace
    library.addPrimitive(&_trace_i, "trace", [vec2iType]);
    library.addPrimitive(&_trace_f, "trace", [vec2fType]);

    // Operators
    static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnaryVec2i!op, op, [vec2iType], vec2iType);
        library.addOperator(&_opUnaryVec2f!op, op, [vec2fType], vec2fType);
    }
    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryVec2i!op, op, [vec2iType, vec2iType], vec2iType);
        library.addOperator(&_opBinaryScalarVec2i!op, op, [vec2iType, grInt], vec2iType);
        library.addOperator(&_opBinaryScalarRightVec2i!op, op, [
                grInt, vec2iType
                ], vec2iType);

        library.addOperator(&_opBinaryVec2f!op, op, [vec2fType, vec2fType], vec2fType);
        library.addOperator(&_opBinaryScalarVec2f!op, op, [vec2fType, grFloat], vec2fType);
        library.addOperator(&_opBinaryScalarRightVec2f!op, op, [
                grFloat, vec2fType
                ], vec2fType);
    }
    static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryCompareVec2i!op, op, [
                vec2iType, vec2iType
                ], grBool);

        library.addOperator(&_opBinaryCompareVec2f!op, op, [
                vec2fType, vec2fType
                ], grBool);
    }

    // Utility
    library.addPrimitive(&_oneVec2i, "Vec2i_one", [], [vec2iType]);
    library.addPrimitive(&_oneVec2f, "Vec2f_one", [], [vec2fType]);
    library.addPrimitive(&_halfVec2f, "Vec2f_half", [], [vec2fType]);
    library.addPrimitive(&_upVec2i, "Vec2i_up", [], [vec2iType]);
    library.addPrimitive(&_upVec2f, "Vec2f_up", [], [vec2fType]);
    library.addPrimitive(&_downVec2i, "Vec2i_down", [], [vec2iType]);
    library.addPrimitive(&_downVec2f, "Vec2f_down", [], [vec2fType]);
    library.addPrimitive(&_leftVec2i, "Vec2i_left", [], [vec2iType]);
    library.addPrimitive(&_leftVec2f, "Vec2f_left", [], [vec2fType]);
    library.addPrimitive(&_rightVec2i, "Vec2i_right", [], [vec2iType]);
    library.addPrimitive(&_rightVec2f, "Vec2f_right", [], [vec2fType]);

    library.addPrimitive(&_unpackVec2i, "unpack", [vec2iType], [grInt, grInt]);
    library.addPrimitive(&_unpackVec2f, "unpack", [vec2fType], [
            grFloat, grFloat
            ]);

    library.addPrimitive(&_isZeroVec2i, "zero?", [vec2iType], [grBool]);
    library.addPrimitive(&_isZeroVec2f, "zero?", [vec2fType], [grBool]);

    // Operations
    library.addPrimitive(&_sumVec2i, "sum", [vec2iType], [grInt]);
    library.addPrimitive(&_sumVec2f, "sum", [vec2fType], [grFloat]);
    library.addPrimitive(&_distanceVec2i, "distance", [vec2iType, vec2iType], [
            grFloat
            ]);
    library.addPrimitive(&_distanceVec2f, "distance", [vec2fType, vec2fType], [
            grFloat
            ]);
    library.addPrimitive(&_distanceVec2i, "distanceSq", [vec2iType, vec2iType], [
            grFloat
            ]);
    library.addPrimitive(&_distanceVec2f, "distanceSq", [vec2fType, vec2fType], [
            grFloat
            ]);
    library.addPrimitive(&_dotVec2i, "dot", [vec2iType, vec2iType], [grFloat]);
    library.addPrimitive(&_dotVec2f, "dot", [vec2fType, vec2fType], [grFloat]);
    library.addPrimitive(&_crossVec2i, "cross", [vec2iType, vec2iType], [
            grFloat
            ]);
    library.addPrimitive(&_crossVec2f, "cross", [vec2fType, vec2fType], [
            grFloat
            ]);
    library.addPrimitive(&_normalVec2i, "normal", [vec2iType], [vec2iType]);
    library.addPrimitive(&_normalVec2f, "normal", [vec2fType], [vec2fType]);
    library.addPrimitive(&_angleVec2i, "angle", [vec2iType], [grFloat]);
    library.addPrimitive(&_angleVec2f, "angle", [vec2fType], [grFloat]);
    library.addPrimitive(&_rotateVec2f, "rotate!", [vec2fType, grFloat], [
            vec2fType
            ]);
    library.addPrimitive(&_rotatedVec2f, "rotate", [vec2fType, grFloat], [
            vec2fType
            ]);
    library.addPrimitive(&_angledVec2f, "Vec2f_angled", [grFloat], [vec2fType]);
    library.addPrimitive(&_lengthVec2i, "length", [vec2iType], [grFloat]);
    library.addPrimitive(&_lengthVec2f, "length", [vec2fType], [grFloat]);
    library.addPrimitive(&_lengthSquaredVec2i, "lengthSq", [vec2iType], [
            grFloat
            ]);
    library.addPrimitive(&_lengthSquaredVec2f, "lengthSq", [vec2fType], [
            grFloat
            ]);
    library.addPrimitive(&_normalizeVec2f, "normalize!", [vec2fType], [
            vec2fType
            ]);
    library.addPrimitive(&_normalizedVec2f, "normalize", [vec2fType], [
            vec2fType
            ]);
}

// Ctors ------------------------------------------
private void _vec2i_0(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("x", 0);
    self.setInt("y", 0);
    call.setObject(self);
}

private void _vec2i_1(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    const GrInt value = call.getInt(0);
    self.setInt("x", value);
    self.setInt("y", value);
    call.setObject(self);
}

private void _vec2i_2(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("x", call.getInt(0));
    self.setInt("y", call.getInt(1));
    call.setObject(self);
}

private void _vec2f_0(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", 0f);
    self.setFloat("y", 0f);
    call.setObject(self);
}

private void _vec2f_1(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    const GrFloat value = call.getFloat(0);
    self.setFloat("x", value);
    self.setFloat("y", value);
    call.setObject(self);
}

private void _vec2f_2(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", call.getFloat(0));
    self.setFloat("y", call.getFloat(1));
    call.setObject(self);
}

// Cast ------------------------------------------
private void _vec2i_vec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    GrObject v = call.createObject(_vec2fTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setFloat("x", cast(GrFloat) self.getInt("x"));
    v.setFloat("y", cast(GrFloat) self.getInt("y"));
    call.setObject(v);
}

private void _vec2f_vec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    GrObject v = call.createObject(_vec2iTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setInt("x", cast(GrInt) self.getFloat("x"));
    v.setInt("y", cast(GrInt) self.getFloat("y"));
    call.setObject(v);
}

// Trace ------------------------------------------
private void _trace_i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Vec2i)\n");
        return;
    }
    _stdOut("Vec2(" ~ to!GrString(self.getInt("x")) ~ ", " ~ to!GrString(self.getInt("y")) ~ ")\n");
}

private void _trace_f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Vec2f)\n");
        return;
    }
    _stdOut("Vec2(" ~ to!GrString(self.getFloat("x")) ~ ", " ~ to!GrString(
            self.getFloat("y")) ~ ")\n");
}

/// Operators ------------------------------------------
private void _opUnaryVec2i(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setInt(\"x\", " ~ op ~ "v.getInt(\"x\"));");
    mixin("self.setInt(\"y\", " ~ op ~ "v.getInt(\"y\"));");
    call.setObject(self);
}

private void _opUnaryVec2f(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"x\", " ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", " ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryVec2i(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    mixin("self.setInt(\"x\", v1.getInt(\"x\")" ~ op ~ "v2.getInt(\"x\"));");
    mixin("self.setInt(\"y\", v1.getInt(\"y\")" ~ op ~ "v2.getInt(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2i(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    const GrInt s = call.getInt(1);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setInt(\"x\", v.getInt(\"x\")" ~ op ~ "s);");
    mixin("self.setInt(\"y\", v.getInt(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2i(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    const GrInt s = call.getInt(1);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setInt(\"x\", s" ~ op ~ "v.getInt(\"x\"));");
    mixin("self.setInt(\"y\", s" ~ op ~ "v.getInt(\"y\"));");
    call.setObject(self);
}

private void _opBinaryCompareVec2i(string op)(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    mixin("call.setBool(
        v1.getInt(\"x\")" ~ op ~ "v2.getInt(\"x\") &&
        v1.getInt(\"y\")" ~ op ~ "v2.getInt(\"y\"));");
}

private void _opBinaryVec2f(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"x\", v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2f(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"x\", v.getFloat(\"x\")" ~ op ~ "s);");
    mixin("self.setFloat(\"y\", v.getFloat(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2f(string op)(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject v = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!v) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"x\", s" ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", s" ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryCompareVec2f(string op)(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    mixin("call.setBool(
        v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\") &&
        v1.getFloat(\"y\")" ~ op
            ~ "v2.getFloat(\"y\"));");
}

// Utility ------------------------------------------
private void _oneVec2i(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("x", 1);
    self.setInt("y", 1);
    call.setObject(self);
}

private void _oneVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", 1f);
    self.setFloat("y", 1f);
    call.setObject(self);
}

private void _halfVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", .5f);
    self.setFloat("y", .5f);
    call.setObject(self);
}

private void _upVec2i(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("y", 1);
    call.setObject(self);
}

private void _upVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("y", 1f);
    call.setObject(self);
}

private void _downVec2i(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("y", -1);
    call.setObject(self);
}

private void _downVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("y", -1f);
    call.setObject(self);
}

private void _leftVec2i(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("x", -1);
    call.setObject(self);
}

private void _leftVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", -1f);
    call.setObject(self);
}

private void _rightVec2i(GrCall call) {
    GrObject self = call.createObject(_vec2iTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setInt("x", 1);
    call.setObject(self);
}

private void _rightVec2f(GrCall call) {
    GrObject self = call.createObject(_vec2fTypeName);
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("x", 1f);
    call.setObject(self);
}

private void _unpackVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setInt(self.getInt("x"));
    call.setInt(self.getInt("y"));
}

private void _unpackVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setFloat(self.getFloat("x"));
    call.setFloat(self.getFloat("y"));
}

private void _isZeroVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setBool(self.getInt("x") == 0 && self.getInt("y") == 0);
}

private void _isZeroVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setBool(self.getFloat("x") == 0f && self.getFloat("y") == 0f);
}

// Operations ------------------------------------------
private void _sumVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setInt(self.getInt("x") + self.getInt("y"));
}

private void _sumVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setFloat(self.getFloat("x") + self.getFloat("y"));
}

private void _distanceVec2i(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    const GrFloat px = v1.getInt("x") - v2.getInt("x");
    const GrFloat py = v1.getInt("y") - v2.getInt("y");
    call.setFloat(std.math.sqrt(px * px + py * py));
}

private void _distanceVec2f(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    const GrFloat px = v1.getFloat("x") - v2.getFloat("x");
    const GrFloat py = v1.getFloat("y") - v2.getFloat("y");
    call.setFloat(std.math.sqrt(px * px + py * py));
}

private void _distanceSquaredVec2i(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    const GrFloat px = v1.getInt("x") - v2.getInt("x");
    const GrFloat py = v1.getInt("y") - v2.getInt("y");
    call.setFloat(px * px + py * py);
}

private void _distanceSquaredVec2f(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    const GrFloat px = v1.getFloat("x") - v2.getFloat("x");
    const GrFloat py = v1.getFloat("y") - v2.getFloat("y");
    call.setFloat(px * px + py * py);
}

private void _dotVec2i(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    call.setFloat(v1.getInt("x") * v2.getInt("x") + v1.getInt("y") * v2.getInt("y"));
}

private void _dotVec2f(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    call.setFloat(v1.getFloat("x") * v2.getFloat("x") + v1.getFloat("y") * v2.getFloat("y"));
}

private void _crossVec2i(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    call.setFloat(v1.getInt("x") * v2.getInt("y") - v1.getInt("y") * v2.getInt("x"));
}

private void _crossVec2f(GrCall call) {
    GrObject v1 = call.getObject(0);
    GrObject v2 = call.getObject(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    call.setFloat(v1.getFloat("x") * v2.getFloat("y") - v1.getFloat("y") * v2.getFloat("x"));
}

private void _normalVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    GrObject v = call.createObject(_vec2iTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setInt("x", -self.getInt("y"));
    v.setInt("y", self.getInt("x"));
    call.setObject(v);
}

private void _normalVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    GrObject v = call.createObject(_vec2fTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setFloat("x", -self.getFloat("y"));
    v.setFloat("y", self.getFloat("x"));
    call.setObject(v);
}

private void _angleVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setFloat(std.math.atan2(cast(GrFloat) self.getInt("y"),
            cast(GrFloat) self.getInt("x")) * _radToDeg);
}

private void _angleVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setFloat(std.math.atan2(self.getFloat("y"), self.getFloat("x")) * _radToDeg);
}

private void _rotateVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
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

private void _rotatedVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    const GrFloat radians = call.getFloat(1) * _degToRad;
    const GrFloat px = self.getFloat("x"), py = self.getFloat("y");
    const GrFloat c = std.math.cos(radians);
    const GrFloat s = std.math.sin(radians);

    GrObject v = call.createObject(_vec2fTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setFloat("x", px * c - py * s);
    v.setFloat("y", px * s + py * c);
    call.setObject(v);
}

private void _angledVec2f(GrCall call) {
    const GrFloat radians = call.getFloat(0) * _degToRad;
    GrObject v = call.createObject(_vec2fTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setFloat("x", std.math.cos(radians));
    v.setFloat("y", std.math.sin(radians));
    call.setObject(v);
}

private void _lengthVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    const GrInt x = self.getInt("x");
    const GrInt y = self.getInt("y");
    call.setFloat(std.math.sqrt(cast(GrFloat)(x * x + y * y)));
}

private void _lengthVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    const GrFloat x = self.getFloat("x");
    const GrFloat y = self.getFloat("y");
    call.setFloat(std.math.sqrt(x * x + y * y));
}

private void _lengthSquaredVec2i(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    const GrInt x = self.getInt("x");
    const GrInt y = self.getInt("y");
    call.setFloat(x * x + y * y);
}

private void _lengthSquaredVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    const GrFloat x = self.getFloat("x");
    const GrFloat y = self.getFloat("y");
    call.setFloat(x * x + y * y);
}

private void _normalizeVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
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

private void _normalizedVec2f(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
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

    GrObject v = call.createObject(_vec2fTypeName);
    if (!v) {
        call.raise("UnknownClassError");
        return;
    }
    v.setFloat("x", x);
    v.setFloat("y", y);
    call.setObject(v);
}
