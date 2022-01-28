/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library) {
    library.addClass("Pair", ["key", "value"], [
            grAny("A"), grAny("B")
        ], [
            "A", "B"
        ]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin(
            "
        library.addOperator(&_makeKeyValuePair_!\""
                ~ t
                ~ "\", GrLibrary.Operator.arrow, [grString, grAny(\"T\", (type, data) {
            data.set(\"P\", grGetClassType(\"Pair\", [grString, type]));
            return grIsKindOf"
                ~ t ~ "(type.base);
        })], grAny(\"P\"));
        ");
    }
}

private void _makeKeyValuePair_(string t)(GrCall call) {
    GrObject obj = call.createObject(grUnmangle(call.getOutType(0)).mangledType);
    obj.setString("key", call.getString(0));
    static if (t == "Int") {
        obj.setInt("value", call.getInt(1));
    }
    else static if (t == "Real") {
        obj.setReal("value", call.getReal(1));
    }
    else static if (t == "String") {
        obj.setString("value", call.getString(1));
    }
    else static if (t == "Object") {
        obj.setPtr("value", call.getPtr(1));
    }
    call.setObject(obj);
}
