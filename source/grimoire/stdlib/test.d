/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.test;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibTest(GrLibrary library, GrLocale locale) {
    library.addPrimitive(&_assert, "assert", [grBool]);
    library.addPrimitive(&_assert_msg, "assert", [grBool, grString]);
    library.addPrimitive(&_setMeta, "_setMeta", [grString]);
}

private void _assert(GrCall call) {
    const GrBool value = call.getBool(0);
    if (!value)
        call.raise("AssertError");
}

private void _assert_msg(GrCall call) {
    const GrBool value = call.getBool(0);
    if (!value)
        call.raise(call.getString(1));
}

private void _setMeta(GrCall call) {
    const GrString value = call.getString(0);
    call.context.engine.meta = value;
}