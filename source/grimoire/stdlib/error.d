/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.error;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibError(GrLibrary library) {
    library.addFunction(&_assert, "assert", [grBool]);
    library.addFunction(&_assert_msg, "assert", [grBool, grPure(grString)]);
    library.addFunction(&_setMeta, "_setMeta", [grPure(grString)]);
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
    const GrStringValue value = call.getString(0);
    call.task.engine.meta = value;
}
