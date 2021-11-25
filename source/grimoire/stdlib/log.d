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
    final switch (locale) with (GrLocale) {
    case en_US:
        _trueText = "true";
        _falseText = "false";
        break;
    case fr_FR:
        _trueText = "vrai";
        _falseText = "faux";
        break;
    }

    //trace
    library.addPrimitive(&_trace_i, "trace", [grInt]);
    library.addPrimitive(&_trace_b, "trace", [grBool]);
    library.addPrimitive(&_trace_f, "trace", [grFloat]);
    library.addPrimitive(&_trace_s, "trace", [grString]);
    library.addPrimitive(&_trace_ni, "trace", [grIntList]);
    library.addPrimitive(&_trace_nb, "trace", [grBoolList]);
    library.addPrimitive(&_trace_nf, "trace", [grFloatList]);
    library.addPrimitive(&_trace_ns, "trace", [grStringList]);
    library.addPrimitive(&_trace_enum, "trace", [
            grAny("T", (type, data) { return type.base == GrType.Base.enum_; })
        ]
    );
    library.addPrimitive(&_trace_chan, "trace", [
            grAny("T", (type, data) { return type.base == GrType.Base.channel; })
        ]
    );
    library.addPrimitive(&_trace_func, "trace", [
            grAny("T", (type, data) {
                return (type.base == GrType.Base.function_) || (type.base == GrType.Base.task);
            })
        ]
    );
    library.addPrimitive(&_trace_o, "trace", [
            grAny("T", (type, data) { return type.base == GrType.Base.class_; })
        ]
    );
    library.addPrimitive(&_trace_u, "trace", [
            grAny("T", (type, data) { return type.base == GrType.Base.foreign; })
        ]
    );
}

// trace
private void _trace_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _trace_b(GrCall call) {
    _stdOut(call.getBool(0) ? _trueText : _falseText);
}

private void _trace_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _trace_f(GrCall call) {
    _stdOut(to!string(call.getFloat(0)));
}

private void _trace_ni(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(ary.data));
}

private void _trace_nb(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(to!(GrBool[])(ary.data)));
}

private void _trace_nf(GrCall call) {
    auto ary = call.getFloatList(0);
    _stdOut(to!string(ary.data));
}

private void _trace_ns(GrCall call) {
    auto ary = call.getStringList(0);
    _stdOut(to!string(ary.data));
}

private void _trace_enum(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _trace_chan(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getIntChannel(0);
    _stdOut(name ~ " {" ~ to!string(channel.capacity) ~ "}");
}

private void _trace_func(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name ~ " {" ~ to!string(call.getInt(0)) ~ "}");
}

private void _trace_o(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getObject(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}

private void _trace_u(GrCall call) {
    const string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getPtr(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}
