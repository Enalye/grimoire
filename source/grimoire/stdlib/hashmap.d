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
/+
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
private final class HashMapIterator(T) {
    Tuple!(GrString, T)[] pairs;
    size_t index;
}+/

package(grimoire.stdlib) void grLoadStdLibHashMap(GrLibrary library) {
    /+library.addForeign("HashMap", ["T"]);
    library.addForeign("HashMapIterator", ["T"]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("
            GrType " ~ t ~ "ValueType = grAny(\"T\");
            GrType " ~ t ~ "HashMapType = grGetForeignType(\"HashMap\", [" ~ t ~ "ValueType]);
            GrType pure" ~ t ~ "HashMapType = grGetForeignType(\"HashMap\", [" ~
                t ~ "ValueType], true);
            GrType " ~ t ~ "PairType = grGetClassType(\"pair\", [grString, " ~ t ~ "ValueType]);
            GrType " ~ t ~ "ArrayType = grArray(" ~ t ~ "ValueType);

            GrType " ~ t ~ "IteratorType = grGetForeignType(\"HashMapIterator\", [" ~
                t ~ "ValueType]);
            static if(t == \"Object\") {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", " ~ t ~ "ValueType,
                    [GrType(GrType.Base.null_)]);
            }
            else {
                GrConstraint " ~ t ~ "Constraint = grConstraint(\"Register\", " ~
                t ~ "ValueType, [gr" ~ t ~ "]);
            }

            library.addConstructor(&_new_!\"" ~ t ~ "\", " ~ t ~
                "HashMapType, [], [" ~ t ~ "Constraint]);

            library.addConstructor(&_newByArray_!\"" ~ t ~ "\", " ~ t ~
                "HashMapType, [grStringArray, " ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);

            library.addConstructor(&_newByPairs_!\"" ~ t ~ "\", " ~ t ~
                "HashMapType, [" ~ t ~ "PairType], [" ~ t ~ "Constraint]);

            library.addFunction(&_copy_!\"" ~ t ~ "\", \"copy\", [" ~ t ~
                "HashMapType], [" ~ t ~ "HashMapType], [" ~ t ~ "Constraint]);

            library.addFunction(&_size_!\"" ~ t ~ "\", \"size\", [pure" ~ t ~
                "HashMapType], [grInt], [" ~ t ~ "Constraint]);

            library.addFunction(&_empty_!\"" ~ t ~ "\", \"empty?\", [pure" ~ t ~
                "HashMapType], [grBool], [" ~ t ~ "Constraint]);

            library.addFunction(&_clear_!\"" ~ t ~ "\", \"clear\", [" ~ t ~ "HashMapType
            ], [" ~ t ~ "HashMapType], [" ~ t ~ "Constraint]);

            library.addFunction(&_set_!\"" ~ t ~ "\", \"set\", [" ~ t ~
                "HashMapType, grString, " ~ t ~ "ValueType], [], [" ~ t ~ "Constraint]);

            library.addFunction(&_get_!\"" ~ t ~ "\", \"get\", [pure" ~ t ~
                "HashMapType, grString], [grBool, " ~ t ~ "ValueType], [" ~ t ~ "Constraint]);

            library.addFunction(&_has_!\"" ~ t ~ "\", \"has?\", [pure" ~ t ~
                "HashMapType, grString], [grBool], [" ~ t ~ "Constraint]);

            library.addFunction(&_remove_!\"" ~ t ~ "\", \"remove\", [" ~ t ~
                "HashMapType, grString], [], [" ~ t ~ "Constraint]);

            library.addFunction(&_byKeys_!\"" ~ t ~ "\", \"keys\", [" ~ t ~
                "HashMapType], [grStringArray], [" ~ t ~ "Constraint]);

            library.addFunction(&_byValues_!\"" ~ t ~ "\", \"values\", [" ~ t ~
                "HashMapType], [" ~ t ~ "ArrayType], [" ~ t ~ "Constraint]);

            library.addFunction(&_each_!\"" ~ t ~ "\", \"each\", [" ~ t ~ "HashMapType
                ], [" ~ t ~ "IteratorType], [" ~ t ~ "Constraint]);

            library.addFunction(&_next_!\"" ~ t ~ "\", \"next\", [
                    " ~ t ~ "IteratorType
                ], [grBool, " ~ t ~ "PairType], [" ~ t ~ "Constraint]);
            ");
    }

    GrType boolHashMap = grGetForeignType("HashMap", [grBool]);
    library.addFunction(&_print_!"bool", "print", [boolHashMap]);

    GrType intHashMap = grGetForeignType("HashMap", [grInt]);
    library.addFunction(&_print_!"int", "print", [intHashMap]);

    GrType realHashMap = grGetForeignType("HashMap", [grReal]);
    library.addFunction(&_print_!"real", "print", [realHashMap]);

    GrType stringHashMap = grGetForeignType("HashMap", [grString]);
    library.addFunction(&_print_!"string", "print", [stringHashMap]);+/
}
/+
private void _new_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = new " ~ t ~ "HashMap;");
    call.setForeign(hashmap);
}

private void _newByArray_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = new " ~ t ~ "HashMap(call.getArray(0), call.getArray(1));");
    call.setForeign(hashmap);
}

private void _newByPairs_(string t)(GrCall call) {
    mixin(t ~ "HashMap hashmap = new " ~ t ~ "HashMap;");
    GrObjectArray pairs = call.getObjectArray(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i];
        static if (t == "Object") {
            auto value = pair.getPtr("value");
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(\"value\");");
        }
        hashmap.data[pair.getString("key")] = value;
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
        HashMapIterator!(GrInt) iter = new HashMapIterator!(GrInt);
    }
    else static if (t == "Real") {
        HashMapIterator!(GrReal) iter = new HashMapIterator!(GrReal);
    }
    else static if (t == "String") {
        HashMapIterator!(GrString) iter = new HashMapIterator!(GrString);
    }
    else static if (t == "Object") {
        HashMapIterator!(GrPtr) iter = new HashMapIterator!(GrPtr);
    }
    foreach (pair; hashmap.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next_(string t)(GrCall call) {
    static if (t == "Int") {
        HashMapIterator!(GrInt) iter = call.getForeign!(HashMapIterator!(GrInt))(0);
    }
    else static if (t == "Real") {
        HashMapIterator!(GrReal) iter = call.getForeign!(HashMapIterator!(GrReal))(0);
    }
    else static if (t == "String") {
        HashMapIterator!(GrString) iter = call.getForeign!(HashMapIterator!(GrString))(0);
    }
    else static if (t == "Object") {
        HashMapIterator!(GrPtr) iter = call.getForeign!(HashMapIterator!(GrPtr))(0);
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
+/