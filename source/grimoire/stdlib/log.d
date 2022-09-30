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
    library.addFunction(&_print_bx, "print", [grOptional(grBool)]);
    library.addFunction(&_print_r, "print", [grReal]);
    library.addFunction(&_print_rx, "print", [grOptional(grReal)]);
    library.addFunction(&_print_s, "print", [grString]);
    library.addFunction(&_print_sx, "print", [grOptional(grString)]);
    library.addFunction(&_print_ni, "print", [grPure(grArray(grInt))]);
    library.addFunction(&_print_nix, "print", [
            grPure(grOptional(grArray(grInt)))
        ]);
    library.addFunction(&_print_nb, "print", [grPure(grArray(grBool))]);
    library.addFunction(&_print_nbx, "print", [
            grPure(grOptional(grArray(grBool)))
        ]);
    library.addFunction(&_print_nr, "print", [grPure(grArray(grReal))]);
    library.addFunction(&_print_nrx, "print", [
            grPure(grOptional(grArray(grReal)))
        ]);
    library.addFunction(&_print_ns, "print", [grPure(grArray(grString))]);
    library.addFunction(&_print_nsx, "print", [
            grPure(grOptional(grArray(grString)))
        ]);
    library.addFunction(&_print_enum, "print", [grPure(grAny("T"))], [],
        [grConstraint("Enum", grAny("T"))]);
    library.addFunction(&_print_enumx, "print", [grOptional(grAny("T"))], [],
        [grConstraint("Enum", grAny("T"))]);
    library.addFunction(&_print_chan, "print", [grPure(grAny("T"))], [],
        [grConstraint("Channel", grAny("T"))]);
    library.addFunction(&_print_chanx, "print",
        [grPure(grOptional(grAny("T")))], [], [
            grConstraint("Channel", grAny("T"))
        ]);
    library.addFunction(&_print_func, "print", [grAny("T")], [],
        [grConstraint("Callable", grAny("T"))]);
    library.addFunction(&_print_funcx, "print", [grOptional(grAny("T"))], [],
        [grConstraint("Callable", grAny("T"))]);
    library.addFunction(&_print_o, "print", [grPure(grAny("T"))], [],
        [grConstraint("Class", grAny("T"))]);
    library.addFunction(&_print_ox, "print", [grPure(grOptional(grAny("T")))],
        [], [grConstraint("Class", grAny("T"))]);
    library.addFunction(&_print_u, "print", [grPure(grAny("T"))], [],
        [grConstraint("Foreign", grAny("T"))]);
    library.addFunction(&_print_ux, "print", [grPure(grOptional(grAny("T")))],
        [], [grConstraint("Foreign", grAny("T"))]);
}

// print
private void _print_i(GrCall call) {
    _stdOut(to!string(call.getInt(0)));
}

private void _print_ix(GrCall call) {
    if (call.isNull(0))
        _stdOut("null");
    else
        _stdOut(to!string(call.getInt(0)));
}

private void _print_b(GrCall call) {
    _stdOut(call.getBool(0) ? "true" : "false");
}

private void _print_bx(GrCall call) {
    if (call.isNull(0))
        _stdOut("null");
    else
        _stdOut(call.getBool(0) ? "true" : "false");
}

private void _print_r(GrCall call) {
    _stdOut(to!string(call.getReal(0)));
}

private void _print_rx(GrCall call) {
    if (call.isNull(0))
        _stdOut("null");
    else
        _stdOut(to!string(call.getReal(0)));
}

private void _print_s(GrCall call) {
    _stdOut(call.getString(0));
}

private void _print_sx(GrCall call) {
    if (call.isNull(0))
        _stdOut("null");
    else
        _stdOut(call.getString(0));
}

private void _print_ni(GrCall call) {
    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(array[i].getInt());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nix(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(array[i].getInt());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nb(GrCall call) {
    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= array[i].getBool() ? "true" : "false";
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nbx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= array[i].getBool() ? "true" : "false";
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nr(GrCall call) {
    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(array[i].getReal());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nrx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(array[i].getReal());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_ns(GrCall call) {
    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= array[i].getString();
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nsx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrArray array = call.getArray(0);
    string txt = "[";
    for (int i; i < array.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= array[i].getString();
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_enum(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _print_enumx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto enumValue = call.getInt(0);
    _stdOut(name ~ "." ~ to!string(enumValue));
}

private void _print_chan(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getChannel(0);
    _stdOut(name ~ " {" ~ to!string(channel.capacity) ~ "}");
}

private void _print_chanx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    auto channel = call.getChannel(0);
    _stdOut(name ~ " {" ~ to!string(channel.capacity) ~ "}");
}

private void _print_func(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name ~ " {" ~ to!string(call.getInt(0)) ~ "}");
}

private void _print_funcx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name ~ " {" ~ to!string(call.getInt(0)) ~ "}");
}

private void _print_o(GrCall call) {
    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name);
}

private void _print_ox(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name);
}

private void _print_u(GrCall call) {
    const string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name);
}

private void _print_ux(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    const string name = grGetPrettyType(grUnmangle(call.getInType(0)));
    _stdOut(name);
}
