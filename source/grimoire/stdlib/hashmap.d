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
        for (size_t i; i < keys.length; ++i) {
            data[keys[i].getString()] = values[i];
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

    GrType valueType = grAny("T");
    GrType hashMapType = grGetForeignType("HashMap", [valueType]);
    GrType pureHashMapType = grGetForeignType("HashMap", [valueType], true);
    GrType pairType = grGetClassType("pair", [grString, valueType]);
    GrType arrayType = grArray(valueType);
    GrType iteratorType = grGetForeignType("HashMapIterator", [valueType]);

    library.addConstructor(&_new, hashMapType, []);
    library.addConstructor(&_newByArray, hashMapType, [grStringArray, arrayType]);
    library.addConstructor(&_newByPairs, hashMapType, [pairType]);
    library.addFunction(&_copy, "copy", [hashMapType], [hashMapType]);
    library.addFunction(&_size, "size", [pureHashMapType], [grInt]);
    library.addFunction(&_empty, "empty?", [pureHashMapType], [grBool]);
    library.addFunction(&_clear, "clear", [hashMapType], [hashMapType]);
    library.addFunction(&_set, "set", [hashMapType, grString, valueType]);
    library.addFunction(&_get, "get", [pureHashMapType, grString], [valueType]);
    library.addFunction(&_getOr, "getOr", [pureHashMapType, grString, valueType], [
            valueType
        ]);
    library.addFunction(&_has, "has?", [pureHashMapType, grString], [grBool]);
    library.addFunction(&_remove, "remove", [hashMapType, grString]);
    library.addFunction(&_byKeys, "keys", [hashMapType], [grStringArray]);
    library.addFunction(&_byValues, "values", [hashMapType], [arrayType]);
    library.addFunction(&_each, "each", [hashMapType], [iteratorType]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(pairType)]);

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
    for (size_t i; i < pairs.length; ++i) {
        GrObject pair = cast(GrObject) pairs[i].getPtr();
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
    if (p is null) {
        call.raise("KeyError");
        return;
    }
    call.setValue(*p);
}

private void _getOr(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    auto p = call.getString(1) in hashmap.data;
    call.setValue(p ? *p : call.getValue(2));
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
    GrArray ary;
    foreach (GrString key; hashmap.data.keys) {
        ary ~= GrValue(key);
    }
    call.setArray(ary);
}

private void _byValues(GrCall call) {
    HashMap hashmap = call.getForeign!(HashMap)(0);
    if (!hashmap) {
        call.raise("NullError");
        return;
    }
    GrArray ary;
    ary = hashmap.data.values;
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
        call.setNull();
        return;
    }
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
