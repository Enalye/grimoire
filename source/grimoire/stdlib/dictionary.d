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
    alias FloatDictionary = Dictionary!(GrFloat);
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
    library.addForeign("DictionaryIter", ["T"]);

    static foreach (t; ["Int", "Float", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Dictionary = grAny(\"M\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Dictionary\")
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
                data.set(\"M\", grGetForeignType(\"Dictionary\", [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.baseType);
            });

            library.addPrimitive(&_make_!\"" ~ t ~ "\", \"Dictionary\", [grStringArray, any" ~ t
                ~ "Array], [grAny(\"M\")]);

            library.addPrimitive(&_makeByPairs_!\"" ~ t ~ "\", \"Dictionary\", [grAny(\"T\", (type, data) {
                if (type.baseType != GrBaseType.array_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                if(subType.baseType != GrBaseType.class_)
                    return false;
                auto pairType = grUnmangleComposite(subType.mangledType);
                if(pairType.name != \"Pair\" || pairType.signature.length != 2 || pairType.signature[0].baseType != GrBaseType.string_)
                    return false;
                data.set(\"M\", grGetForeignType(\"Dictionary\", [pairType.signature[1]]));
                return true;
                })], [grAny(\"M\")]);

            library.addPrimitive(&_copy_!\""
                ~ t ~ "\", \"copy\", [any" ~ t ~ "Dictionary], [grAny(\"M\")]);

            library.addPrimitive(&_size_!\"" ~ t ~ "\", \"size\", [any"
                ~ t ~ "Dictionary], [grInt]);

            library.addPrimitive(&_empty_!\"" ~ t ~ "\", \"empty?\", [
                any" ~ t ~ "Dictionary
            ], [grBool]);

            library.addPrimitive(&_clear_!\"" ~ t ~ "\", \"clear\", [
                any" ~ t ~ "Dictionary
            ], [grAny(\"M\")]);

            library.addPrimitive(&_set_!\"" ~ t
                ~ "\", \"set\", [any" ~ t ~ "Dictionary, grString, grAny(\"T\")]);

            library.addPrimitive(&_get_!\"" ~ t
                ~ "\", \"get\", [any" ~ t ~ "Dictionary, grString], [grBool, grAny(\"T\")]);

            library.addPrimitive(&_has_!\""
                ~ t ~ "\", \"has?\", [any" ~ t ~ "Dictionary, grString], [grBool]);

            library.addPrimitive(&_remove_!\"" ~ t
                ~ "\", \"remove\", [any" ~ t ~ "Dictionary, grString]);

            library.addPrimitive(&_byKeys_!\"" ~ t ~ "\", \"byKeys\", [any" ~ t
                ~ "Dictionary], [grStringArray]);

            library.addPrimitive(&_byValues_!\"" ~ t ~ "\", \"byValues\", [any" ~ t ~ "Dictionary], [any"
                ~ t ~ "Array]);

            library.addPrimitive(&_each_!\"" ~ t ~ "\", \"each\", [
                    grAny(\"A\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != \"Dictionary\")
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"R\", grGetForeignType(\"DictionaryIter\", subType.signature));
                return grIsKindOf" ~ t ~ "(subType.signature[0].baseType);
            })
                ], [grAny(\"R\")]);

            library.addPrimitive(&_next_!\""
                ~ t ~ "\", \"next\", [
                    grAny(\"R\", (type, data) {
                if (type.baseType != GrBaseType.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != \"DictionaryIter\")
                    return false;
                data.set(\"T\", grGetClassType(\"Pair\", [grString, result.signature[0]]));
                return grIsKindOf" ~ t ~ "(result.signature[0].baseType);
                    })
                ], [grBool, grAny(\"T\")]);
            ");
    }

    GrType boolDictionary = grGetForeignType("Dictionary", [grBool]);
    library.addPrimitive(&_print_!("bool", false), "print", [boolDictionary]);
    library.addPrimitive(&_print_!("bool", true), "printl", [boolDictionary]);

    GrType intDictionary = grGetForeignType("Dictionary", [grInt]);
    library.addPrimitive(&_print_!("int", false), "print", [intDictionary]);
    library.addPrimitive(&_print_!("int", true), "printl", [intDictionary]);

    GrType floatDictionary = grGetForeignType("Dictionary", [grFloat]);
    library.addPrimitive(&_print_!("float", false), "print", [floatDictionary]);
    library.addPrimitive(&_print_!("float", true), "printl", [floatDictionary]);

    GrType stringDictionary = grGetForeignType("Dictionary", [grString]);
    library.addPrimitive(&_print_!("string", false), "print", [stringDictionary]);
    library.addPrimitive(&_print_!("string", true), "printl", [stringDictionary]);
}

private void _make_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = new " ~ t ~ "Dictionary(call.getStringArray(0).data, call.get"
            ~ t ~ "Array(1).data);");
    call.setForeign(dictionary);
}

private void _makeByPairs_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = new " ~ t ~ "Dictionary;");
    GrObjectArray pairs = call.getObjectArray(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i];
        static if (t == "Object") {
            auto value = pair.getPtr("second");
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(\"second\");");
        }
        dictionary.data[pair.getString("first")] = value;
    }
    call.setForeign(dictionary);
}

private void _copy_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    mixin("call.setForeign!" ~ t ~ "Dictionary(new " ~ t ~ "Dictionary(dictionary));");
}

private void _size_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    call.setInt(cast(GrInt) dictionary.data.length);
}

private void _empty_(string t)(GrCall call) {
    mixin("const " ~ t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    call.setBool(dictionary.data.length == 0);
}

private void _clear_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!" ~ t ~ "Dictionary(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    dictionary.data.clear();
    mixin("call.setForeign!" ~ t ~ "Dictionary(dictionary);");
}

private void _set_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
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
        call.raise("NullError");
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
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    call.setBool((call.getString(1) in dictionary.data) !is null);
}

private void _remove_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    dictionary.data.remove(call.getString(1));
}

private void _byKeys_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    GrStringArray ary = new GrStringArray;
    ary.data = dictionary.data.keys;
    call.setStringArray(ary);
}

private void _byValues_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    mixin("Gr" ~ t ~ "Array ary = new Gr" ~ t ~ "Array;");
    ary.data = dictionary.data.values;
    mixin("call.set" ~ t ~ "Array(ary);");
}

private void _printb_(string t)(GrCall call) {
    Dictionary dictionary = call.getForeign!(IntDictionary)(0);
    if (!dictionary) {
        call.raise("NullError");
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
        result ~= "\"" ~ key ~ "\"=>" ~ to!string(cast(GrBool) value);
    }
    result ~= "}";
    _stdOut(result);
}

private void _printlb_(string t)(GrCall call) {
    Dictionary dictionary = call.getForeign!(IntDictionary)(0);
    if (!dictionary) {
        call.raise("NullError");
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
        result ~= "\"" ~ key ~ "\"=>" ~ to!string(cast(GrBool) value);
    }
    result ~= "}\n";
    _stdOut(result);
}

private void _each_(string t)(GrCall call) {
    mixin(t ~ "Dictionary dictionary = call.getForeign!(" ~ t ~ "Dictionary)(0);");
    if (!dictionary) {
        call.raise("NullError");
        return;
    }
    static if (t == "Int") {
        DictionaryIter!(GrInt) iter = new DictionaryIter!(GrInt);
    }
    else static if (t == "Float") {
        DictionaryIter!(GrFloat) iter = new DictionaryIter!(GrFloat);
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
    else static if (t == "Float") {
        DictionaryIter!(GrFloat) iter = call.getForeign!(DictionaryIter!(GrFloat))(0);
    }
    else static if (t == "String") {
        DictionaryIter!(GrString) iter = call.getForeign!(DictionaryIter!(GrString))(0);
    }
    else static if (t == "Object") {
        DictionaryIter!(GrPtr) iter = call.getForeign!(DictionaryIter!(GrPtr))(0);
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
        IntDictionary dictionary = call.getForeign!(IntDictionary)(0);
    }
    else static if (t == "float") {
        FloatDictionary dictionary = call.getForeign!(FloatDictionary)(0);
    }
    else static if (t == "string") {
        StringDictionary dictionary = call.getForeign!(StringDictionary)(0);
    }
    if (!dictionary) {
        call.raise("NullError");
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
    result ~= newLine ? "}\n" : "}";
    _stdOut(result);
}
