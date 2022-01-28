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

package void grLoadStdLibColor(GrLibrary library) {
    auto colorType = library.addClass("Color", [
            "r", "g", "b"
        ], [
            grReal, grReal, grReal
        ]);

    library.addFunction(&_makeColor, "Color", [], [colorType]);
    library.addFunction(&_makeColor3, "Color", [grReal, grReal, grReal], [
            colorType
        ]);

    library.addFunction(&_makeColor3i, "Color", [grInt, grInt, grInt], [
            colorType
        ]);

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryColor!op, op, [colorType, colorType], colorType);
        library.addOperator(&_opBinaryScalarColor!op, op, [colorType, grReal], colorType);
        library.addOperator(&_opBinaryScalarRightColor!op, op, [
                grReal, colorType
            ], colorType);
    }

    library.addFunction(&_mixColor, "mix", [colorType, colorType], [
            colorType
        ]);
    library.addFunction(&_lerpColor, "lerp", [
            colorType, colorType, grReal
        ], [
            colorType
        ]);

    library.addCast(&_castArrayToColor, grIntArray, colorType);
    library.addCast(&_castColorToString, colorType, grString);

    library.addFunction(&_unpack, "unpack", [colorType], [
            grReal, grReal, grReal
        ]);

    library.addFunction(&_print, "print", [colorType]);
}

private void _makeColor(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("r", 0f);
    self.setReal("g", 0f);
    self.setReal("b", 0f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("r", call.getReal(0));
    self.setReal("g", call.getReal(1));
    self.setReal("b", call.getReal(2));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise(_classError);
        return;
    }
    self.setReal("r", clamp(call.getInt(0) / 255f, 0f, 1f));
    self.setReal("g", clamp(call.getInt(1) / 255f, 0f, 1f));
    self.setReal("b", clamp(call.getInt(2) / 255f, 0f, 1f));
    call.setObject(self);
}

private void _opBinaryColor(string op)(GrCall call) {
    GrObject self = call.createObject("Color");
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
    GrObject self = call.createObject("Color");
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
    GrObject self = call.createObject("Color");
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
    GrObject self = call.createObject("Color");
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
    self.setReal("r", (c1.getReal("r") + c2.getReal("r")) / 2f);
    self.setReal("g", (c1.getReal("g") + c2.getReal("g")) / 2f);
    self.setReal("b", (c1.getReal("b") + c2.getReal("b")) / 2f);
    call.setObject(self);
}

private void _lerpColor(GrCall call) {
    GrObject self = call.createObject("Color");
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
    self.setReal("r", (t * c2.getReal("r")) + ((1f - t) * c1.getReal("r")));
    self.setReal("g", (t * c2.getReal("g")) + ((1f - t) * c1.getReal("g")));
    self.setReal("b", (t * c2.getReal("b")) + ((1f - t) * c1.getReal("b")));
    call.setObject(self);
}

private void _castArrayToColor(GrCall call) {
    GrIntArray array = call.getIntArray(0);
    if (array.data.length == 3) {
        GrObject self = call.createObject("Color");
        if (!self) {
            call.raise(_classError);
            return;
        }
        self.setReal("r", array.data[0]);
        self.setReal("g", array.data[1]);
        self.setReal("b", array.data[2]);
        call.setObject(self);
        return;
    }
    call.raise("Cannot convert array to Color, invalid size");
}

private void _castColorToString(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setString("Color(" ~ to!GrString(
            self.getReal("r")) ~ ", " ~ to!GrString(
            self.getReal(
            "g")) ~ ", " ~ to!GrString(self.getReal("b")) ~ ")");
}

private void _unpack(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise(_paramError);
        return;
    }
    call.setReal(self.getReal("r"));
    call.setReal(self.getReal("g"));
    call.setReal(self.getReal("b"));
}

private void _print(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        _stdOut("null(Color)");
        return;
    }
    _stdOut("Color(" ~ to!GrString(self.getReal("r")) ~ ", " ~ to!GrString(
            self.getReal("g")) ~ ", " ~ to!GrString(self.getReal("b")) ~ ")");
}
