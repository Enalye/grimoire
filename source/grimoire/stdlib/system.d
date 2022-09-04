/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime, grimoire.assembly;
import grimoire.stdlib.util;

package void grLoadStdLibSystem(GrLibrary library) {
    library.addFunction(&_swap_2, "swap", [grAny("T1"), grAny("T2")], [
            grAny("T2"), grAny("T1")
        ]);

    library.addFunction(&_cond, "unwrap_or", [grBool, grAny("T1"), grAny("T1")], [
            grAny("T1")
        ]);

    library.addFunction(&_typeOf, "typeof", [grAny("T")], [grString]);

    library.addFunction(&_test_call, "test_call", [
            grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt
        ], [
            grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt
        ]);

    library.addFunction(&_test_call2, "test_call_2", [], [
            grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt, grInt
        ]);
}

private void _swap_2(GrCall call) {
    call.setValue(call.getValue(1));
    call.setValue(call.getValue(0));
}

private void _cond(GrCall call) {
    call.setValue(call.getBool(0) ? call.getValue(1) : call.getValue(2));
}

private void _typeOf(GrCall call) {
    call.setString(grGetPrettyType(grUnmangle(call.getInType(0))));
}

private void _test_call(GrCall call) {
    GrInt v0 = call.getInt(0);
    GrInt v1 = call.getInt(1);
    GrInt v2 = call.getInt(2);
    GrInt v3 = call.getInt(3);
    GrInt v4 = call.getInt(4);
    GrInt v5 = call.getInt(5);
    GrInt v6 = call.getInt(6);
    GrInt v7 = call.getInt(7);
    GrInt v8 = call.getInt(8);
    GrInt v9 = call.getInt(9);

    call.setInt(v9);
    call.setInt(v8);
    call.setInt(v7);
    call.setInt(v6);
    call.setInt(v5);
    call.setInt(v4);
    call.setInt(v3);
    call.setInt(v2);
    call.setInt(v1);
    call.setInt(v0);
}

private void _test_call2(GrCall call) {
    call.setInt(9);
    call.setInt(8);
    call.setInt(7);
    call.setInt(6);
    call.setInt(5);
    call.setInt(4);
    call.setInt(3);
    call.setInt(2);
    call.setInt(1);
    call.setInt(0);
}