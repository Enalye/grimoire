/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.vector;

import grimoire.compiler, grimoire.runtime;

package void grLoadStdLibVector(GrData data) {
    auto defVector = data.addClass("Vector", ["x", "y"], [grFloat, grFloat]);

	data.addPrimitive(&_makeVector, "Vector", [], [], [defVector]);
	data.addPrimitive(&_makeVector2f, "Vector", ["x", "y"], [grFloat, grFloat], [defVector]);

    static foreach(op; ["+", "-", "*", "/", "%"]) {
        data.addOperator(&_opBinaryVector!op, op, ["v1", "v2"], [defVector, defVector], defVector);
        data.addOperator(&_opBinaryScalarVector!op, op, ["v", "s"], [defVector, grFloat], defVector);
        data.addOperator(&_opBinaryScalarRightVector!op, op, ["s", "v"], [grFloat, defVector], defVector);
    }

    static foreach(op; ["==", "!=", ">=", "<=", ">", "<"]) {
        data.addOperator(&_opBinaryVector!op, op, ["v1", "v2"], [defVector, defVector], grBool);
    }
}

private void _makeVector(GrCall call) {
    auto self = call.createObject("Vector");
    self.setFloat("x", 0f);
    self.setFloat("y", 0f);
    call.setObject(self);
}

private void _makeVector2f(GrCall call) {
    auto self = call.createObject("Vector");
    self.setFloat("x", call.getFloat("x"));
    self.setFloat("y", call.getFloat("y"));
    call.setObject(self);
}

private void _opBinaryVector(string op)(GrCall call) {
    auto self = call.createObject("Vector");
    auto v1 = call.getObject("v1");
    auto v2 = call.getObject("v2");
    mixin("self.setFloat(\"x\", v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVector(string op)(GrCall call) {
    auto self = call.createObject("Vector");
    auto v = call.getObject("v");
    const auto s = call.getFloat("s");
    mixin("self.setFloat(\"x\", v.getFloat(\"x\")" ~ op ~ "s);");
    mixin("self.setFloat(\"y\", v.getFloat(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVector(string op)(GrCall call) {
    auto self = call.createObject("Vector");
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