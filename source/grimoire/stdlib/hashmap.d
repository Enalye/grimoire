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
import grimoire.stdlib.pair;

/// HashMap
private final class HashMap {
    /// Payload
    GrValue[GrStringValue] data;

    /// Ctor
    this(GrString[] keys, GrValue[] values) {
        for (size_t i; i < keys.length; ++i) {
            data[keys[i]] = values[i];
        }
    }
    /// Ditto
    this() {
    }

    this(HashMap hashmap) {
        data = hashmap.data.dup;
    }
}

/// Iterator
private final class HashMapIterator {
    Tuple!(GrStringValue, GrValue)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibHashMap(GrLibrary library) {
    GrType mapType = library.addNative("HashMap", ["T"]);
    GrType iteratorType = library.addNative("HashMapIterator", ["T"]);

    GrType pairType = grGetNativeType("Pair", [grString, grAny("T")]);

    library.addConstructor(&_new, mapType);
    library.addConstructor(&_newByList, mapType, [
            grPure(grList(grString)), grPure(grList(grAny("T")))
        ]);
    library.addConstructor(&_newByPairs, mapType, [grPure(grList(pairType))]);

    library.addFunction(&_copy, "copy", [grPure(mapType)], [mapType]);
    library.addFunction(&_size, "size", [grPure(mapType)], [grInt]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(mapType)], [grBool]);
    library.addFunction(&_clear, "clear", [mapType], [mapType]);
    library.addFunction(&_set, "set", [mapType, grPure(grString), grAny("T")]);
    library.addFunction(&_get, "get", [grPure(mapType), grString], [
            grOptional(grAny("T"))
        ]);
    library.addFunction(&_getOr, "getOr", [
            grPure(mapType), grString, grAny("T")
        ], [grAny("T")]);
    library.addFunction(&_contains, "contains", [grPure(mapType), grString], [
            grBool
        ]);
    library.addFunction(&_remove, "remove", [mapType, grPure(grString)]);
    library.addFunction(&_byKeys, "byKeys", [grPure(mapType)], [grList(grString)]);
    library.addFunction(&_byValues, "byValues", [grPure(mapType)], [grList(grAny("T"))]);
    library.addFunction(&_each, "each", [grPure(mapType)], [iteratorType]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(pairType)]);

    GrType boolHashMap = grGetNativeType("HashMap", [grBool]);
    library.addFunction(&_print_!"bool", "print", [grPure(boolHashMap)]);

    GrType intHashMap = grGetNativeType("HashMap", [grInt]);
    library.addFunction(&_print_!"int", "print", [grPure(intHashMap)]);

    GrType realHashMap = grGetNativeType("HashMap", [grReal]);
    library.addFunction(&_print_!"real", "print", [grPure(realHashMap)]);

    GrType stringHashMap = grGetNativeType("HashMap", [grString]);
    library.addFunction(&_print_!"string", "print", [grPure(stringHashMap)]);
}

private void _new(GrCall call) {
    HashMap hashmap = new HashMap;
    call.setNative(hashmap);
}

private void _newByList(GrCall call) {
    HashMap hashmap = new HashMap(call.getList(0).getStrings(), call.getList(1).getValues());
    call.setNative(hashmap);
}

private void _newByPairs(GrCall call) {
    HashMap hashmap = new HashMap;
    GrPair[] pairs = call.getList(0).getNatives!GrPair();
    for (size_t i; i < pairs.length; ++i) {
        hashmap.data[pairs[i].key.getString()] = pairs[i].value;
    }
    call.setNative(hashmap);
}

private void _copy(GrCall call) {
    HashMap hashmap = call.getNative!HashMap(0);
    call.setNative!HashMap(new HashMap(hashmap));
}

private void _size(GrCall call) {
    HashMap hashmap = call.getNative!HashMap(0);
    call.setInt(cast(GrInt) hashmap.data.length);
}

private void _isEmpty(GrCall call) {
    const HashMap hashmap = call.getNative!HashMap(0);
    call.setBool(hashmap.data.length == 0);
}

private void _clear(GrCall call) {
    HashMap hashmap = call.getNative!HashMap(0);
    hashmap.data.clear();
    call.setNative!HashMap(hashmap);
}

private void _set(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    hashmap.data[call.getString(1)] = call.getValue(2);
}

private void _get(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    auto p = call.getString(1) in hashmap.data;
    if (p is null) {
        call.setNull();
        return;
    }
    call.setValue(*p);
}

private void _getOr(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    auto p = call.getString(1) in hashmap.data;
    call.setValue(p ? *p : call.getValue(2));
}

private void _contains(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    call.setBool((call.getString(1) in hashmap.data) !is null);
}

private void _remove(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    hashmap.data.remove(call.getString(1));
}

private void _byKeys(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    GrValue[] ary;
    foreach (GrStringValue key; hashmap.data.keys) {
        ary ~= GrValue(key);
    }
    call.setList(ary);
}

private void _byValues(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    GrValue[] ary;
    ary = hashmap.data.values;
    call.setList(ary);
}

private void _each(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    HashMapIterator iter = new HashMapIterator;
    foreach (pair; hashmap.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setNative(iter);
}

private void _next(GrCall call) {
    HashMapIterator iter = call.getNative!HashMapIterator(0);

    if (iter.index >= iter.pairs.length) {
        call.setNull();
        return;
    }
    GrPair pair = new GrPair;
    pair.key = GrValue(iter.pairs[iter.index][0]);
    pair.value = iter.pairs[iter.index][1];
    call.setNative(pair);
    iter.index++;
}

private void _print_(string T)(GrCall call) {
    HashMap hashmap = call.getNative!HashMap(0);

    GrStringValue result = "{";
    bool isFirst = true;
    foreach (key, value; hashmap.data) {
        if (isFirst) {
            isFirst = false;
        }
        else {
            result ~= ", ";
        }
        result ~= "\"" ~ key ~ "\"=>";
        static if (T == "bool")
            result ~= to!string(value.getBool());
        else static if (T == "int")
            result ~= to!string(value.getInt());
        else static if (T == "real")
            result ~= to!string(value.getReal());
        else static if (T == "string")
            result ~= "\"" ~ value.getString() ~ "\"";
        else
            static assert(false);
    }
    result ~= "}";
    _stdOut(result);
}
