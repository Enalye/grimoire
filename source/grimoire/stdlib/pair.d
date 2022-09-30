/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library) {
    library.addClass("pair", ["key", "value"], [grAny("K"), grAny("V")], [
            "K", "V"
        ]);

    library.addOperator(&_newKeyValuePair, GrLibrary.Operator.arrow,
        [grAny("T1"), grAny("T2")], grGetClassType("pair", [
                grAny("T1"), grAny("T2")
            ]));
}

private void _newKeyValuePair(GrCall call) {
    GrObject obj = call.createObject(grUnmangle(call.getOutType(0)).mangledType);
    obj.setValue("key", call.getValue(0));
    obj.setValue("value", call.getValue(1));
    call.setObject(obj);
}
