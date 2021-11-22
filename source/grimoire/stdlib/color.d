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
    auto colorType = library.addClass("Color", ["r", "g", "b"], [
            grFloat, grFloat, grFloat
            ]);

    library.addPrimitive(&_makeColor, "Color", [], [colorType]);
    library.addPrimitive(&_makeColor3, "Color", [grFloat, grFloat, grFloat], [
            colorType
            ]);

    library.addPrimitive(&_makeColor3i, "Color", [grInt, grInt, grInt], [
            colorType
            ]);

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryColor!op, op, [colorType, colorType], colorType);
        library.addOperator(&_opBinaryScalarColor!op, op, [colorType, grFloat], colorType);
        library.addOperator(&_opBinaryScalarRightColor!op, op, [
                grFloat, colorType
                ], colorType);
    }

    library.addPrimitive(&_mixColor, "mix", [colorType, colorType], [colorType]);
    library.addPrimitive(&_lerpColor, "lerp", [colorType, colorType, grFloat], [
            colorType
            ]);

    library.addCast(&_castListToColor, grIntList, colorType);
    library.addCast(&_castColorToString, colorType, grString);

    library.addPrimitive(&_unpack, "unpack", [colorType], [
            grFloat, grFloat, grFloat
            ]);

    library.addPrimitive(&_print, "print", [colorType]);
    library.addPrimitive(&_printl, "printl", [colorType]);
}

private void _makeColor(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("r", 0f);
    self.setFloat("g", 0f);
    self.setFloat("b", 0f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("r", call.getFloat(0));
    self.setFloat("g", call.getFloat(1));
    self.setFloat("b", call.getFloat(2));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    self.setFloat("r", clamp(call.getInt(0) / 255f, 0f, 1f));
    self.setFloat("g", clamp(call.getInt(1) / 255f, 0f, 1f));
    self.setFloat("b", clamp(call.getInt(2) / 255f, 0f, 1f));
    call.setObject(self);
}

private void _opBinaryColor(string op)(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    if (!c1 || !c2) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"r\", c1.getFloat(\"r\")" ~ op ~ "c2.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", c1.getFloat(\"g\")" ~ op ~ "c2.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", c1.getFloat(\"b\")" ~ op ~ "c2.getFloat(\"b\"));");
    call.setObject(self);
}

private void _opBinaryScalarColor(string op)(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject c = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!c) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"r\", c.getFloat(\"r\")" ~ op ~ "s);");
    mixin("self.setFloat(\"g\", c.getFloat(\"g\")" ~ op ~ "s);");
    mixin("self.setFloat(\"b\", c.getFloat(\"b\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightColor(string op)(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject c = call.getObject(0);
    const GrFloat s = call.getFloat(1);
    if (!c) {
        call.raise("NullError");
        return;
    }
    mixin("self.setFloat(\"r\", s" ~ op ~ "c.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", s" ~ op ~ "c.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", s" ~ op ~ "c.getFloat(\"b\"));");
    call.setObject(self);
}

private void _mixColor(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    if (!c1 || !c2) {
        call.raise("NullError");
        return;
    }
    self.setFloat("r", (c1.getFloat("r") + c2.getFloat("r")) / 2f);
    self.setFloat("g", (c1.getFloat("g") + c2.getFloat("g")) / 2f);
    self.setFloat("b", (c1.getFloat("b") + c2.getFloat("b")) / 2f);
    call.setObject(self);
}

private void _lerpColor(GrCall call) {
    GrObject self = call.createObject("Color");
    if (!self) {
        call.raise("UnknownClassError");
        return;
    }
    GrObject c1 = call.getObject(0);
    GrObject c2 = call.getObject(1);
    const GrFloat t = call.getFloat(2);
    if (!c1 || !c2) {
        call.raise("NullError");
        return;
    }
    self.setFloat("r", (t * c2.getFloat("r")) + ((1f - t) * c1.getFloat("r")));
    self.setFloat("g", (t * c2.getFloat("g")) + ((1f - t) * c1.getFloat("g")));
    self.setFloat("b", (t * c2.getFloat("b")) + ((1f - t) * c1.getFloat("b")));
    call.setObject(self);
}

private void _castListToColor(GrCall call) {
    GrIntList list = call.getIntList(0);
    if (list.data.length == 3) {
        GrObject self = call.createObject("Color");
        if (!self) {
            call.raise("UnknownClassError");
            return;
        }
        self.setFloat("r", list.data[0]);
        self.setFloat("g", list.data[1]);
        self.setFloat("b", list.data[2]);
        call.setObject(self);
        return;
    }
    call.raise("Cannot convert list to Color, invalid size");
}

private void _castColorToString(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setString("Color(" ~ to!GrString(self.getFloat("r")) ~ ", " ~ to!GrString(
            self.getFloat("g")) ~ ", " ~ to!GrString(self.getFloat("b")) ~ ")");
}

private void _unpack(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    call.setFloat(self.getFloat("r"));
    call.setFloat(self.getFloat("g"));
    call.setFloat(self.getFloat("b"));
}

private void _print(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    _stdOut("Color(" ~ to!GrString(self.getFloat("r")) ~ ", " ~ to!GrString(
            self.getFloat("g")) ~ ", " ~ to!GrString(self.getFloat("b")) ~ ")");
}

private void _printl(GrCall call) {
    GrObject self = call.getObject(0);
    if (!self) {
        call.raise("NullError");
        return;
    }
    _stdOut("Color(" ~ to!GrString(self.getFloat("r")) ~ ", " ~ to!GrString(
            self.getFloat("g")) ~ ", " ~ to!GrString(self.getFloat("b")) ~ ")\n");
}
