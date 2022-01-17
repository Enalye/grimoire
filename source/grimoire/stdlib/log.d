/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.log;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private {
    string _trueText, _falseText;
}

package(grimoire.stdlib) void grLoadStdLibLog(GrLibrary library, GrLocale locale) {
    string writeSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _trueText = "true";
        _falseText = "false";
        writeSymbol = "write";
        break;
    case fr_FR:
        _trueText = "vrai";
        _falseText = "faux";
        writeSymbol = "écris";
        break;
    }

    //write
    library.addPrimitive(&_write_i, writeSymbol, [grInt]);
    library.addPrimitive(&_write_b, writeSymbol, [grBool]);
    library.addPrimitive(&_write_f, writeSymbol, [grFloat]);
    library.addPrimitive(&_write_s, writeSymbol, [grString]);
    library.addPrimitive(&_write_ni, writeSymbol, [grIntList]);
    library.addPrimitive(&_write_nb, writeSymbol, [grBoolList]);
    library.addPrimitive(&_write_nf, writeSymbol, [grFloatList]);
    library.addPrimitive(&_write_ns, writeSymbol, [grStringList]);
    library.addPrimitive(&_write_enum, writeSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.enum_; })
        ]
    );
    library.addPrimitive(&_write_chan, writeSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.channel; })
        ]
    );
    library.addPrimitive(&_write_func, writeSymbol, [
            grAny("T", (type, data) {
                return (type.base == GrType.Base.function_) || (type.base == GrType.Base.task);
            })
        ]
    );
    library.addPrimitive(&_write_o, writeSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.class_; })
        ]
    );
    library.addPrimitive(&_write_u, writeSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.foreign; })
        ]
    );
}

// write
private void _write_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _write_b(GrCall call) {
    _stdOut(call.getBool(0) ? _trueText : _falseText);
}

private void _write_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _write_f(GrCall call) {
    _stdOut(to!string(call.getFloat(0)));
}

private void _write_ni(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(ary.data));
}

private void _write_nb(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(to!(GrBool[])(ary.data)));
}

private void _write_nf(GrCall call) {
    auto ary = call.getFloatList(0);
    _stdOut(to!string(ary.data));
}

private void _write_ns(GrCall call) {
    auto ary = call.getStringList(0);
    _stdOut(to!string(ary.data));
}

private void _write_enum(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _write_chan(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getIntChannel(0);
    _stdOut(name ~ " {" ~ to!string(channel.capacity) ~ "}");
}

private void _write_func(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name ~ " {" ~ to!string(call.getInt(0)) ~ "}");
}

private void _write_o(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getObject(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}

private void _write_u(GrCall call) {
    const string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getPtr(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}
