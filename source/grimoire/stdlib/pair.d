/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.pair;

import grimoire.compiler, grimoire.runtime;

private {
    string pairSymbol, keySymbol, valueSymbol;
}

package(grimoire.stdlib) void grLoadStdLibPair(GrLibrary library, GrLocale locale) {
    final switch (locale) with (GrLocale) {
    case en_US:
        pairSymbol = "Pair";
        keySymbol = "key";
        valueSymbol = "value";
        break;
    case fr_FR:
        pairSymbol = "Paire";
        keySymbol = "clé";
        valueSymbol = "valeur";
        break;
    }

    library.addClass(pairSymbol, [keySymbol, valueSymbol], [
            grAny("A"), grAny("B")
        ], [
            "A", "B"
        ]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin(
            "
        library.addOperator(&_makeKeyValuePair_!\""
                ~ t
                ~ "\", GrLibrary.Operator.arrow, [grString, grAny(\"T\", (type, data) {
            data.set(\"P\", grGetClassType(pairSymbol, [grString, type]));
            return grIsKindOf"
                ~ t ~ "(type.base);
        })], grAny(\"P\"));
        ");
    }
}

private void _makeKeyValuePair_(string t)(GrCall call) {
    GrObject obj = call.createObject(grUnmangle(call.getOutType(0)).mangledType);
    obj.setString(keySymbol, call.getString(0));
    static if (t == "Int") {
        obj.setInt(valueSymbol, call.getInt(1));
    }
    else static if (t == "Float") {
        obj.setFloat(valueSymbol, call.getFloat(1));
    }
    else static if (t == "String") {
        obj.setString(valueSymbol, call.getString(1));
    }
    else static if (t == "Object") {
        obj.setPtr(valueSymbol, call.getPtr(1));
    }
    call.setObject(obj);
}
