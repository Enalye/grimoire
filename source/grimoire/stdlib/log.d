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
    string printSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _trueText = "true";
        _falseText = "false";
        printSymbol = "print";
        break;
    case fr_FR:
        _trueText = "vrai";
        _falseText = "faux";
        printSymbol = "affiche";
        break;
    }

    //print
    library.addPrimitive(&_print_i, printSymbol, [grInt]);
    library.addPrimitive(&_print_b, printSymbol, [grBool]);
    library.addPrimitive(&_print_f, printSymbol, [grReal]);
    library.addPrimitive(&_print_s, printSymbol, [grString]);
    library.addPrimitive(&_print_ni, printSymbol, [grIntList]);
    library.addPrimitive(&_print_nb, printSymbol, [grBoolList]);
    library.addPrimitive(&_print_nf, printSymbol, [grRealList]);
    library.addPrimitive(&_print_ns, printSymbol, [grStringList]);
    library.addPrimitive(&_print_enum, printSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.enumeration; })
        ]
    );
    library.addPrimitive(&_print_chan, printSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.channel; })
        ]
    );
    library.addPrimitive(&_print_func, printSymbol, [
            grAny("T", (type, data) {
                return (type.base == GrType.Base.function_) || (type.base == GrType.Base.task);
            })
        ]
    );
    library.addPrimitive(&_print_o, printSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.class_; })
        ]
    );
    library.addPrimitive(&_print_u, printSymbol, [
            grAny("T", (type, data) { return type.base == GrType.Base.foreign; })
        ]
    );
}

// print
private void _print_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _print_b(GrCall call) {
    _stdOut(call.getBool(0) ? _trueText : _falseText);
}

private void _print_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _print_f(GrCall call) {
    _stdOut(to!string(call.getReal(0)));
}

private void _print_ni(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(ary.data));
}

private void _print_nb(GrCall call) {
    auto ary = call.getIntList(0);
    _stdOut(to!string(to!(GrBool[])(ary.data)));
}

private void _print_nf(GrCall call) {
    auto ary = call.getRealList(0);
    _stdOut(to!string(ary.data));
}

private void _print_ns(GrCall call) {
    auto ary = call.getStringList(0);
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
