/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrData data) {
    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Channel = grAny(\"C\", (type, data) {
                if (type.baseType != GrBaseType.chan)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOf" ~ t
                ~ "(subType.baseType);
            });
            data.addPrimitive(&_size_!\"" ~ t ~ "\", \"size\", [\"chan\"], [
                    any" ~ t ~ "Channel
                    ], [grInt]);
            data.addPrimitive(&_capacity_!\""
                ~ t ~ "\", \"capacity\", [\"chan\"], [
                    any" ~ t ~ "Channel
                    ], [grInt]);
            data.addPrimitive(&_empty_!\"" ~ t ~ "\", \"empty?\", [\"chan\"], [
                    any"
                ~ t ~ "Channel
                    ], [grBool]);

            data.addPrimitive(&_full_!\"" ~ t
                ~ "\", \"full?\", [\"chan\"], [
                    any" ~ t ~ "Channel
                    ], [grBool]);
                    ");
    }
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Channel(\"chan\").size);");
}

private void _capacity_(string t)(GrCall call) {
    mixin("call.setInt(cast(int) call.get" ~ t ~ "Channel(\"chan\").capacity);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(\"chan\");
    call.setBool(chan.isEmpty);");
}

private void _full_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(\"chan\");
    call.setBool(chan.isFull);");
}
