/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package void grLoadStdLibSystem(GrLibrary library, GrLocale locale) {
    string swapSymbol, condSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        swapSymbol = "swap";
        condSymbol = "cond";
        break;
    case fr_FR:
        swapSymbol = "permute";
        condSymbol = "cond";
        break;
    }
    static foreach (t1; ["Int", "Real", "String", "Ptr"]) {
        static foreach (t2; ["Int", "Real", "String", "Ptr"]) {
            library.addPrimitive(&_swap_2_!(t1, t2), swapSymbol, [
                    grAny("1", (type, data) {
                        static if (t1 == "Ptr") {
                            return grIsKindOfObject(type.base);
                        }
                        else {
                            mixin("return grIsKindOf" ~ t1 ~ "(type.base);");
                        }
                    }), grAny("2", (type, data) {
                        static if (t2 == "Ptr") {
                            return grIsKindOfObject(type.base);
                        }
                        else {
                            mixin("return grIsKindOf" ~ t2 ~ "(type.base);");
                        }
                    })
                ], [grAny("2"), grAny("1")]);
        }
    }
    static foreach (t; ["Int", "Real", "String", "Ptr"]) {
        library.addPrimitive(&_cond_!t, condSymbol, [
                grBool, grAny("T", (type, data) {
                    static if (t == "Ptr") {
                        return grIsKindOfObject(type.base);
                    }
                    else {
                        mixin("return grIsKindOf" ~ t ~ "(type.base);");
                    }
                }), grAny("T")
            ], [grAny("T")]);
    }

    library.addPrimitive(&_typeOf, "typeOf", [grAny("T")], [grString]);
}

private void _swap_2_(string t1, string t2)(GrCall call) {
    mixin("auto v1 = call.get" ~ t1 ~ "(0);
    auto v2 = call.get"
            ~ t2 ~ "(1);
    call.set"
            ~ t2
            ~ "(v2);
    call.set"
            ~ t1 ~ "(v1);");
}

private void _cond_(string t)(GrCall call) {
    mixin("call.set" ~ t ~ "(call.getBool(0) ? call.get" ~ t ~ "(1) : call.get" ~ t ~ "(2));");
}

private void _typeOf(GrCall call) {
    call.setString(grGetPrettyType(grUnmangle(call.getInType(0))));
}
