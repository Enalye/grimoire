/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.any;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private final class Any {
    union {
        GrBool bvalue;
        GrInt ivalue;
        GrReal fvalue;
        GrString svalue;
        GrPtr ovalue;
    }

    enum Type {
        boolean,
        integer,
        real_,
        string_,
        ptr_,
        otherInt,
    }

    Type type;

    string typeInfo;

    this(GrBool value_, string typeInfo_) {
        type = Type.boolean;
        ivalue = value_;
        typeInfo = typeInfo_;
    }

    this(GrInt value_, string typeInfo_) {
        type = Type.integer;
        ivalue = value_;
        typeInfo = typeInfo_;
    }

    this(GrReal value_, string typeInfo_) {
        type = Type.real_;
        fvalue = value_;
        typeInfo = typeInfo_;
    }

    this(GrString value_, string typeInfo_) {
        type = Type.string_;
        svalue = value_;
        typeInfo = typeInfo_;
    }

    this(GrPtr value_, string typeInfo_) {
        type = Type.ptr_;
        ovalue = value_;
        typeInfo = typeInfo_;
    }
}

package(grimoire.stdlib) void grLoadStdLibAny(GrLibrary library, GrLocale locale) {
    GrType anyType = library.addForeign("any");

    library.addCast(&_from_b, grBool, anyType);
    library.addCast(&_from_i, grInt, anyType);
    library.addCast(&_from_f, grReal, anyType);
    library.addCast(&_from_s, grString, anyType);

    library.addCast(&_from_o, grAny("T", (type, data) {
            return type.base == GrType.Base.list_ || type.base == GrType.Base.class_
            || type.base == GrType.Base.foreign || type.base == GrType.Base.channel;
        }), anyType);

    library.addCast(&_from_i2, grAny("T", (type, data) {
            return type.base == GrType.Base.enumeration
            || type.base == GrType.Base.function_ || type.base == GrType.Base.task;
        }), anyType);

    library.addCast(&_to_b, anyType, grBool);
    library.addCast(&_to_i, anyType, grInt);
    library.addCast(&_to_f, anyType, grReal);
    library.addCast(&_to_s, anyType, grString);

    library.addPrimitive(&_trace, "trace", [anyType]);

    // Operators
    /*static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnaryAny!op, op, [anyType], anyType);
    }*/
    /*static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryAny!op, op, [anyType, anyType], anyType);
        library.addOperator(&_opBinaryScalarAny!op, op, [anyType, grInt], anyType);
        library.addOperator(&_opBinaryScalarRightAny!op, op, [
                grReal, anyType
                ], anyType);

        library.addOperator(&_opBinaryVec2f!op, op, [vec2fType, vec2fType], vec2fType);
        library.addOperator(&_opBinaryScalarVec2f!op, op, [vec2fType, grReal], vec2fType);
        library.addOperator(&_opBinaryScalarRightVec2f!op, op, [
                grReal, vec2fType
                ], vec2fType);
    }
    static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryCompareAny!op, op, [
                anyType, anyType
                ], grBool);

        library.addOperator(&_opBinaryCompareVec2f!op, op, [
                vec2fType, vec2fType
                ], grBool);
    }*/
}

private void _from_b(GrCall call) {
    call.setForeign(new Any(call.getBool(0), call.getInType(0)));
}

private void _from_i(GrCall call) {
    call.setForeign(new Any(call.getInt(0), call.getInType(0)));
}

private void _from_f(GrCall call) {
    call.setForeign(new Any(call.getReal(0), call.getInType(0)));
}

private void _from_s(GrCall call) {
    call.setForeign(new Any(call.getString(0), call.getInType(0)));
}

private void _from_o(GrCall call) {
    call.setForeign(new Any(call.getPtr(0), call.getInType(0)));
}

private void _from_i2(GrCall call) {
    call.setForeign(new Any(call.getInt(0), call.getInType(0)));
}

private void _to_b(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case boolean:
        call.setBool(any.bvalue);
        return;
    case integer:
        call.setBool(any.ivalue != 0);
        return;
    case real_:
        call.setBool(any.fvalue != .0);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_i(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case integer:
        call.setInt(any.ivalue);
        return;
    case real_:
        call.setInt(cast(int) any.fvalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_f(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case integer:
        call.setReal(cast(real) any.ivalue);
        return;
    case real_:
        call.setReal(any.fvalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_s(GrCall call) {
    import std.conv : to;

    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case boolean:
        call.setString(to!GrString(any.bvalue));
        return;
    case integer:
        call.setString(to!GrString(any.ivalue));
        return;
    case real_:
        call.setString(to!GrString(any.fvalue));
        return;
    case string_:
        call.setString(any.svalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_o(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    if (any.typeInfo != call.getOutType(0)) {
        call.raise("ConvError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case ptr_:
        call.setPtr(any.ovalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_i2(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        call.raise("NullError");
        return;
    }
    if (any.typeInfo != call.getOutType(0)) {
        call.raise("ConvError");
        return;
    }
    switch (any.type) with (Any.Type) {
    case otherInt:
        call.setInt(any.ivalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _trace(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if (!any) {
        _stdOut("null(any)");
        return;
    }
    _stdOut("any(" ~ grGetPrettyType(grUnmangle(any.typeInfo)) ~ ")");
}
/*
private void _add_vf(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if(!any) {
        call.raise("NullError");
        return;
    }
    Any result = new Any(any);
    call.setForeign(result);
}*/

/// Operators ------------------------------------------
/*private void _opUnaryAny(string op)(GrCall call) {
    Any v = call.getForeign!(Any)(0);
    if(!v) {
        call.raise("NullError");
        return;
    }
    Any self = new Any;
    mixin("self.setInt(\"x\", " ~ op ~ "v.getInt(\"x\"));");
    call.setObject(self);
}*/

/*
private void _add_vf(GrCall call) {
    Any any = call.getForeign!(Any)(0);
    if(!any) {
        call.raise("NullError");
        return;
    }
    Any result = new Any(any);
    call.setForeign(result);
}*/
