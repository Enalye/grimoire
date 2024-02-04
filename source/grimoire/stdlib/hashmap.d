/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
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
    GrValue[string] data;

    /// Ctor
    this(GrString[] keys, GrValue[] values) {
        for (size_t i; i < keys.length; ++i) {
            data[keys[i].str] = values[i];
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
    Tuple!(string, GrValue)[] pairs;
    size_t index;
}

void grLoadStdLibHashMap(GrLibDefinition library) {
    library.setModule("hashmap");

    library.setModuleInfo(GrLocale.fr_FR, "Dictionnaire associant des valeurs par clés.");
    library.setModuleInfo(GrLocale.en_US, "Dictionary that associates values by keys.");

    library.setDescription(GrLocale.fr_FR, "Dictionnaire associant des valeurs par clés.");
    library.setDescription(GrLocale.en_US, "Dictionary that associates values by keys.");
    GrType mapType = library.addNative("HashMap", ["T"]);

    library.setDescription(GrLocale.fr_FR, "Itère sur les éléments d’une hashmap.");
    library.setDescription(GrLocale.en_US, "Iterate on the elements of a hashmap.");
    GrType iteratorType = library.addNative("HashMapIterator", ["T"]);

    GrType pairType = grGetNativeType("Pair", [grString, grAny("T")]);

    library.addConstructor(&_new, mapType);
    library.addConstructor(&_newByList, mapType, [
            grPure(grList(grString)), grPure(grList(grAny("T")))
        ]);
    library.addConstructor(&_newByPairs, mapType, [grPure(grList(pairType))]);

    library.setDescription(GrLocale.fr_FR, "Returne une copie de la hashmap.");
    library.setDescription(GrLocale.fr_FR, "Returns a copy of the hashmap.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_copy, "copy", [grPure(mapType)], [mapType]);

    library.setDescription(GrLocale.fr_FR, "Returne le nombre d’élements dans la hashmap.");
    library.setDescription(GrLocale.en_US, "Returns the number of elements in the hashmap.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_size, "size", [grPure(mapType)], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la hashmap ne contient rien.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the hashmap contains nothing.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(mapType)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Vide la hashmap.");
    library.setDescription(GrLocale.en_US, "Clear the hashmap.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_clear, "clear", [mapType], [mapType]);

    library.setDescription(GrLocale.fr_FR,
        "Ajoute la nouvelle valeur à la clé correspondante dans la hashmap.");
    library.setDescription(GrLocale.en_US,
        "Add the new value to the corresponding key in the hashmap.");
    library.setParameters(["hashmap", "key", "value"]);
    library.addFunction(&_set, "set", [mapType, grPure(grString), grAny("T")]);

    library.setDescription(GrLocale.fr_FR,
        "Returne la valeur associée avec `key`.\nSi cette valeur n’existe pas, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US,
        "Return the value associated with `key`.\nIf the value doesn't exist, returns `null<T>`.");
    library.setParameters(["hashmap", "key"]);
    library.addFunction(&_get, "get", [grPure(mapType), grString], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Returne la valeur associée avec `key`.\nSi cette valeur n’existe pas, retourne `def`.");
    library.setDescription(GrLocale.en_US,
        "Return the value associated with `key`.\nIf the value doesn't exist, returns `def`.");
    library.setParameters(["hashmap", "key", "default"]);
    library.addFunction(&_getOr, "getOr", [
            grPure(mapType), grString, grAny("T")
        ], [grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la clé existe dans la hashmap.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the key exists inside the hashmap.");
    library.setParameters(["hashmap", "key"]);
    library.addFunction(&_contains, "contains", [grPure(mapType), grString], [
            grBool
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire l’entrée `key` de la hashmap.");
    library.setDescription(GrLocale.en_US, "Delete the entry `key` from the hashmap.");
    library.setParameters(["hashmap", "key"]);
    library.addFunction(&_remove, "remove", [mapType, grPure(grString)]);

    library.setDescription(GrLocale.fr_FR, "Returne la liste de toutes les clés.");
    library.setDescription(GrLocale.en_US, "Returns the list of all keys.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_byKeys, "byKeys", [grPure(mapType)], [
            grList(grString)
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne la liste de toutes les valeurs.");
    library.setDescription(GrLocale.en_US, "Returns the list of all values.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_byValues, "byValues", [grPure(mapType)], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Returne un itérateur permettant d’itérer sur chaque paire de clés/valeurs.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that iterate through each key/value pairs.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_each, "each", [grPure(mapType)], [iteratorType]);

    library.setDescription(GrLocale.fr_FR, "Avance l’itérateur à l’élément suivant.");
    library.setDescription(GrLocale.en_US, "Advance the iterator to the next element.");
    library.setParameters(["iterator"]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(pairType)]);

    GrType boolHashMap = grGetNativeType("HashMap", [grBool]);
    GrType intHashMap = grGetNativeType("HashMap", [grInt]);
    GrType floatHashMap = grGetNativeType("HashMap", [grFloat]);
    GrType stringHashMap = grGetNativeType("HashMap", [grString]);

    library.setDescription(GrLocale.fr_FR, "Affiche le contenu d’hashmap.");
    library.setDescription(GrLocale.en_US, "Display the content of hashmap.");
    library.setParameters(["hashmap"]);
    library.addFunction(&_print_!"bool", "print", [grPure(boolHashMap)]);
    library.addFunction(&_print_!"int", "print", [grPure(intHashMap)]);
    library.addFunction(&_print_!"float", "print", [grPure(floatHashMap)]);
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
        hashmap.data[pairs[i].key.getString().str] = pairs[i].value;
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
    hashmap.data[call.getString(1).str] = call.getValue(2);
}

private void _get(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    auto p = call.getString(1).str in hashmap.data;
    if (p is null) {
        call.setNull();
        return;
    }
    call.setValue(*p);
}

private void _getOr(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    auto p = call.getString(1).str in hashmap.data;
    call.setValue(p ? *p : call.getValue(2));
}

private void _contains(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    call.setBool((call.getString(1).str in hashmap.data) !is null);
}

private void _remove(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    hashmap.data.remove(call.getString(1).str);
}

private void _byKeys(GrCall call) {
    HashMap hashmap = call.getNative!(HashMap)(0);
    GrValue[] ary;
    foreach (string key; hashmap.data.keys) {
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

    string result = "{";
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
        else static if (T == "float")
            result ~= to!string(value.getFloat());
        else static if (T == "string")
            result ~= "\"" ~ value.getString().str ~ "\"";
        else
            static assert(false);
    }
    result ~= "}";
    grPrint(result);
}
