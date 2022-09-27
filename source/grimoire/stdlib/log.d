/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.log;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibLog(GrLibrary library) {
    //print
    library.addFunction(&_print_i, "print", [grInt]);
    library.addFunction(&_print_ix, "print", [grOptional(grInt)]);
    library.addFunction(&_print_b, "print", [grBool]);
    library.addFunction(&_print_r, "print", [grReal]);
    library.addFunction(&_print_s, "print", [grString]);
    library.addFunction(&_print_ni, "print", [grPure(grIntArray)]);
    library.addFunction(&_print_nb, "print", [grBoolArray]);
    library.addFunction(&_print_nr, "print", [grRealArray]);
    library.addFunction(&_print_ns, "print", [grStringArray]);
    library.addFunction(&_print_enum, "print", [grPure(grAny("T"))], [],
        [grConstraint("Enum", grAny("T"))]);
    library.addFunction(&_print_chan, "print", [grPure(grAny("T"))], [],
        [grConstraint("Channel", grAny("T"))]);
    library.addFunction(&_print_func, "print", [grPure(grAny("T"))], [],
        [grConstraint("Callable", grAny("T"))]);
    library.addFunction(&_print_o, "print", [grPure(grAny("T"))], [],
        [grConstraint("Class", grAny("T"))]);
    library.addFunction(&_print_u, "print", [grPure(grAny("T"))], [],
        [grConstraint("Foreign", grAny("T"))]);
}

// print
private void _print_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _print_ix(GrCall call) {
    if(call.isNull(0))
        _stdOut("null");
    else
        _stdOut(to!string(call.getInt(0)));
}

private void _print_b(GrCall call) {
    _stdOut(call.getBool(0) ? "true" : "false");
}

private void _print_r(GrCall call) {
    _stdOut(to!string(call.getReal(0)));
}

private void _print_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _print_ni(GrCall call) {
    auto ary = call.getArray(0);
    string txt = "[";
    for (int i; i < ary.data.length; ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(ary.data[i].getInt());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nb(GrCall call) {
    auto ary = call.getArray(0);
    string txt = "[";
    for (int i; i < ary.data.length; ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= ary.data[i].getBool() ? "true" : "false";
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nr(GrCall call) {
    auto ary = call.getArray(0);
    string txt = "[";
    for (int i; i < ary.data.length; ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(ary.data[i].getReal());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_ns(GrCall call) {
    auto ary = call.getArray(0);
    string txt = "[";
    for (int i; i < ary.data.length; ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= ary.data[i].getString();
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_enum(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _print_chan(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getChannel(0);
    _stdOut(name ~ " {" ~ to!string(channel.capacity) ~ "}");
}

private void _print_func(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name ~ " {" ~ to!string(call.getInt(0)) ~ "}");
}

private void _print_o(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getObject(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}

private void _print_u(GrCall call) {
    const string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    if (call.getPtr(0)) {
        _stdOut(name);
    }
    else {
        _stdOut("null(" ~ name ~ ")");
    }
}
