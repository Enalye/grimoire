/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.dynamic;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private final class Dynamic {
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
        ptr_
    }

    Type type;

    string typeInfo;

    this() {
    }

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

package(grimoire.stdlib) void grLoadStdLibDynamic(GrLibrary library) {
    GrType dynamicType = library.addForeign("dynamic");

    library.addCast(&_from_b, grBool, dynamicType);
    library.addCast(&_from_i, grInt, dynamicType);
    library.addCast(&_from_f, grReal, dynamicType);
    library.addCast(&_from_s, grString, dynamicType);

    /*library.addCast(&_from_o, grDynamic("T", (type, data) {
            return type.base == GrType.Base.array || type.base == GrType.Base.class_
            || type.base == GrType.Base.foreign || type.base == GrType.Base.channel;
        }), dynamicType);

    library.addCast(&_from_i2, grDynamic("T", (type, data) {
            return type.base == GrType.Base.enum_
            || type.base == GrType.Base.function_ || type.base == GrType.Base.task;
        }), dynamicType);*/

    library.addCast(&_to_b, dynamicType, grBool);
    library.addCast(&_to_i, dynamicType, grInt);
    library.addCast(&_to_f, dynamicType, grReal);
    library.addCast(&_to_s, dynamicType, grString);

    library.addFunction(&_print, "print", [dynamicType]);

    // Operators
    static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnaryDynamic!op, op, [dynamicType], dynamicType);
    }
    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryDynamic!op, op, [dynamicType, dynamicType], dynamicType);
        /*library.addOperator(&_opBinaryScalarDynamic!op, op, [dynamicType, grInt], dynamicType);
        library.addOperator(&_opBinaryScalarRightDynamic!op, op, [
                grReal, dynamicType
            ], dynamicType);

        library.addOperator(&_opBinaryVec2f!op, op, [vec2fType, vec2fType], vec2fType);
        library.addOperator(&_opBinaryScalarVec2f!op, op, [vec2fType, grReal], vec2fType);
        library.addOperator(&_opBinaryScalarRightVec2f!op, op, [
                grReal, vec2fType
            ], vec2fType);*/
    }
    /+static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryCompareDynamic!op, op, [
                dynamicType, dynamicType
            ], grBool);

        library.addOperator(&_opBinaryCompareVec2f!op, op, [
                vec2fType, vec2fType
            ], grBool);
    }+/
}

private void _from_b(GrCall call) {
    call.setForeign(new Dynamic(call.getBool(0), call.getInType(0)));
}

private void _from_i(GrCall call) {
    call.setForeign(new Dynamic(call.getInt(0), call.getInType(0)));
}

private void _from_f(GrCall call) {
    call.setForeign(new Dynamic(call.getReal(0), call.getInType(0)));
}

private void _from_s(GrCall call) {
    call.setForeign(new Dynamic(call.getString(0), call.getInType(0)));
}

private void _from_o(GrCall call) {
    call.setForeign(new Dynamic(call.getPtr(0), call.getInType(0)));
}

private void _from_i2(GrCall call) {
    call.setForeign(new Dynamic(call.getInt(0), call.getInType(0)));
}

private void _to_b(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case boolean:
        call.setBool(dynamic.bvalue);
        return;
    case integer:
        call.setBool(dynamic.ivalue != 0);
        return;
    case real_:
        call.setBool(dynamic.fvalue != .0);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_i(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case integer:
        call.setInt(dynamic.ivalue);
        return;
    case real_:
        call.setInt(cast(int) dynamic.fvalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_f(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case integer:
        call.setReal(cast(real) dynamic.ivalue);
        return;
    case real_:
        call.setReal(dynamic.fvalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_s(GrCall call) {
    import std.conv : to;

    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case boolean:
        call.setString(to!GrString(dynamic.bvalue));
        return;
    case integer:
        call.setString(to!GrString(dynamic.ivalue));
        return;
    case real_:
        call.setString(to!GrString(dynamic.fvalue));
        return;
    case string_:
        call.setString(dynamic.svalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_o(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    if (dynamic.typeInfo != call.getOutType(0)) {
        call.raise("ConvError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case ptr_:
        call.setPtr(dynamic.ovalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _to_i2(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    if (dynamic.typeInfo != call.getOutType(0)) {
        call.raise("ConvError");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case integer:
        call.setInt(dynamic.ivalue);
        return;
    default:
        call.raise("ConvError");
        return;
    }
}

private void _print(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        _stdOut("null(dynamic)");
        return;
    }
    switch (dynamic.type) with (Dynamic.Type) {
    case boolean:
        _stdOut(dynamic.bvalue ? "true" : "false");
        break;
    case integer:
        _stdOut(to!string(dynamic.ivalue));
        break;
    case real_:
        _stdOut(to!string(dynamic.fvalue));
        break;
    case string_:
        _stdOut(dynamic.svalue);
        break;
    case ptr_:
    default:
        _stdOut("dynamic(" ~ grGetPrettyType(grUnmangle(dynamic.typeInfo)) ~ ")");
        break;
    }
}
/*
private void _add_vf(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if(!dynamic) {
        call.raise("NullError");
        return;
    }
    Dynamic result = new Dynamic(dynamic);
    call.setForeign(result);
}*/

/// Operators ------------------------------------------
private void _opUnaryDynamic(string op)(GrCall call) {
    Dynamic v = call.getForeign!(Dynamic)(0);
    if (!v) {
        call.raise("NullError");
        return;
    }
    Dynamic self = new Dynamic;
    self.type = v.type;
    self.typeInfo = v.typeInfo;

    switch(v.type) with(Dynamic.Type) {
    case integer:
        mixin("self.ivalue = " ~ op ~ "v.ivalue;");
        break;
    case real_:
        mixin("self.fvalue = " ~ op ~ "v.fvalue;");
        break;
    default:
        call.raise("ConvError");
        return;
    }
    call.setForeign(self);
}

private void _opBinaryDynamic(string op)(GrCall call) {
    Dynamic v1 = call.getForeign!(Dynamic)(0);
    Dynamic v2 = call.getForeign!(Dynamic)(1);
    if (!v1 || !v2) {
        call.raise("NullError");
        return;
    }
    Dynamic self = new Dynamic;
    self.type = v1.type;
    self.typeInfo = v1.typeInfo;

    switch(v1.type) with(Dynamic.Type) {
    case integer:
        mixin("self.ivalue = v1.ivalue " ~ op ~ "v2.ivalue;");
        break;
    case real_:
        mixin("self.fvalue = v1.fvalue " ~ op ~ "v2.fvalue;");
        break;
    default:
        call.raise("ConvError");
        return;
    }
    call.setForeign(self);
}
/+
private void _add_vf(GrCall call) {
    Dynamic dynamic = call.getForeign!(Dynamic)(0);
    if (!dynamic) {
        call.raise("NullError");
        return;
    }
    Dynamic result = new Dynamic(dynamic);
    call.setForeign(result);
}
+/
