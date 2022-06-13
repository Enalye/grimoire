/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package void grLoadStdLibSystem(GrLibrary library) {
    GrConstraint constraint1, constraint2;
    static foreach (t1; ["Int", "Real", "String", "Ptr"]) {
        static foreach (t2; ["Int", "Real", "String", "Ptr"]) {
            static if (t1 == "Ptr") {
                constraint1 = grConstraint("Register", grAny("T1"), [
                        GrType(GrType.Base.null_)
                    ]);
            }
            else {
                mixin("constraint1 = grConstraint(\"Register\", grAny(\"T1\"), [gr" ~ t1 ~ "]);");
            }

            static if (t2 == "Ptr") {
                constraint2 = grConstraint("Register", grAny("T2"), [
                        GrType(GrType.Base.null_)
                    ]);
            }
            else {
                mixin("constraint2 = grConstraint(\"Register\", grAny(\"T2\"), [gr" ~ t2 ~ "]);");
            }

            library.addFunction(&_swap_2_!(t1, t2), "swap", [
                    grAny("T1"), grAny("T2")
                ], [grAny("T2"), grAny("T1")], [constraint1, constraint2]);
        }
    }
    static foreach (t; ["Int", "Real", "String", "Ptr"]) {
        static if (t == "Ptr") {
            constraint1 = grConstraint("Register", grAny("T1"), [
                    GrType(GrType.Base.null_)
                ]);
        }
        else {
            mixin("constraint1 = grConstraint(\"Register\", grAny(\"T1\"), [gr" ~ t ~ "]);");
        }

        library.addFunction(&_cond_!t, "cond", [
                grBool, grAny("T1"), grAny("T1")
            ], [grAny("T1")], [constraint1]);
    }

    library.addFunction(&_typeOf, "typeof", [grAny("T")], [grString]);
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
