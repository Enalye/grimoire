/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.vector;

import grimoire.compiler, grimoire.runtime;

package void grLoadStdLibVector(GrData data) {
    auto defVec2 = data.addClass("Vec2", ["x", "y"], [grFloat, grFloat]);

	data.addPrimitive(&_makeVec2, "Vec2", [], [], [defVec2]);
	data.addPrimitive(&_makeVec2_2f, "Vec2", ["x", "y"], [grFloat, grFloat], [defVec2]);

    static foreach(op; ["+", "-", "*", "/", "%"]) {
        data.addOperator(&_opBinaryVec2!op, op, ["v1", "v2"], [defVec2, defVec2], defVec2);
        data.addOperator(&_opBinaryScalarVec2!op, op, ["v", "s"], [defVec2, grFloat], defVec2);
        data.addOperator(&_opBinaryScalarRightVec2!op, op, ["s", "v"], [grFloat, defVec2], defVec2);
    }

    static foreach(op; ["==", "!=", ">=", "<=", ">", "<"]) {
        data.addOperator(&_opBinaryVec2!op, op, ["v1", "v2"], [defVec2, defVec2], grBool);
    }
}

private void _makeVec2(GrCall call) {
    auto self = call.createObject("Vec2");
    self.setFloat("x", 0f);
    self.setFloat("y", 0f);
    call.setObject(self);
}

private void _makeVec2_2f(GrCall call) {
    auto self = call.createObject("Vec2");
    self.setFloat("x", call.getFloat("x"));
    self.setFloat("y", call.getFloat("y"));
    call.setObject(self);
}

private void _opBinaryVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v1 = call.getObject("v1");
    auto v2 = call.getObject("v2");
    mixin("self.setFloat(\"x\", v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v = call.getObject("v");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"x\", v.getFloat(\"x\")" ~ op ~ "s);");
    mixin("self.setFloat(\"y\", v.getFloat(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v = call.getObject("v");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"x\", s" ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", s" ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryCompare(string op)(GrCall call) {
    auto v1 = call.getObject("v1");
    auto v2 = call.getObject("v2");
    mixin("call.setBool(
        v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\") &&
        v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
}