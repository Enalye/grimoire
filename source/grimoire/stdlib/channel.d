/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrLibrary library) {
    GrType chanType = grPure(grChannel(grAny("T")));

    library.addFunction(&_size, "size", [chanType], [grInt]);
    library.addFunction(&_capacity, "capacity", [chanType], [grInt]);
    library.addFunction(&_empty, "empty", [chanType], [grBool]);
    library.addFunction(&_full, "full", [chanType], [grBool]);
}

private void _size(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).size);
}

private void _capacity(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).capacity);
}

private void _empty(GrCall call) {
    call.setBool(call.getChannel(0).isEmpty);
}

private void _full(GrCall call) {
    call.setBool(call.getChannel(0).isFull);
}
