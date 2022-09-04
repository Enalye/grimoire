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
private final class HashMap {
    /// Payload
    GrValue[GrString] data;

    /// Ctor
    this(GrArray keys, GrArray values) {
        for (size_t i; i < keys.data.length; ++i) {
            data[keys.data[i].svalue] = values.data[i];
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
    Tuple!(GrString, GrValue)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibHashMap(GrLibrary library) {
    library.addForeign("HashMap", ["T"]);
    library.addForeign("HashMapIterator", ["T"]);

    GrType ValueType = grAny("T");
    GrType HashMapType = grGetForeignType("HashMap", [ValueType]);
    GrType pureHashMapType = grGetForeignType("HashMap", [ValueType], true);
    GrType PairType = grGetClassType("pair", [grString, ValueType]);
    GrType ArrayType = grArray(ValueType);
    GrType IteratorType = grGetForeignType("HashMapIterator", [ValueType]);

    library.addConstructor(&_new, HashMapType, []);
    library.addConstructor(&_newByArray, HashMapType, [grStringArray, ArrayType]);
    library.addConstructor(&_newByPairs, HashMapType, [PairType]);
    library.addFunction(&_copy, "copy", [HashMapType], [HashMapType]);
    library.addFunction(&_size, "size", [pureHashMapType], [grInt]);
    library.addFunction(&_empty, "empty?", [pureHashMapType], [grBool]);
    library.addFunction(&_clear, "clear", [HashMapType], [HashMapType]);
    library.addFunction(&_set, "set", [HashMapType, grString, ValueType]);
    library.addFunction(&_get, "get", [pureHashMapType, grString], [
            grBool, ValueType
        ]);
    library.addFunction(&_has, "has?", [pureHashMapType, grString], [grBool]);
    library.addFunction(&_remove, "remove", [HashMapType, grString]);
    library.addFunction(&_byKeys, "keys", [HashMapType], [grStringArray]);
    library.addFunction(&_byValues, "values", [HashMapType], [ArrayType]);
    library.addFunction(&_each, "each", [HashMapType], [IteratorType]);
    library.addFunction(&_next, "next", [IteratorType], [grBool, PairType]);

    GrType boolHashMap = grGetForeignType("HashMap", [grBool]);
    library.addFunction(&_print_!"bool", "print", [boolHashMap]);

    GrType intHashMap = grGetForeignType("HashMap", [grInt]);
    library.addFunction(&_print_!"int", "print", [intHashMap]);

    GrType realHashMap = grGetForeignType("HashMap", [grReal]);
    library.addFunction(&_print_!"real", "print", [realHashMap]);

    GrType stringHashMap = grGetForeignType("HashMap", [grString]);
    library.addFunction(&_print_!"string", "print", [stringHashMap]);
}

private void _new(GrCall call) {
    HashMap hashmap = new HashMap;
    call.setForeign(hashmap);
}

private void _newByArray(GrCall call) {
    HashMap hashmap = new HashMap(call.getArray(0), call.getArray(1));
    call.setForeign(hashmap);
}

private void _newByPairs(GrCall call) {
    HashMap hashmap = new HashMap;
    GrArray pairs = call.getArray(0);
    for (size_t i; i < pairs.data.length; ++i) {
        GrObject pair = cast(GrObject) pairs.data[i].ovalue;
        hashmap.data[pair.getString("key")] = pair.getValue("value");
    }
    call.setForeign(hashmap);
}

private void _copy(GrCall call) {
    HashMap hashmap = call.getForeign!HashMap(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setForeign!HashMap(new HashMap(hashmap));
}

private void _size(GrCall call) {
    HashMap hashmap = call.getForeign!HashMap(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setInt(cast(GrInt) hashmap.data.length);
}

private void _empty(GrCall call) {
    const HashMap hashmap = call.getForeign!HashMap(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setBool(hashmap.data.length == 0);
}

private void _clear(GrCall call) {
    HashMap hashmap = call.getForeign!HashMap(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    hashmap.data.clear();
    call.setForeign!HashMap(hashmap);
}

private void _set(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    hashmap.data[call.getString(1)] = call.getValue(2);
}

private void _get(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    auto p = call.getString(1) in hashmap.data;
    call.setBool(p !is null);
    call.setValue(p ? *p : GrValue());
}

private void _has(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    call.setBool((call.getString(1) in hashmap.data) !is null);
}

private void _remove(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    hashmap.data.remove(call.getString(1));
}

private void _byKeys(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    GrArray ary = new GrArray;
    foreach (GrString key; hashmap.data.keys) {
        ary.data ~= GrValue(key);
    }
    call.setArray(ary);
}

private void _byValues(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    GrArray ary = new GrArray;
    ary.data = hashmap.data.values;
    call.setArray(ary);
}

private void _each(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    HashMapIterator iter = new HashMapIterator;
    foreach (pair; hashmap.data.byKeyValue()) {
        iter.pairs ~= tuple(pair.key, pair.value);
    }
    call.setForeign(iter);
}

private void _next(GrCall call) {
    HashMapIterator iter = call.getForeign!HashMapIterator(0);

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
    GrObject obj = new GrObject(["key", "value"]);
    obj.setString("key", iter.pairs[iter.index][0]);
    obj.setValue("value", iter.pairs[iter.index][1]);
    call.setObject(obj);
    iter.index++;
}

private void _print_(string T)(GrCall call) {
    HashMap hashmap = call.getForeign!HashMap(0);

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
        static if (T == "bool")
            result ~= to!string(cast(GrBool) value.ivalue);
        else static if (T == "int")
            result ~= to!string(value.ivalue);
        else static if (T == "real")
            result ~= to!string(value.rvalue);
        else static if (T == "string")
            result ~= "\"" ~ value.svalue ~ "\"";
        else
            static assert(false);
    }
    result ~= "}";
    _stdOut(result);
}
