/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.color;

import std.algorithm.comparison: clamp;
import grimoire.compiler, grimoire.runtime;

package void grLoadStdLibColor(GrLibrary library) {
    auto defColor = library.addClass("Color", ["r", "g", "b"], [grFloat, grFloat, grFloat]);

	library.addPrimitive(&_makeColor, "Color", [], [], [defColor]);
	library.addPrimitive(&_makeColor3, "Color", ["r", "g", "b"], [grFloat, grFloat, grFloat], [defColor]);

    library.addPrimitive(&_makeColor3i, "Color", ["r", "g", "b"], [grInt, grInt, grInt], [defColor]);

    static foreach(op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryColor!op, op, ["c1", "c2"], [defColor, defColor], defColor);
        library.addOperator(&_opBinaryScalarColor!op, op, ["c", "s"], [defColor, grFloat], defColor);
        library.addOperator(&_opBinaryScalarRightColor!op, op, ["s", "c"], [grFloat, defColor], defColor);
    }

	library.addPrimitive(&_mixColor, "mix", ["c1", "c2"], [defColor, defColor], [defColor]);
	library.addPrimitive(&_lerpColor, "lerp", ["c1", "c2", "t"], [defColor, defColor, grFloat], [defColor]);

    library.addCast(&_castArrayToColor, "ary", grIntArray, defColor);
    library.addCast(&_castColorToString, "c", defColor, grString);
}

private void _makeColor(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", 0f);
    self.setFloat("g", 0f);
    self.setFloat("b", 0f);
    call.setObject(self);
}

private void _makeColor3(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", call.getFloat("r"));
    self.setFloat("g", call.getFloat("g"));
    self.setFloat("b", call.getFloat("b"));
    call.setObject(self);
}

private void _makeColor3i(GrCall call) {
    auto self = call.createObject("Color");
    self.setFloat("r", clamp(call.getInt("r") / 255f, 0f, 1f));
    self.setFloat("g", clamp(call.getInt("g") / 255f, 0f, 1f));
    self.setFloat("b", clamp(call.getInt("b") / 255f, 0f, 1f));
    call.setObject(self);
}

private void _opBinaryColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c1 = call.getObject("c1");
    auto c2 = call.getObject("c2");
    mixin("self.setFloat(\"r\", c1.getFloat(\"r\")" ~ op ~ "c2.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", c1.getFloat(\"g\")" ~ op ~ "c2.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", c1.getFloat(\"b\")" ~ op ~ "c2.getFloat(\"b\"));");
    call.setObject(self);
}

private void _opBinaryScalarColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c = call.getObject("c");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"r\", c.getFloat(\"r\")" ~ op ~ "s);");
    mixin("self.setFloat(\"g\", c.getFloat(\"g\")" ~ op ~ "s);");
    mixin("self.setFloat(\"b\", c.getFloat(\"b\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightColor(string op)(GrCall call) {
    auto self = call.createObject("Color");
    auto c = call.getObject("c");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"r\", s" ~ op ~ "c.getFloat(\"r\"));");
    mixin("self.setFloat(\"g\", s" ~ op ~ "c.getFloat(\"g\"));");
    mixin("self.setFloat(\"b\", s" ~ op ~ "c.getFloat(\"b\"));");
    call.setObject(self);
}

private void _mixColor(GrCall call) {
    auto self = call.createObject("Color");
    auto c1 = call.getObject("c1");
    auto c2 = call.getObject("c2");
    self.setFloat("r", (c1.getFloat("r") + c2.getFloat("r")) / 2f);
    self.setFloat("g", (c1.getFloat("g") + c2.getFloat("g")) / 2f);
    self.setFloat("b", (c1.getFloat("b") + c2.getFloat("b")) / 2f);
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
    call.setObject(self);
}

private void _castArrayToColor(GrCall call) {
    auto array = call.getIntArray("ary");
    if(array.data.length == 3) {
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
        ~ ")");
}