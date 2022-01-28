/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.dictionary;

import std.typecons : Tuple, tuple;
import std.conv : to;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

/// Dictionary
private final class Dictionary(T) {
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

    this(Dictionary!T dictionary) {
        data = dictionary.data.dup;
    }
}

private {
    alias IntDictionary = Dictionary!(GrInt);
    alias RealDictionary = Dictionary!(GrReal);
    alias StringDictionary = Dictionary!(GrString);
    alias ObjectDictionary = Dictionary!(GrPtr);
}

/// Iterator
private final class DictionaryIter(T) {
    Tuple!(GrString, T)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibDictionary(GrLibrary library) {
    library.addForeign("Dictionary", ["T"]);
    library.addForeign("DictionaryIterator", ["T"]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Dictionary = grAny(\"M\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Dictionary\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"T\", subType.signature[0]);
                data.set(\"A\", grList(subType.signature[0]));
                return grIsKindOf"
                ~ t
                ~ "(subType.signature[0].base);
            });

            GrType any"
                ~ t ~ "List = grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.list_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                data.set(\"M\", grGetForeignType(\"Dictionary\", [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.base);
            });

            library.addFunction(&_make_!\""
                ~ t ~ "\", \"Dictionary\", [grStringList, any" ~ t
                ~ "List], [grAny(\"M\")]);

            library.addFunction(&_makeByPairs_!\""
                ~ t ~ "\", \"Dictionary\", [grAny(\"T\", (type, data) {
                if (type.base != GrType.Base.list_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                if(subType.base != GrType.Base.class_)
                    return false;
                auto pairType = grUnmangleComposite(subType.mangledType);
                if(pairType.name != \"Pair\" || pairType.signature.length != 2 || pairType.signature[0].base != GrType.Base.string_)
                    return false;
                data.set(\"M\", grGetForeignType(\"Dictionary\", [pairType.signature[1]]));
                return true;
                })], [grAny(\"M\")]);

            library.addFunction(&_copy_!\""
                ~ t ~ "\", \"copy\", [any" ~ t ~ "Dictionary], [grAny(\"M\")]);

            library.addFunction(&_size_!\""
                ~ t ~ "\", \"size\", [any"
                ~ t ~ "Dictionary], [grInt]);

            library.addFunction(&_empty_!\""
                ~ t ~ "\", \"empty?\", [
                any"
                ~ t ~ "Dictionary
            ], [grBool]);

            library.addFunction(&_clear_!\""
                ~ t ~ "\", \"clear\", [
                any"
                ~ t ~ "Dictionary
            ], [grAny(\"M\")]);

            library.addFunction(&_set_!\""
                ~ t
                ~ "\", \"set\", [any" ~ t ~ "Dictionary, grString, grAny(\"T\")]);

            library.addFunction(&_get_!\""
                ~ t
                ~ "\", \"get\", [any" ~ t ~ "Dictionary, grString], [grBool, grAny(\"T\")]);

            library.addFunction(&_has_!\""
                ~ t ~ "\", \"has?\", [any" ~ t ~ "Dictionary, grString], [grBool]);

            library.addFunction(&_remove_!\""
                ~ t
                ~ "\", \"remove\", [any" ~ t ~ "Dictionary, grString]);

            library.addFunction(&_byKeys_!\""
                ~ t ~ "\", \"byKeys\", [any" ~ t
                ~ "Dictionary], [grStringList]);

            library.addFunction(&_byValues_!\""
                ~ t ~ "\", \"byValues\", [any" ~ t ~ "Dictionary], [any"
                ~ t ~ "List]);

            library.addFunction(&_each_!\""
                ~ t ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Dictionary\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"R\", grGetForeignType(\"DictionaryIterator\", subType.signature));
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
                if(result.signature.length != 1 || result.name != \"DictionaryIterator\")
                    return false;
                data.set(\"T\", grGetClassType(\"Pair\", [grString, result.signature[0]]));
                return grIsKindOf"
                ~ t ~ "(result.signature[0].base);
                    })
                ], [grBool, grAny(\"T\")]);
            ");
    }

    GrType boolDictionary = grGetForeignType("Dictionary", [grBool]);
    library.addFunction(&_print_!"bool", "print", [boolDictionary]);

    GrType intDictionary = grGetForeignType("Dictionary", [grInt]);
    library.addFunction(&_print_!"int", "print", [intDictionary]);

    GrType realDictionary = grGetForeignType("Dictionary", [grReal]);
    library.addFunction(&_print_!"real", "print", [realDictionary]);

    GrType stringDictionary = grGetForeignType("Dictionary", [grString]);
    library.addFunction(&_print_!"string", "print", [stringDictionary]);
}

private void _make_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = new " ~ t ~ "Dictionary(call.getStringList(0).data, call.get"
            ~ t ~ "List(1).data);");
    call.setForeign(dictionary);
}

private void _makeByPairs_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = new " ~ t ~ "Dictionary;");
    GrObjectList pairs = call.getObjectList(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i];
        static if (t == "Object") {
            auto value = pair.getPtr("value");
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(\"value\");");
        }
        dictionary.data[pair.getString("key")] = value;
    }
    call.setForeign(dictionary);
}

private void _copy_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    mixin("call.setForeign!" ~ t ~ "Dictionary(new " ~ t ~ "Dictionary(dictionary));");
}

private void _size_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    call.setInt(cast(GrInt) dictionary.data.length);
}

private void _empty_(string t)(GrCall call) {
    mixin("const " ~ t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    call.setBool(dictionary.data.length == 0);
}

private void _clear_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    dictionary.data.clear();
    mixin("call.setForeign!" ~ t ~ "Dictionary(dictionary);");
}

private void _set_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    static if (t == "Object") {
        dictionary.data[call.getString(1)] = call.getPtr(2);
    }
    else {
        mixin("dictionary.data[call.getString(1)] = call.get" ~ t ~ "(2);");
    }
}

private void _get_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    static if (t == "Object") {
        auto p = call.getString(1) in dictionary.data;
        call.setBool(p !is null);
        call.setPtr(p ? *p : null);
    }
    else {
        auto p = call.getString(1) in dictionary.data;
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
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    call.setBool((call.getString(1) in dictionary.data) !is null);
}

private void _remove_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    dictionary.data.remove(call.getString(1));
}

private void _byKeys_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    GrStringList ary = new GrStringList;
    ary.data = dictionary.data.keys;
    call.setStringList(ary);
}

private void _byValues_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    mixin("Gr" ~ t ~ "List ary = new Gr" ~ t ~ "List;");
    ary.data = dictionary.data.values;
    mixin("call.set" ~ t ~ "List(ary);");
}

private void _each_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    static if (t == "Int") {
        DictionaryIter!(GrInt) iter = new DictionaryIter!(GrInt);
    }
    else static if (t == "Real") {
        DictionaryIter!(GrReal) iter = new DictionaryIter!(GrReal);
    }
    else static if (t == "String") {
        DictionaryIter!(GrString) iter = new DictionaryIter!(GrString);
    }
    else static if (t == "Object") {
        DictionaryIter!(GrPtr) iter = new DictionaryIter!(GrPtr);
    }
    foreach (pair; dictionary.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        DictionaryIter!(GrInt) iter = call.getForeign!(DictionaryIter!(GrInt))(0);
    }
    else static if (t == "Real") {
        DictionaryIter!(GrReal) iter = call.getForeign!(DictionaryIter!(GrReal))(0);
    }
    else static if (t == "String") {
        DictionaryIter!(GrString) iter = call.getForeign!(DictionaryIter!(GrString))(0);
    }
    else static if (t == "Object") {
        DictionaryIter!(GrPtr) iter = call.getForeign!(DictionaryIter!(GrPtr))(0);
    }
    if (!iter) {
        call.raise(_paramError);
        return;
    }
    if (iter.index >= iter.pairs.length) {
        call.setBool(false);
        call.setPtr(null);
        return;
    }
    call.setBool(true);
    static if (t == "Int") {
        GrObject obj = new GrObject(["key", "value"]);
        obj.setString("key", iter.pairs[iter.index][0]);
        obj.setInt("value", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Real") {
        GrObject obj = new GrObject(["key", "value"]);
        obj.setString("key", iter.pairs[iter.index][0]);
        obj.setReal("value", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "String") {
        GrObject obj = new GrObject(["key", "value"]);
        obj.setString("key", iter.pairs[iter.index][0]);
        obj.setString("value", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Object") {
        GrObject obj = new GrObject(["key", "value"]);
        obj.setString("key", iter.pairs[iter.index][0]);
        obj.setPtr("value", iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    iter.index++;
}

private void _print_(string t)(GrCall call) {
    static if (t == "bool" || t == "int") {
        IntDictionary dictionary = call.getForeign!(IntDictionary)(0);
    }
    else static if (t == "real") {
        RealDictionary dictionary = call.getForeign!(RealDictionary)(0);
    }
    else static if (t == "string") {
        StringDictionary dictionary = call.getForeign!(StringDictionary)(0);
    }
    if (!dictionary) {
        call.raise(_paramError);
        return;
    }
    GrString result = "{";
    bool isFirst = true;
    foreach (key, value; dictionary.data) {
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
