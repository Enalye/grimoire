/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

void grLoadStdLibChannel(GrLibDefinition library) {
    library.setModule(["std", "channel"]);

    GrType chanType = grPure(grChannel(grAny("T")));

    library.addFunction(&_size, "size", [chanType], [grInt]);
    library.addFunction(&_capacity, "capacity", [chanType], [grInt]);
    library.addFunction(&_isEmpty, "isEmpty", [chanType], [grBool]);
    library.addFunction(&_isFull, "isFull", [chanType], [grBool]);
}

private void _size(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).size);
}

private void _capacity(GrCall call) {
    call.setInt(cast(GrInt) call.getChannel(0).capacity);
}

private void _isEmpty(GrCall call) {
    call.setBool(call.getChannel(0).isEmpty);
}

private void _isFull(GrCall call) {
    call.setBool(call.getChannel(0).isFull);
}
