/**
    Vec2 functions.

    Copyright: (c) Enalye 2019
    License: Zlib
    Authors: Enalye
*/

module grimoire.lib.math.vec2;

import grimoire.lib.api;

static this() {
    auto defVec2f = grAddStructure("vec2f", ["x", "y"], [grFloat, grFloat]);
    
	grAddPrimitive(&vec2f_make, "vec2f", ["x", "y"], [grFloat, grFloat], [defVec2f]);
	
}

private void vec2f_make(GrCall call) {
    call.setFloat(call.getFloat("x"));
    call.setFloat(call.getFloat("y"));
}