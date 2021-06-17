/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrLibrary library) {
    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Channel = grAny(\"C\", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOf" ~ t ~ "(subType.baseType);
            });
            library.addPrimitive(&_size_!\"" ~ t ~ "\", \"size\", [
                    any"
                ~ t ~ "Channel
                    ], [grInt]);
            library.addPrimitive(&_capacity_!\"" ~ t ~ "\", \"capacity\", [
                    any" ~ t ~ "Channel
                    ], [grInt]);
            library.addPrimitive(&_empty_!\"" ~ t
                ~ "\", \"empty?\", [
                    any" ~ t ~ "Channel
                    ], [grBool]);
            library.addPrimitive(&_full_!\""
                ~ t ~ "\", \"full?\", [
                    any" ~ t ~ "Channel
                    ], [grBool]);
                    ");
    }
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Channel(0).size);");
}

private void _capacity_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Channel(0).capacity);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(0);
    call.setBool(chan.isEmpty);");
}

private void _full_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(0);
    call.setBool(chan.isFull);");
}
