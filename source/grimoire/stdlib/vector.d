/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.vector;

import grimoire.compiler, grimoire.runtime;

package void grLoadStdLibVector(GrLibrary library) {
    auto defVec2 = library.addClass("Vec2", ["x", "y"], [grFloat, grFloat]);

    library.addPrimitive(&_makeVec2, "Vec2", [], [defVec2]);
    library.addPrimitive(&_makeVec2_2f, "Vec2", [grFloat, grFloat], [defVec2]);

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinaryVec2!op, op, [defVec2, defVec2], defVec2);
        library.addOperator(&_opBinaryScalarVec2!op, op, [defVec2, grFloat], defVec2);
        library.addOperator(&_opBinaryScalarRightVec2!op, op, [grFloat, defVec2], defVec2);
    }

    static foreach (op; ["==", "!=", ">=", "<=", ">", "<"]) {
        library.addOperator(&_opBinaryVec2!op, op, [defVec2, defVec2], grBool);
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
    self.setFloat("x", call.getFloat(0));
    self.setFloat("y", call.getFloat(1));
    call.setObject(self);
}

private void _opBinaryVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v1 = call.getObject(0);
    auto v2 = call.getObject(1);
    mixin("self.setFloat(\"x\", v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", v1.getFloat(\"y\")" ~ op ~ "v2.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryScalarVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v = call.getObject(0);
    const auto s = call.getFloat(1);
    mixin("self.setFloat(\"x\", v.getFloat(\"x\")" ~ op ~ "s);");
    mixin("self.setFloat(\"y\", v.getFloat(\"y\")" ~ op ~ "s);");
    call.setObject(self);
}

private void _opBinaryScalarRightVec2(string op)(GrCall call) {
    auto self = call.createObject("Vec2");
    auto v = call.getObject(0);
    const auto s = call.getFloat(1);
    mixin("self.setFloat(\"x\", s" ~ op ~ "v.getFloat(\"x\"));");
    mixin("self.setFloat(\"y\", s" ~ op ~ "v.getFloat(\"y\"));");
    call.setObject(self);
}

private void _opBinaryCompare(string op)(GrCall call) {
    auto v1 = call.getObject(0);
    auto v2 = call.getObject(1);
    mixin("call.setBool(
        v1.getFloat(\"x\")" ~ op ~ "v2.getFloat(\"x\") &&
        v1.getFloat(\"y\")" ~ op
            ~ "v2.getFloat(\"y\"));");
}
