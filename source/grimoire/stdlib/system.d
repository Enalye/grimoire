/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime, grimoire.assembly;
import grimoire.stdlib.util;

void grLoadStdLibSystem(GrLibDefinition library) {
    library.setModule(["std", "system"]);

    library.addFunction(&_swap_2, "swap", [grAny("T1"), grAny("T2")], [
            grAny("T2"), grAny("T1")
        ]);

    library.addFunction(&_cond, "cond", [grBool, grAny("T"), grAny("T")], [
            grAny("T")
        ]);

    library.addFunction(&_typeOf, "typeOf", [grAny("T")], [grString]);
}

private void _swap_2(GrCall call) {
    call.setValue(call.getValue(1));
    call.setValue(call.getValue(0));
}

private void _cond(GrCall call) {
    if (call.getBool(0))
        call.setValue(call.getValue(1));
    else
        call.setValue(call.getValue(2));
}

private void _typeOf(GrCall call) {
    call.setString(grGetPrettyType(grUnmangle(call.getInType(0))));
}