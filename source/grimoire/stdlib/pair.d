/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library) {
    library.addClass("pair", ["key", "value"], [
            grAny("A"), grAny("B")
        ], [
            "A", "B"
        ]);

    static foreach (t1; ["Int", "Real", "String", "Object"]) {
        static foreach (t2; ["Int", "Real", "String", "Object"]) {
            mixin(
                "
            library.addOperator(&_makeKeyValuePair_!(\""
                    ~ t1 ~ "\", \"" ~ t2
                    ~ "\"), GrLibrary.Operator.arrow, [grAny(\"T1\"),
                    grAny(\"T2\", (t2, data) {
                        auto t1 = data.get(\"T1\");
                        data.set(\"P\", grGetClassType(\"pair\", [t1, t2]));
                        return grIsKindOf"
                    ~ t1 ~ "(t1.base) && grIsKindOf"
                    ~ t2 ~ "(t2.base);
                    })],
                    grAny(\"P\"));
            ");
        }
    }
}

private void _makeKeyValuePair_(string t1, string t2)(GrCall call) {
    GrObject obj = call.createObject(grUnmangle(call.getOutType(0)).mangledType);
    static if (t1 == "Int") {
        obj.setInt("key", call.getInt(0));
    }
    else static if (t1 == "Real") {
        obj.setReal("key", call.getReal(0));
    }
    else static if (t1 == "String") {
        obj.setString("key", call.getString(0));
    }
    else static if (t1 == "Object") {
        obj.setPtr("key", call.getPtr(0));
    }

    static if (t2 == "Int") {
        obj.setInt("value", call.getInt(1));
    }
    else static if (t2 == "Real") {
        obj.setReal("value", call.getReal(1));
    }
    else static if (t2 == "String") {
        obj.setString("value", call.getString(1));
    }
    else static if (t2 == "Object") {
        obj.setPtr("value", call.getPtr(1));
    }
    call.setObject(obj);
}
