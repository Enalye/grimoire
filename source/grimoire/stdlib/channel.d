/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrLibrary library) {
    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("GrType " ~ t ~ "ChannelType = grChannel(grAny(\"T\"));

            static if(t == \"Object\") {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", grAny(\"T\"),
                    [GrType(GrType.Base.null_)]);
            }
            else {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", grAny(\"T\"), [gr" ~ t ~ "]);
            }

            library.addFunction(&_size_!\""
                ~ t ~ "\", \"size\", [
                    " ~ t ~ "ChannelType
                    ], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_capacity_!\""
                ~ t ~ "\", \"capacity\", [
                    " ~ t ~ "ChannelType
                    ], [grInt], [" ~ t ~ "Constraint]);
            library.addFunction(&_empty_!\""
                ~ t
                ~ "\", \"empty?\", [
                    " ~ t ~ "ChannelType
                    ], [grBool], [" ~ t ~ "Constraint]);
            library.addFunction(&_full_!\""
                ~ t ~ "\", \"full?\", [
                    " ~ t ~ "ChannelType
                    ], [grBool], [" ~ t ~ "Constraint]);
                    ");
    }
}

private void _size_(string t)(GrCall call) {
    mixin("call.setInt(cast(GrInt) call.get" ~ t ~ "Channel(0).size);");
}

private void _capacity_(string t)(GrCall call) {
    mixin("call.setInt(cast(GrInt) call.get" ~ t ~ "Channel(0).capacity);");
}

private void _empty_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(0);
    call.setBool(chan.isEmpty);");
}

private void _full_(string t)(GrCall call) {
    mixin("const Gr" ~ t ~ "Channel chan = call.get" ~ t ~ "Channel(0);
    call.setBool(chan.isFull);");
}
