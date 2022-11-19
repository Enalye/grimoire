/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.log;

import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibLog(GrLibDefinition library) {
    library.setModule(["std", "io"]);

    library.setDescription(GrLocale.fr_FR, "Affiche le contenu de `valeur`.");
    library.setDescription(GrLocale.en_US, "Display `value`'s content.");

    library.setParameters(GrLocale.fr_FR, ["valeur"]);
    library.setParameters(GrLocale.en_US, ["value"]);

    //print
    library.addFunction(&_print_i, "print", [grInt]);
    library.addFunction(&_print_ix, "print", [grOptional(grInt)]);
    library.addFunction(&_print_b, "print", [grBool]);
    library.addFunction(&_print_bx, "print", [grOptional(grBool)]);
    library.addFunction(&_print_r, "print", [grFloat]);
    library.addFunction(&_print_rx, "print", [grOptional(grFloat)]);
    library.addFunction(&_print_s, "print", [grString]);
    library.addFunction(&_print_sx, "print", [grOptional(grString)]);
    library.addFunction(&_print_ni, "print", [grPure(grList(grInt))]);
    library.addFunction(&_print_nix, "print", [
            grPure(grOptional(grList(grInt)))
        ]);
    library.addFunction(&_print_nb, "print", [grPure(grList(grBool))]);
    library.addFunction(&_print_nbx, "print", [
            grPure(grOptional(grList(grBool)))
        ]);
    library.addFunction(&_print_nr, "print", [grPure(grList(grFloat))]);
    library.addFunction(&_print_nrx, "print", [
            grPure(grOptional(grList(grFloat)))
        ]);
    library.addFunction(&_print_ns, "print", [grPure(grList(grString))]);
    library.addFunction(&_print_nsx, "print", [
            grPure(grOptional(grList(grString)))
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
        [grConstraint("Native", grAny("T"))]);
    library.addFunction(&_print_ux, "print", [grPure(grOptional(grAny("T")))],
        [], [grConstraint("Native", grAny("T"))]);
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
    _stdOut(to!string(call.getFloat(0)));
}

private void _print_rx(GrCall call) {
    if (call.isNull(0))
        _stdOut("null");
    else
        _stdOut(to!string(call.getFloat(0)));
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
    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(list[i].getInt());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nix(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(list[i].getInt());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nb(GrCall call) {
    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= list[i].getBool() ? "true" : "false";
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nbx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= list[i].getBool() ? "true" : "false";
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nr(GrCall call) {
    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(list[i].getFloat());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nrx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= to!string(list[i].getFloat());
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_ns(GrCall call) {
    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= list[i].getString();
    }
    txt ~= "]";
    _stdOut(txt);
}

private void _print_nsx(GrCall call) {
    if (call.isNull(0)) {
        _stdOut("null");
        return;
    }

    GrList list = call.getList(0);
    string txt = "[";
    for (int i; i < list.size(); ++i) {
        if (i != 0) {
            txt ~= ", ";
        }
        txt ~= list[i].getString();
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
