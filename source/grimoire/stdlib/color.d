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
            grFloat, grFloat, grFloat
        ]);

    library.addPrimitive(&_makeColor, _colorSymbol, [], [colorType]);
    library.addPrimitive(&_makeColor3, _colorSymbol, [grFloat, grFloat, grFloat], [
            colorType
        ]);

    library.addPrimitive(&_makeColor3i, _colorSymbol, [grInt, grInt, grInt], [
            colorType
        ]);

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryColor!op, op, [colorType, colorType], colorType);
        library.addOperator(&_opBinaryScalarColor!op, op, [colorType, grFloat], colorType);
        library.addOperator(&_opBinaryScalarRightColor!op, op, [
                grFloat, colorType
            ], colorType);
    }

    library.addPrimitive(&_mixColor, mixSymbol, [colorType, colorType], [
            colorType
        ]);
    library.addPrimitive(&_lerpColor, lerpSymbol, [
            colorType, colorType, grFloat
        ], [
            colorType
        ]);

    library.addCast(&_castListToColor, grIntList, colorType);
    library.addCast(&_castColorToString, colorType, grString);

    library.addPrimitive(&_unpack, unpackSymbol, [colorType], [
            grFloat, grFloat, grFloat
        ]);

    library.addPrimitive(&_print, printSymbol, [colorType]);
}

private void _makeColor(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat(_rSymbol, 0f);
    self.setFloat(_gSymbol, 0f);
    self.setFloat(_bSymbol, 0f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat(_rSymbol, call.getFloat(0));
    self.setFloat(_gSymbol, call.getFloat(1));
    self.setFloat(_bSymbol, call.getFloat(2));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setFloat(_rSymbol, clamp(call.getInt(0) / 255f, 0f, 1f));
    self.setFloat(_gSymbol, clamp(call.getInt(1) / 255f, 0f, 1f));
    self.setFloat(_bSymbol, clamp(call.getInt(2) / 255f, 0f, 1f));
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
    mixin("self.setFloat(\"r\", c1.getFloat(\"r\")" ~ op ~ "c2.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", c1.getFloat(\"g\")" ~ op ~ "c2.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", c1.getFloat(\"b\")" ~ op ~ "c2.getFloat(\"b\"));");
    call.setObject(self);
}

private void _opBinaryScalarColor(string op)(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!c) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"r\", c.getFloat(\"r\")" ~ op ~ "s);");
    mixin("self.setFloat(\"g\", c.getFloat(\"g\")" ~ op ~ "s);");
    mixin("self.setFloat(\"b\", c.getFloat(\"b\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightColor(string op)(GrCall call) {
    GrObject self = call.createObject(_colorSymbol);
    if (!self) {
        call.raise(_classError);
        return;
    }
    GrObject c = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!c) {
        call.raise(_paramError);
        return;
    }
    mixin("self.setFloat(\"r\", s" ~ op ~ "c.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", s" ~ op ~ "c.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", s" ~ op ~ "c.getFloat(\"b\"));");
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
    self.setFloat(_rSymbol, (c1.getFloat(_rSymbol) + c2.getFloat(_rSymbol)) / 2f);
    self.setFloat(_gSymbol, (c1.getFloat(_gSymbol) + c2.getFloat(_gSymbol)) / 2f);
    self.setFloat(_bSymbol, (c1.getFloat(_bSymbol) + c2.getFloat(_bSymbol)) / 2f);
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
    const GrFloat t = call.getFloat(2);
    if (!c1 || !c2) {
        call.raise(_paramError);
        return;
    }
    self.setFloat(_rSymbol, (t * c2.getFloat(_rSymbol)) + ((1f - t) * c1.getFloat(_rSymbol)));
    self.setFloat(_gSymbol, (t * c2.getFloat(_gSymbol)) + ((1f - t) * c1.getFloat(_gSymbol)));
    self.setFloat(_bSymbol, (t * c2.getFloat(_bSymbol)) + ((1f - t) * c1.getFloat(_bSymbol)));
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
        self.setFloat(_rSymbol, list.data[0]);
        self.setFloat(_gSymbol, list.data[1]);
        self.setFloat(_bSymbol, list.data[2]);
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
            self.getFloat(_rSymbol)) ~ ", " ~ to!GrString(
            self.getFloat(
            _gSymbol)) ~ ", " ~ to!GrString(self.getFloat(_bSymbol)) ~ ")");
}

private void _unpack(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setFloat(self.getFloat(_rSymbol));
    call.setFloat(self.getFloat(_gSymbol));
    call.setFloat(self.getFloat(_bSymbol));
}

private void _print(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Color)");
        return;
    }
    _stdOut("Color(" ~ to!GrString(self.getFloat(_rSymbol)) ~ ", " ~ to!GrString(
            self.getFloat(_gSymbol)) ~ ", " ~ to!GrString(self.getFloat(_bSymbol)) ~ ")");
}
