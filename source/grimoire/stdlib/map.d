/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.map;

import std.typecons : Tuple, tuple;

import grimoire.compiler, grimoire.runtime;

/// Hashmap
private final class Map(T) {
    /// Payload
    T[string] data;

    /// Ctor
    this(string[] keys, T[] values) {
        for (int i; i < keys.length; ++i) {
            data[keys[i]] = values[i];
        }
    }
}

private {
    alias IntMap = Map!(int);
    alias FloatMap = Map!(float);
    alias StringMap = Map!(string);
    alias ObjectMap = Map!(void*);
}

/// Iterator
private final class MapIter(T) {
    Tuple!(string, T)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibMap(GrLibrary library) {
    library.addForeign("Map", ["T"]);
    library.addForeign("MapIter", ["T"]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Map = grAny(\"M\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Map\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"T\", subType.signature[0]);
                data.set(\"A\", grArray(subType.signature[0]));
                return grIsKindOf" ~ t ~ "(subType.signature[0].baseType);
            });

            GrType any" ~ t
                ~ "Array = grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"M\", grGetForeignType(\"Map\", [subType]));
                return grIsKindOf" ~ t ~ "(subType.baseType);
            });

            library.addPrimitive(&_make_!\"" ~ t
                ~ "\", \"Map\", [grStringArray, any" ~ t ~ "Array], [grAny(\"M\")]);

            library.addPrimitive(&_set_!\"" ~ t
                ~ "\", \"set\", [any" ~ t ~ "Map, grString, grAny(\"T\")]);

            library.addPrimitive(&_get_!\"" ~ t
                ~ "\", \"get\", [any" ~ t ~ "Map, grString], [grAny(\"T\")]);

            library.addPrimitive(&_has_!\""
                ~ t ~ "\", \"has?\", [any" ~ t ~ "Map, grString], [grBool]);

            library.addPrimitive(&_remove_!\"" ~ t
                ~ "\", \"remove\", [any" ~ t ~ "Map, grString]);

            library.addPrimitive(&_byKeys_!\"" ~ t ~ "\", \"byKeys\", [any"
                ~ t ~ "Map], [grStringArray]);

            library.addPrimitive(&_byValues_!\"" ~ t ~ "\", \"byValues\", [any" ~ t ~ "Map], [any" ~ t ~ "Array]);

            library.addPrimitive(&_each_!\""
                ~ t ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Map\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"R\", grGetForeignType(\"MapIter\", subType.signature));
                return grIsKindOf" ~ t ~ "(subType.signature[0].baseType);
            })
                ], [grAny(\"R\")]);

            library.addPrimitive(&_next_!\""
                ~ t ~ "\", \"next\", [
                    grAny(\"R\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != \"MapIter\")
                    return false;
                data.set(\"T\", grGetClassType(\"Pair\", [grString, result.signature[0]]));
                return grIsKindOf" ~ t ~ "(result.signature[0].baseType);
                    })
                ], [grBool, grAny(\"T\")]);
            ");
    }
}

private void _make_(string t)(GrCall call) {
    mixin(t ~ "Map map = new " ~ t ~ "Map(call.getStringArray(0).data, call.get" ~ t
            ~ "Array(1).data);");
    call.setForeign(map);
}

private void _set_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    static if (t == "Object") {
        map.data[call.getString(1)] = call.getPtr(2);
    }
    else {
        mixin("map.data[call.getString(1)] = call.get" ~ t ~ "(2);");
    }
}

private void _get_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    static if (t == "Object") {
        call.setPtr(map.data[call.getString(1)]);
    }
    else {
        mixin("call.set" ~ t ~ "(map.data[call.getString(1)]);");
    }
}

private void _has_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    call.setBool((call.getString(1) in map.data) !is null);
}

private void _remove_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    map.data.remove(call.getString(1));
}

private void _byKeys_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    GrStringArray ary = new GrStringArray;
    ary.data = map.data.keys;
    call.setStringArray(ary);
}

private void _byValues_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    mixin("Gr" ~ t ~ "Array ary = new Gr" ~ t ~ "Array;");
    ary.data = map.data.values;
    mixin("call.set" ~ t ~ "Array(ary);");
}

private void _each_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    static if (t == "Int") {
        MapIter!(int) iter = new MapIter!(int);
    }
    else static if (t == "Float") {
        MapIter!(float) iter = new MapIter!(float);
    }
    else static if (t == "String") {
        MapIter!(string) iter = new MapIter!(string);
    }
    else static if (t == "Object") {
        MapIter!(void*) iter = new MapIter!(void*);
    }
    foreach (pair; map.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        MapIter!(int) iter = call.getForeign!(MapIter!(int))(0);
    }
    else static if (t == "Float") {
        MapIter!(float) iter = call.getForeign!(MapIter!(float))(0);
    }
    else static if (t == "String") {
        MapIter!(string) iter = call.getForeign!(MapIter!(string))(0);
    }
    else static if (t == "Object") {
        MapIter!(void*) iter = call.getForeign!(MapIter!(void*))(0);
    }
    if (!iter) {
        call.raise("NullError");
        return;
    }
    if (iter.index >= iter.pairs.length) {
        call.setBool(false);
        call.setPtr(null);
        return;
    }
    call.setBool(true);
    static if (t == "Int") {
        GrObject obj = new GrObject(["first", "second"]);
        obj.setString("first", iter.pairs[iter.index][0]);
        obj.setInt("second", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Float") {
        GrObject obj = new GrObject(["first", "second"]);
        obj.setString("first", iter.pairs[iter.index][0]);
        obj.setFloat("second", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "String") {
        GrObject obj = new GrObject(["first", "second"]);
        obj.setString("first", iter.pairs[iter.index][0]);
        obj.setString("second", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Object") {
        GrObject obj = new GrObject(["first", "second"]);
        obj.setString("first", iter.pairs[iter.index][0]);
        obj.setPtr("second", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    iter.index++;
}
