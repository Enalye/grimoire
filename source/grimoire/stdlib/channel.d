/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.channel;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;

package(grimoire.stdlib) void grLoadStdLibChannel(GrLibrary library, GrLocale locale) {
    string _sizeSymbol, _capacitySymbol, _emptySymbol, _fullSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _sizeSymbol = "size";
        _capacitySymbol = "capacity";
        _emptySymbol = "empty?";
        _fullSymbol = "full?";
        break;
    case fr_FR:
        _sizeSymbol = "taille";
        _capacitySymbol = "capacité";
        _emptySymbol = "vide?";
        _fullSymbol = "plein?";
        break;
    }

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Channel = grAny(\"C\", (type, data) {
                if (type.base != GrType.Base.channel)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                return grIsKindOf"
                ~ t ~ "(subType.base);
            });
            library.addPrimitive(&_size_!\""
                ~ t ~ "\", _sizeSymbol, [
                    any"
                ~ t ~ "Channel
                    ], [grInt]);
            library.addPrimitive(&_capacity_!\""
                ~ t ~ "\", _capacitySymbol, [
                    any"
                ~ t ~ "Channel
                    ], [grInt]);
            library.addPrimitive(&_empty_!\""
                ~ t
                ~ "\", _emptySymbol, [
                    any"
                ~ t ~ "Channel
                    ], [grBool]);
            library.addPrimitive(&_full_!\""
                ~ t ~ "\", _fullSymbol, [
                    any"
                ~ t ~ "Channel
                    ], [grBool]);
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
