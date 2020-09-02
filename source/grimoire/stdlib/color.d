/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.color;

import std.algorithm.comparison: clamp;
import grimoire.compiler, grimoire.runtime;

package void grLoadStdLibColor(GrData data) {
    auto defColor = data.addClass("Color", ["r", "g", "b", "a"], [grFloat, grFloat, grFloat, grFloat]);

	data.addPrimitive(&_makeColor, "Color", [], [], [defColor]);
	data.addPrimitive(&_makeColor3, "Color", ["r", "g", "b"], [grFloat, grFloat, grFloat], [defColor]);
	data.addPrimitive(&_makeColor4, "Color", ["r", "g", "b", "a"], [grFloat, grFloat, grFloat, grFloat], [defColor]);

    data.addPrimitive(&_makeColor3i, "Color", ["r", "g", "b"], [grInt, grInt, grInt], [defColor]);
	data.addPrimitive(&_makeColor4i, "Color", ["r", "g", "b", "a"], [grInt, grInt, grInt, grInt], [defColor]);

    static foreach(op; ["+", "-", "*", "/", "%"]) {
        data.addOperator(&_opBinaryColor!op, op, ["c1", "c2"], [defColor, defColor], defColor);
        data.addOperator(&_opBinaryScalarColor!op, op, ["c", "s"], [defColor, grFloat], defColor);
        data.addOperator(&_opBinaryScalarRightColor!op, op, ["s", "c"], [grFloat, defColor], defColor);
    }

	data.addPrimitive(&_mixColor, "mix", ["c1", "c2"], [defColor, defColor], [defColor]);
	data.addPrimitive(&_lerpColor, "lerp", ["c1", "c2", "t"], [defColor, defColor, grFloat], [defColor]);

    data.addCast(&_castArrayToColor, "ary", grIntArray, defColor);
    data.addCast(&_castColorToString, "c", defColor, grString);
}

private void _makeColor(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", 0f);
    self.setFloat("g", 0f);
    self.setFloat("b", 0f);
    self.setFloat("a", 1f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", call.getFloat("r"));
    self.setFloat("g", call.getFloat("g"));
    self.setFloat("b", call.getFloat("b"));
    self.setFloat("a", 1f);
    call.setObject(self);
}

private void _makeColor4(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", call.getFloat("r"));
    self.setFloat("g", call.getFloat("g"));
    self.setFloat("b", call.getFloat("b"));
    self.setFloat("a", call.getFloat("a"));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", clamp(call.getInt("r") / 255f, 0f, 1f));
    self.setFloat("g", clamp(call.getInt("g") / 255f, 0f, 1f));
    self.setFloat("b", clamp(call.getInt("b") / 255f, 0f, 1f));
    self.setFloat("a", 1f);
    call.setObject(self);
}

private void _makeColor4i(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", clamp(call.getInt("r") / 255f, 0f, 1f));
    self.setFloat("g", clamp(call.getInt("g") / 255f, 0f, 1f));
    self.setFloat("b", clamp(call.getInt("b") / 255f, 0f, 1f));
    self.setFloat("a", clamp(call.getInt("a") / 255f, 0f, 1f));
    call.setObject(self);
}

private void _opBinaryColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c1 = call.getObject("c1");
    auto c2 = call.getObject("c2");
    mixin("self.setFloat(\"r\", c1.getFloat(\"r\")" ~ op ~ "c2.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", c1.getFloat(\"g\")" ~ op ~ "c2.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", c1.getFloat(\"b\")" ~ op ~ "c2.getFloat(\"b\"));");
    mixin("self.setFloat(\"a\", c1.getFloat(\"a\")" ~ op ~ "c2.getFloat(\"a\"));");
    call.setObject(self);
}

private void _opBinaryScalarColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c = call.getObject("c");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"r\", c.getFloat(\"r\")" ~ op ~ "s);");
    mixin("self.setFloat(\"g\", c.getFloat(\"g\")" ~ op ~ "s);");
    mixin("self.setFloat(\"b\", c.getFloat(\"b\")" ~ op ~ "s);");
    mixin("self.setFloat(\"a\", c.getFloat(\"a\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c = call.getObject("c");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"r\", s" ~ op ~ "c.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", s" ~ op ~ "c.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", s" ~ op ~ "c.getFloat(\"b\"));");
    mixin("self.setFloat(\"a\", s" ~ op ~ "c.getFloat(\"a\"));");
    call.setObject(self);
}

private void _mixColor(GrCall call) {
    auto self = call.createObject("Color");
    auto c1 = call.getObject("c1");
    auto c2 = call.getObject("c2");
    self.setFloat("r", (c1.getFloat("r") + c2.getFloat("r")) / 2f);
    self.setFloat("g", (c1.getFloat("g") + c2.getFloat("g")) / 2f);
    self.setFloat("b", (c1.getFloat("b") + c2.getFloat("b")) / 2f);
    self.setFloat("a", (c1.getFloat("a") + c2.getFloat("a")) / 2f);
    call.setObject(self);
}

private void _lerpColor(GrCall call) {
    auto self = call.createObject("Color");
    auto c1 = call.getObject("c1");
    auto c2 = call.getObject("c2");
    const float t = call.getFloat("t");

    self.setFloat("r", (t * c2.getFloat("r")) + ((1f - t) * c1.getFloat("r")));
    self.setFloat("g", (t * c2.getFloat("g")) + ((1f - t) * c1.getFloat("g")));
    self.setFloat("b", (t * c2.getFloat("b")) + ((1f - t) * c1.getFloat("b")));
    self.setFloat("a", (t * c2.getFloat("a")) + ((1f - t) * c1.getFloat("a")));
    call.setObject(self);
}

private void _castArrayToColor(GrCall call) {
    auto array = call.getIntArray("ary");
    if(array.data.length == 4) {
        auto self = call.createObject("Color");
        self.setFloat("r", array.data[0]);
        self.setFloat("g", array.data[1]);
        self.setFloat("b", array.data[2]);
        self.setFloat("a", array.data[3]);
        call.setObject(self);
        return;
    }
    else if(array.data.length == 3) {
        auto self = call.createObject("Color");
        self.setFloat("r", array.data[0]);
        self.setFloat("g", array.data[1]);
        self.setFloat("b", array.data[2]);
        call.setObject(self);
        return;
    }
    call.raise("Cannot convert array to Color, invalid size");
}

private void _castColorToString(GrCall call) {
    import std.conv: to;
    auto self = call.getObject("c");
    call.setString("Color(" ~ to!string(self.getFloat("r"))
        ~ ", " ~ to!string(self.getFloat("g"))
        ~ ", " ~ to!string(self.getFloat("b"))
        ~ ", " ~ to!string(self.getFloat("a")) ~ ")");
}