/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.hashmap;

import std.typecons : Tuple, tuple;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

/// HashMap
private final class HashMap(T) {
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

    this(HashMap!T hashmap) {
        data = hashmap.data.dup;
    }
}

private {
    alias IntHashMap = HashMap!(GrInt);
    alias RealHashMap = HashMap!(GrReal);
    alias StringHashMap = HashMap!(GrString);
    alias ObjectHashMap = HashMap!(GrPtr);
}

/// Iterator
private final class IterHashMap(T) {
    Tuple!(GrString, T)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibHashMap(GrLibrary library) {
    library.addForeign("HashMap", ["T"]);
    library.addForeign("IterHashMap", ["T"]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "HashMap = grAny(\"M\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"HashMap\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"T\", subType.signature[0]);
                data.set(\"A\", grArray(subType.signature[0]));
                return grIsKindOf"
                ~ t
                ~ "(subType.signature[0].base);
            });

            GrType any"
                ~ t ~ "Array = grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.array)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"M\", grGetForeignType(\"HashMap\", [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.base);
            });

            library.addFunction(&_make_!\""
                ~ t ~ "\", \"HashMap\", [grStringArray, any" ~ t
                ~ "Array], [grAny(\"M\")]);

            library.addFunction(&_makeByPairs_!\""
                ~ t ~ "\", \"HashMap\", [grAny(\"T\", (type, data) {
                if (type.base != GrType.Base.array)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                if(subType.base != GrType.Base.class_)
                    return false;
                auto pairType = grUnmangleComposite(subType.mangledType);
                if(pairType.name != \"Pair\" || pairType.signature.length != 2 || pairType.signature[0].base != GrType.Base.string_)
                    return false;
                data.set(\"M\", grGetForeignType(\"HashMap\", [pairType.signature[1]]));
                return true;
                })], [grAny(\"M\")]);

            library.addFunction(&_copy_!\""
                ~ t ~ "\", \"copy\", [any" ~ t ~ "HashMap], [grAny(\"M\")]);

            library.addFunction(&_size_!\""
                ~ t ~ "\", \"size\", [any"
                ~ t ~ "HashMap], [grInt]);

            library.addFunction(&_empty_!\""
                ~ t ~ "\", \"empty?\", [
                any"
                ~ t ~ "HashMap
            ], [grBool]);

            library.addFunction(&_clear_!\""
                ~ t ~ "\", \"clear\", [
                any"
                ~ t ~ "HashMap
            ], [grAny(\"M\")]);

            library.addFunction(&_set_!\""
                ~ t
                ~ "\", \"set\", [any" ~ t ~ "HashMap, grString, grAny(\"T\")]);

            library.addFunction(&_get_!\""
                ~ t
                ~ "\", \"get\", [any" ~ t ~ "HashMap, grString], [grBool, grAny(\"T\")]);

            library.addFunction(&_has_!\""
                ~ t ~ "\", \"has?\", [any" ~ t ~ "HashMap, grString], [grBool]);

            library.addFunction(&_remove_!\""
                ~ t
                ~ "\", \"remove\", [any" ~ t ~ "HashMap, grString]);

            library.addFunction(&_byKeys_!\""
                ~ t ~ "\", \"byKeys\", [any" ~ t
                ~ "HashMap], [grStringArray]);

            library.addFunction(&_byValues_!\""
                ~ t ~ "\", \"byValues\", [any" ~ t ~ "HashMap], [any"
                ~ t ~ "Array]);

            library.addFunction(&_each_!\""
                ~ t ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"HashMap\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"R\", grGetForeignType(\"IterHashMap\", subType.signature));
                return grIsKindOf"
                ~ t ~ "(subType.signature[0].base);
            })
                ], [grAny(\"R\")]);

            library.addFunction(&_next_!\""
                ~ t ~ "\", \"next\", [
                    grAny(\"R\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != \"IterHashMap\")
                    return false;
                data.set(\"T\", grGetClassType(\"Pair\", [grString, result.signature[0]]));
                return grIsKindOf"
                ~ t ~ "(result.signature[0].base);
                    })
                ], [grBool, grAny(\"T\")]);
            ");
    }

    GrType boolHashMap = grGetForeignType("HashMap", [grBool]);
    library.addFunction(&_print_!"bool", "print", [boolHashMap]);

    GrType intHashMap = grGetForeignType("HashMap", [grInt]);
    library.addFunction(&_print_!"int", "print", [intHashMap]);

    GrType realHashMap = grGetForeignType("HashMap", [grReal]);
    library.addFunction(&_print_!"real", "print", [realHashMap]);

    GrType stringHashMap = grGetForeignType("HashMap", [grString]);
    library.addFunction(&_print_!"string", "print", [stringHashMap]);
}

private void _make_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = new " ~ t ~ "HashMap(call.getStringArray(0).data, call.get"
            ~ t ~ "Array(1).data);");
    call.setForeign(hashmap);
}

private void _makeByPairs_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = new " ~ t ~ "HashMap;");
    GrObjectArray pairs = call.getObjectArray(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i];
        static if (t == "Object") {
            auto value = pair.getPtr("second");
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(\"second\");");
        }
        hashmap.data[pair.getString("first")] = value;
    }
    call.setForeign(hashmap);
}

private void _copy_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!" ~ t ~ "HashMap(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    mixin("call.setForeign!" ~ t ~ "HashMap(new " ~ t ~ "HashMap(hashmap));");
}

private void _size_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!" ~ t ~ "HashMap(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setInt(cast(GrInt) hashmap.data.length);
}

private void _empty_(string t)(GrCall call) {
    mixin("const " ~ t ~ "HashMap hashmap = call.getForeign!" ~ t ~ "HashMap(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setBool(hashmap.data.length == 0);
}

private void _clear_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!" ~ t ~ "HashMap(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    hashmap.data.clear();
    mixin("call.setForeign!" ~ t ~ "HashMap(hashmap);");
}

private void _set_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    static if (t == "Object") {
        hashmap.data[call.getString(1)] = call.getPtr(2);
    }
    else {
        mixin("hashmap.data[call.getString(1)] = call.get" ~ t ~ "(2);");
    }
}

private void _get_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    static if (t == "Object") {
        auto p = call.getString(1) in hashmap.data;
        call.setBool(p !is null);
        call.setPtr(p ? *p : null);
    }
    else {
        auto p = call.getString(1) in hashmap.data;
        call.setBool(p !is null);
        static if (t == "Int") {
            call.setInt(p ? *p : 0);
        }
        else static if (t == "Real") {
            call.setReal(p ? *p : 0f);
        }
        else static if (t == "String") {
            call.setString(p ? *p : "");
        }
    }
}

private void _has_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setBool((call.getString(1) in hashmap.data) !is null);
}

private void _remove_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    hashmap.data.remove(call.getString(1));
}

private void _byKeys_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    GrStringArray ary = new GrStringArray;
    ary.data = hashmap.data.keys;
    call.setStringArray(ary);
}

private void _byValues_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    mixin("Gr" ~ t ~ "Array ary = new Gr" ~ t ~ "Array;");
    ary.data = hashmap.data.values;
    mixin("call.set" ~ t ~ "Array(ary);");
}

private void _each_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = call.getForeign!(" ~ t ~ "HashMap)(0);");
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    static if (t == "Int") {
        IterHashMap!(GrInt) iter = new IterHashMap!(GrInt);
    }
    else static if (t == "Real") {
        IterHashMap!(GrReal) iter = new IterHashMap!(GrReal);
    }
    else static if (t == "String") {
        IterHashMap!(GrString) iter = new IterHashMap!(GrString);
    }
    else static if (t == "Object") {
        IterHashMap!(GrPtr) iter = new IterHashMap!(GrPtr);
    }
    foreach (pair; hashmap.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        IterHashMap!(GrInt) iter = call.getForeign!(IterHashMap!(GrInt))(0);
    }
    else static if (t == "Real") {
        IterHashMap!(GrReal) iter = call.getForeign!(IterHashMap!(GrReal))(0);
    }
    else static if (t == "String") {
        IterHashMap!(GrString) iter = call.getForeign!(IterHashMap!(GrString))(0);
    }
    else static if (t == "Object") {
        IterHashMap!(GrPtr) iter = call.getForeign!(IterHashMap!(GrPtr))(0);
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
    else static if (t == "Real") {
        GrObject obj = new GrObject(["first", "second"]);
        obj.setString("first", iter.pairs[iter.index][0]);
        obj.setReal("second", iter.pairs[iter.index][1]);
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

private void _print_(string t)(GrCall call) {
    static if (t == "bool" || t == "int") {
        IntHashMap hashmap = call.getForeign!(IntHashMap)(0);
    }
    else static if (t == "real") {
        RealHashMap hashmap = call.getForeign!(RealHashMap)(0);
    }
    else static if (t == "string") {
        StringHashMap hashmap = call.getForeign!(StringHashMap)(0);
    }
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    GrString result = "{";
    bool isFirst = true;
    foreach (key, value; hashmap.data) {
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
    result ~= "}";
    _stdOut(result);
}
