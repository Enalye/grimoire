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
    library.addFunction(&_print_b, "print", [grBool]);
    library.addFunction(&_print_r, "print", [grReal]);
    library.addFunction(&_print_s, "print", [grString]);
    library.addFunction(&_print_ni, "print", [grIntArray]);
    library.addFunction(&_print_nb, "print", [grBoolArray]);
    library.addFunction(&_print_nr, "print", [grRealArray]);
    library.addFunction(&_print_ns, "print", [grStringArray]);
    library.addFunction(&_print_enum, "print", [grAny("T", true)], [], [
            grConstraint("Enum", grAny("T"))
        ]);
    library.addFunction(&_print_chan, "print", [grAny("T", true)], [], [
            grConstraint("Channel", grAny("T"))
        ]);
    library.addFunction(&_print_func, "print", [grAny("T", true)], [], [
            grConstraint("Callable", grAny("T"))
        ]);
    library.addFunction(&_print_o, "print", [grAny("T", true)], [], [
            grConstraint("Class", grAny("T"))
        ]);
    library.addFunction(&_print_u, "print", [grAny("T", true)], [], [
            grConstraint("Foreign", grAny("T"))
        ]);
}

// print
private void _print_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _print_b(GrCall call) {
    _stdOut(call.getBool(0) ? "true" : "false");
}

private void _print_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _print_r(GrCall call) {
    _stdOut(to!string(call.getReal(0)));
}

private void _print_ni(GrCall call) {
    auto ary = call.getIntArray(0);
    _stdOut(to!string(ary.data));
}

private void _print_nb(GrCall call) {
    auto ary = call.getIntArray(0);
    _stdOut(to!string(to!(GrBool[])(ary.data)));
}

private void _print_nr(GrCall call) {
    auto ary = call.getRealArray(0);
    _stdOut(to!string(ary.data));
}

private void _print_ns(GrCall call) {
    auto ary = call.getStringArray(0);
    _stdOut(to!string(ary.data));
}

private void _print_enum(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _print_chan(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getIntChannel(0);
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
