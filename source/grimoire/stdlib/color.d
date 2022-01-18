/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.color;

import std.conv : to;
import std.algorithm.comparison : clamp;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

private {
    string _colorSymbol, _rSymbol, _gSymbol, _bSymbol;
}

package void grLoadStdLibColor(GrLibrary library, GrLocale locale) {
    string mixSymbol, lerpSymbol, unpackSymbol, printSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _colorSymbol = "Color";
        _rSymbol = "r";
        _gSymbol = "g";
        _bSymbol = "b";
        mixSymbol = "mix";
        lerpSymbol = "interpolate";
        unpackSymbol = "unpack";
        printSymbol = "print";
        break;
    case fr_FR:
        _colorSymbol = "Couleur";
        _rSymbol = "r";
        _gSymbol = "v";
        _bSymbol = "b";
        mixSymbol = "mélange";
        lerpSymbol = "interpole";
        unpackSymbol = "déballe";
        printSymbol = "affiche";
        break;
    }

    auto colorType = library.addClass(_colorSymbol, [
            _rSymbol, _gSymbol, _bSymbol
        ], [
            grReal, grReal, grReal
        ]);

    library.addPrimitive(&_makeColor, _colorSymbol, [], [colorType]);
    library.addPrimitive(&_makeColor3, _colorSymbol, [grReal, grReal, grReal], [
            colorType
        ]);

    library.addPrimitive(&_makeColor3i, _colorSymbol, [grInt, grInt, grInt], [
            colorType
        ]);

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryColor!op, op, [colorType, colorType], colorType);
        library.addOperator(&_opBinaryScalarColor!op, op, [colorType, grReal], colorType);
        library.addOperator(&_opBinaryScalarRightColor!op, op, [
                grReal, colorType
            ], colorType);
    }

    library.addPrimitive(&_mixColor, mixSymbol, [colorType, colorType], [
            colorType
        ]);
    library.addPrimitive(&_lerpColor, lerpSymbol, [
            colorType, colorType, grReal
        ], [
            colorType
        ]);

    library.addCast(&_castListToColor, grIntList, colorType);
    library.addCast(&_castColorToString, colorType, grString);

    library.addPrimitive(&_unpack, unpackSymbol, [colorType], [
            grReal, grReal, grReal
        ]);

    library.addPrimitive(&_print, printSymbol, [colorType]);
}

private void _makeColor(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal(_rSymbol, 0f);
    self.setReal(_gSymbol, 0f);
    self.setReal(_bSymbol, 0f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal(_rSymbol, call.getReal(0));
    self.setReal(_gSymbol, call.getReal(1));
    self.setReal(_bSymbol, call.getReal(2));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal(_rSymbol, clamp(call.getInt(0) / 255f, 0f, 1f));
    self.setReal(_gSymbol, clamp(call.getInt(1) / 255f, 0f, 1f));
    self.setReal(_bSymbol, clamp(call.getInt(2) / 255f, 0f, 1f));
    call.setObject(self);
}

private void _opBinaryColor(string op)(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    if (!c1 || !c2) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"r\", c1.getReal(\"r\")" ~ op ~ "c2.getReal(\"r\"));");
    mixin("self.setReal(\"g\", c1.getReal(\"g\")" ~ op ~ "c2.getReal(\"g\"));");
    mixin("self.setReal(\"b\", c1.getReal(\"b\")" ~ op ~ "c2.getReal(\"b\"));");
    call.setObject(self);
}

private void _opBinaryScalarColor(string op)(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c = call.getObject(0);
    const GrReal s = call.getReal(1);
    if (!c) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"r\", c.getReal(\"r\")" ~ op ~ "s);");
    mixin("self.setReal(\"g\", c.getReal(\"g\")" ~ op ~ "s);");
    mixin("self.setReal(\"b\", c.getReal(\"b\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightColor(string op)(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c = call.getObject(0);
    const GrReal s = call.getReal(1);
    if (!c) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setReal(\"r\", s" ~ op ~ "c.getReal(\"r\"));");
    mixin("self.setReal(\"g\", s" ~ op ~ "c.getReal(\"g\"));");
    mixin("self.setReal(\"b\", s" ~ op ~ "c.getReal(\"b\"));");
    call.setObject(self);
}

private void _mixColor(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    if (!c1 || !c2) {
        call.raise(_paramError);
        return;
    }
    self.setReal(_rSymbol, (c1.getReal(_rSymbol) + c2.getReal(_rSymbol)) / 2f);
    self.setReal(_gSymbol, (c1.getReal(_gSymbol) + c2.getReal(_gSymbol)) / 2f);
    self.setReal(_bSymbol, (c1.getReal(_bSymbol) + c2.getReal(_bSymbol)) / 2f);
    call.setObject(self);
}

private void _lerpColor(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    const GrReal t = call.getReal(2);
    if (!c1 || !c2) {
        call.raise(_paramError);
        return;
    }
    self.setReal(_rSymbol, (t * c2.getReal(_rSymbol)) + ((1f - t) * c1.getReal(_rSymbol)));
    self.setReal(_gSymbol, (t * c2.getReal(_gSymbol)) + ((1f - t) * c1.getReal(_gSymbol)));
    self.setReal(_bSymbol, (t * c2.getReal(_bSymbol)) + ((1f - t) * c1.getReal(_bSymbol)));
    call.setObject(self);
}

private void _castListToColor(GrCall call) {
    GrIntList list = call.getIntList(0);
    if (list.data.length == 3) {
        GrObject self = call.createObject(_colorSymbol);
        if (!self) {
            call.raise(_classError);
            return;
        }
        self.setReal(_rSymbol, list.data[0]);
        self.setReal(_gSymbol, list.data[1]);
        self.setReal(_bSymbol, list.data[2]);
        call.setObject(self);
        return;
    }
    call.raise("Cannot convert list to Color, invalid size");
}

private void _castColorToString(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setString("Color(" ~ to!GrString(
            self.getReal(_rSymbol)) ~ ", " ~ to!GrString(
            self.getReal(
            _gSymbol)) ~ ", " ~ to!GrString(self.getReal(_bSymbol)) ~ ")");
}

private void _unpack(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setReal(self.getReal(_rSymbol));
    call.setReal(self.getReal(_gSymbol));
    call.setReal(self.getReal(_bSymbol));
}

private void _print(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Color)");
        return;
    }
    _stdOut("Color(" ~ to!GrString(self.getReal(_rSymbol)) ~ ", " ~ to!GrString(
            self.getReal(_gSymbol)) ~ ", " ~ to!GrString(self.getReal(_bSymbol)) ~ ")");
}
