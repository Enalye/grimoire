/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package void grLoadStdLibSystem(GrLibrary library) {
    static foreach (t1; ["Int", "Float", "String", "Ptr"]) {
        static foreach (t2; ["Int", "Float", "String", "Ptr"]) {
            library.addPrimitive(&_swap_2_!(t1, t2), "swap", [
                    grAny("1"), grAny("2")
                    ], [grAny("2"), grAny("1")]);
        }
    }
    static foreach (t; ["Int", "Float", "String", "Ptr"]) {
        library.addPrimitive(&_cond_!t, "cond", [
                grBool, grAny("T", (type, data) {
                    static if (t == "Ptr") {
                        return grIsKindOfObject(type.baseType);
                    }
                    else {
                        mixin("return grIsKindOf" ~ t ~ "(type.baseType);");
                    }
                }), grAny("T")
                ], [grAny("T")]);
    }
}

private void _swap_2_(string t1, string t2)(GrCall call) {
    mixin("auto v1 = call.get" ~ t1 ~ "(0);
    auto v2 = call.get" ~ t2 ~ "(1);
    call.set" ~ t2
            ~ "(v2);
    call.set" ~ t1 ~ "(v1);");
}

private void _cond_(string t)(GrCall call) {
    mixin("call.set" ~ t ~ "(call.getBool(0) ? call.get" ~ t ~ "(1) : call.get" ~ t ~ "(2));");
}
