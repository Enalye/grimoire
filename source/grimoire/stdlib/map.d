/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.map;

import std.typecons : Tuple, tuple;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

/// Hashmap
private final class Map(T) {
    /// Payload
    T[GrString] data;

    /// Ctor
    this(GrString[] keys, T[] values) {
        for (size_t i; i < keys.length; ++i) {
            data[keys[i]] = values[i];
        }
    }
    /// Ditto
    this() {
    }

    this(Map!T map) {
        data = map.data.dup;
    }
}

private {
    alias IntMap = Map!(GrInt);
    alias FloatMap = Map!(GrFloat);
    alias StringMap = Map!(GrString);
    alias ObjectMap = Map!(GrPtr);
}

/// Iterator
private final class MapIter(T) {
    Tuple!(GrString, T)[] pairs;
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
                return grIsKindOf" ~ t
                ~ "(subType.signature[0].baseType);
            });

            GrType any" ~ t ~ "Array = grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"M\", grGetForeignType(\"Map\", [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.baseType);
            });

            library.addPrimitive(&_make_!\"" ~ t ~ "\", \"Map\", [grStringArray, any" ~ t
                ~ "Array], [grAny(\"M\")]);

            library.addPrimitive(&_makeByPairs_!\"" ~ t ~ "\", \"Map\", [grAny(\"T\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                if(subType.baseType != GrBaseType.class_)
                    return false;
                auto pairType = grUnmangleComposite(subType.mangledType);
                if(pairType.name != \"Pair\" || pairType.signature.length != 2 || pairType.signature[0].baseType != GrBaseType.string_)
                    return false;
                data.set(\"M\", grGetForeignType(\"Map\", [pairType.signature[1]]));
                return true;
                })], [grAny(\"M\")]);

            library.addPrimitive(&_copy_!\""
                ~ t ~ "\", \"copy\", [any" ~ t ~ "Map], [grAny(\"M\")]);

            library.addPrimitive(&_size_!\"" ~ t ~ "\", \"size\", [any"
                ~ t ~ "Map], [grInt]);

            library.addPrimitive(&_empty_!\"" ~ t ~ "\", \"empty?\", [
                any" ~ t ~ "Map
            ], [grBool]);

            library.addPrimitive(&_clear_!\"" ~ t ~ "\", \"clear\", [
                any" ~ t ~ "Map
            ], [grAny(\"M\")]);

            library.addPrimitive(&_set_!\"" ~ t
                ~ "\", \"set\", [any" ~ t ~ "Map, grString, grAny(\"T\")]);

            library.addPrimitive(&_get_!\"" ~ t
                ~ "\", \"get\", [any" ~ t ~ "Map, grString], [grBool, grAny(\"T\")]);

            library.addPrimitive(&_has_!\""
                ~ t ~ "\", \"has?\", [any" ~ t ~ "Map, grString], [grBool]);

            library.addPrimitive(&_remove_!\"" ~ t
                ~ "\", \"remove\", [any" ~ t ~ "Map, grString]);

            library.addPrimitive(&_byKeys_!\"" ~ t ~ "\", \"byKeys\", [any" ~ t
                ~ "Map], [grStringArray]);

            library.addPrimitive(&_byValues_!\"" ~ t ~ "\", \"byValues\", [any" ~ t ~ "Map], [any"
                ~ t ~ "Array]);

            library.addPrimitive(&_each_!\"" ~ t ~ "\", \"each\", [
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

    GrType boolMap = grGetForeignType("Map", [grBool]);
    library.addPrimitive(&_print_!("bool", false), "print", [boolMap]);
    library.addPrimitive(&_print_!("bool", true), "printl", [boolMap]);

    GrType intMap = grGetForeignType("Map", [grInt]);
    library.addPrimitive(&_print_!("int", false), "print", [intMap]);
    library.addPrimitive(&_print_!("int", true), "printl", [intMap]);

    GrType floatMap = grGetForeignType("Map", [grFloat]);
    library.addPrimitive(&_print_!("float", false), "print", [floatMap]);
    library.addPrimitive(&_print_!("float", true), "printl", [floatMap]);

    GrType stringMap = grGetForeignType("Map", [grString]);
    library.addPrimitive(&_print_!("string", false), "print", [stringMap]);
    library.addPrimitive(&_print_!("string", true), "printl", [stringMap]);
}

private void _make_(string t)(GrCall call) {
    mixin(t ~ "Map map = new " ~ t ~ "Map(call.getStringArray(0).data, call.get"
            ~ t ~ "Array(1).data);");
    call.setForeign(map);
}

private void _makeByPairs_(string t)(GrCall call) {
    mixin(t ~ "Map map = new " ~ t ~ "Map;");
    GrObjectArray pairs = call.getObjectArray(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i];
        static if (t == "Object") {
            auto value = pair.getPtr("second");
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(\"second\");");
        }
        map.data[pair.getString("first")] = value;
    }
    call.setForeign(map);
}

private void _copy_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!" ~ t ~ "Map(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    mixin("call.setForeign!" ~ t ~ "Map(new " ~ t ~ "Map(map));");
}

private void _size_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!" ~ t ~ "Map(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    call.setInt(cast(GrInt) map.data.length);
}

private void _empty_(string t)(GrCall call) {
    mixin("const " ~ t ~ "Map map = call.getForeign!" ~ t ~ "Map(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    call.setBool(map.data.length == 0);
}

private void _clear_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!" ~ t ~ "Map(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    map.data.clear();
    mixin("call.setForeign!" ~ t ~ "Map(map);");
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
        auto p = call.getString(1) in map.data;
        call.setBool(p !is null);
        call.setPtr(p ? *p : null);
    }
    else {
        auto p = call.getString(1) in map.data;
        call.setBool(p !is null);
        static if(t == "Int") {
            call.setInt(p ? *p : 0);
        }
        else static if(t == "Float") {
            call.setFloat(p ? *p : 0f);
        }
        else static if(t == "String") {
            call.setString(p ? *p : "");
        }
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

private void _printb_(string t)(GrCall call) {
    Map map = call.getForeign!(IntMap)(0);
    if (!map) {
        call.raise("NullError");
        return;
    }
    GrString result = "{";
    bool isFirst = true;
    foreach (key, value; map.data) {
        if (isFirst) {
            isFirst = false;
        }
        else {
            result ~= ", ";
        }
        result ~= "\"" ~ key ~ "\"=>" ~ to!string(cast(GrBool) value);
    }
    result ~= "}";
    _stdOut(result);
}

private void _printlb_(string t)(GrCall call) {
    Map map = call.getForeign!(IntMap)(0);
    if (!map) {
        call.raise("NullError");
        return;
    }
    GrString result = "{";
    bool isFirst = true;
    foreach (key, value; map.data) {
        if (isFirst) {
            isFirst = false;
        }
        else {
            result ~= ", ";
        }
        result ~= "\"" ~ key ~ "\"=>" ~ to!string(cast(GrBool) value);
    }
    result ~= "}\n";
    _stdOut(result);
}

private void _each_(string t)(GrCall call) {
    mixin(t ~ "Map map = call.getForeign!(" ~ t ~ "Map)(0);");
    if (!map) {
        call.raise("NullError");
        return;
    }
    static if (t == "Int") {
        MapIter!(GrInt) iter = new MapIter!(GrInt);
    }
    else static if (t == "Float") {
        MapIter!(GrFloat) iter = new MapIter!(GrFloat);
    }
    else static if (t == "String") {
        MapIter!(GrString) iter = new MapIter!(GrString);
    }
    else static if (t == "Object") {
        MapIter!(GrPtr) iter = new MapIter!(GrPtr);
    }
    foreach (pair; map.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        MapIter!(GrInt) iter = call.getForeign!(MapIter!(GrInt))(0);
    }
    else static if (t == "Float") {
        MapIter!(GrFloat) iter = call.getForeign!(MapIter!(GrFloat))(0);
    }
    else static if (t == "String") {
        MapIter!(GrString) iter = call.getForeign!(MapIter!(GrString))(0);
    }
    else static if (t == "Object") {
        MapIter!(GrPtr) iter = call.getForeign!(MapIter!(GrPtr))(0);
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

private void _print_(string t, bool newLine)(GrCall call) {
    static if (t == "bool" || t == "int") {
        IntMap map = call.getForeign!(IntMap)(0);
    }
    else static if (t == "float") {
        FloatMap map = call.getForeign!(FloatMap)(0);
    }
    else static if (t == "string") {
        StringMap map = call.getForeign!(StringMap)(0);
    }
    if (!map) {
        call.raise("NullError");
        return;
    }
    GrString result = "{";
    bool isFirst = true;
    foreach (key, value; map.data) {
        if (isFirst) {
            isFirst = false;
        }
        else {
            result ~= ", ";
        }
        result ~= "\"" ~ key ~ "\"=>";
        static if (t == "string") {
            result ~= "\"" ~ to!string(value) ~ "\"";
        }
        else static if (t == "bool") {
            result ~= to!string(cast(bool) value);
        }
        else {
            result ~= to!string(value);
        }
    }
    result ~= newLine ? "}\n" : "}";
    _stdOut(result);
}
