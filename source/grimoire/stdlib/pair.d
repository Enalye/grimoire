/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library) {
    library.addClass("Pair", ["first", "second"], [grAny("A"), grAny("B")], [
            "A", "B"
            ]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin(
                "
        library.addOperator(&_makeKeyValuePair_!\"" ~ t
                ~ "\", GrLibrary.Operator.arrow, [grString, grAny(\"T\", (type, data) {
            data.set(\"P\", grGetClassType(\"Pair\", [grString, type]));
            return grIsKindOf" ~ t ~ "(type.baseType);
        })], grAny(\"P\"));
        ");
    }
}

private void _makeKeyValuePair_(string t)(GrCall call) {
    GrObject obj = call.createObject(grUnmangle(call.getOutType(0)).mangledType);
    obj.setString("first", call.getString(0));
    static if(t == "Int") {
        obj.setInt("second", call.getInt(1));
    }
    else static if(t == "Float") {
        obj.setFloat("second", call.getFloat(1));
    }
    else static if(t == "String") {
        obj.setString("second", call.getString(1));
    }
    else static if(t == "Object") {
        obj.setPtr("second", call.getPtr(1));
    }
    call.setObject(obj);
}