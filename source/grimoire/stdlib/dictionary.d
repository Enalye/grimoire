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
    string _pairSymbol, _dicSymbol, _dicIterSymbol, _valueSymbol, _keySymbol;
}

/// Iterator
private final class DictionaryIter(T) {
    Tuple!(GrString, T)[] pairs;
    size_t index;
}

package(grimoire.stdlib) void grLoadStdLibDictionary(GrLibrary library, GrLocale locale) {
    string copySymbol, sizeSymbol, emptySymbol, clearSymbol, setSymbol, getSymbol, hasSymbol, removeSymbol;
    string byKeysSymbol, byValuesSymbol, eachSymbol, nextSymbol, printSymbol;
    final switch (locale) with (GrLocale) {
    case en_US:
        _pairSymbol = "Pair";
        _dicSymbol = "Dictionary";
        _dicIterSymbol = "IDictionary";
        _valueSymbol = "value";
        _keySymbol = "key";
        copySymbol = "copy";
        sizeSymbol = "size";
        emptySymbol = "empty?";
        clearSymbol = "clear";
        setSymbol = "set";
        getSymbol = "get";
        hasSymbol = "has?";
        removeSymbol = "remove";
        byKeysSymbol = "by_keys";
        byValuesSymbol = "by_values";
        eachSymbol = "each";
        nextSymbol = "next";
        printSymbol = "print";
        break;
    case fr_FR:
        _pairSymbol = "Paire";
        _dicSymbol = "Dictionnaire";
        _dicIterSymbol = "IDictionnaire";
        _valueSymbol = "valeur";
        _keySymbol = "clé";
        copySymbol = "copie";
        sizeSymbol = "taille";
        emptySymbol = "vide?";
        clearSymbol = "vide";
        setSymbol = "mets";
        getSymbol = "prends";
        hasSymbol = "a?";
        removeSymbol = "retire";
        byKeysSymbol = "par_clés";
        byValuesSymbol = "par_valeurs";
        eachSymbol = "chaque";
        nextSymbol = "suivant";
        printSymbol = "affiche";
        break;
    }

    library.addForeign(_dicSymbol, ["T"]);
    library.addForeign(_dicIterSymbol, ["T"]);

    static foreach (t; ["Int", "Real", "String", "Object"]) {
        mixin("GrType any" ~ t ~ "Dictionary = grAny(\"M\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != _dicSymbol)
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
                data.set(\"M\", grGetForeignType(_dicSymbol, [subType]));
                return grIsKindOf"
                ~ t ~ "(subType.base);
            });

            library.addPrimitive(&_make_!\""
                ~ t ~ "\", _dicSymbol, [grStringList, any" ~ t
                ~ "List], [grAny(\"M\")]);

            library.addPrimitive(&_makeByPairs_!\""
                ~ t ~ "\", _dicSymbol, [grAny(\"T\", (type, data) {
                if (type.base != GrType.Base.list_)
                    return false;
                const GrType subType = grUnmangle(type.mangledType);
                if(subType.base != GrType.Base.class_)
                    return false;
                auto pairType = grUnmangleComposite(subType.mangledType);
                if(pairType.name != _pairSymbol || pairType.signature.length != 2 || pairType.signature[0].base != GrType.Base.string_)
                    return false;
                data.set(\"M\", grGetForeignType(_dicSymbol, [pairType.signature[1]]));
                return true;
                })], [grAny(\"M\")]);

            library.addPrimitive(&_copy_!\""
                ~ t ~ "\", copySymbol, [any" ~ t ~ "Dictionary], [grAny(\"M\")]);

            library.addPrimitive(&_size_!\""
                ~ t ~ "\", sizeSymbol, [any"
                ~ t ~ "Dictionary], [grInt]);

            library.addPrimitive(&_empty_!\""
                ~ t ~ "\", emptySymbol, [
                any"
                ~ t ~ "Dictionary
            ], [grBool]);

            library.addPrimitive(&_clear_!\""
                ~ t ~ "\", clearSymbol, [
                any"
                ~ t ~ "Dictionary
            ], [grAny(\"M\")]);

            library.addPrimitive(&_set_!\""
                ~ t
                ~ "\", setSymbol, [any" ~ t ~ "Dictionary, grString, grAny(\"T\")]);

            library.addPrimitive(&_get_!\""
                ~ t
                ~ "\", getSymbol, [any" ~ t ~ "Dictionary, grString], [grBool, grAny(\"T\")]);

            library.addPrimitive(&_has_!\""
                ~ t ~ "\", hasSymbol, [any" ~ t ~ "Dictionary, grString], [grBool]);

            library.addPrimitive(&_remove_!\""
                ~ t
                ~ "\", removeSymbol, [any" ~ t ~ "Dictionary, grString]);

            library.addPrimitive(&_byKeys_!\""
                ~ t ~ "\", byKeysSymbol, [any" ~ t
                ~ "Dictionary], [grStringList]);

            library.addPrimitive(&_byValues_!\""
                ~ t ~ "\", byValuesSymbol, [any" ~ t ~ "Dictionary], [any"
                ~ t ~ "List]);

            library.addPrimitive(&_each_!\""
                ~ t ~ "\", eachSymbol, [
                    grAny(\"A\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto subType = grUnmangleComposite(type.mangledType);
                if(subType.name != _dicSymbol)
                    return false;
                if(subType.signature.length != 1)
                    return false;
                data.set(\"R\", grGetForeignType(_dicIterSymbol, subType.signature));
                return grIsKindOf"
                ~ t ~ "(subType.signature[0].base);
            })
                ], [grAny(\"R\")]);

            library.addPrimitive(&_next_!\""
                ~ t ~ "\", nextSymbol, [
                    grAny(\"R\", (type, data) {
                if (type.base != GrType.Base.foreign)
                    return false;
                auto result = grUnmangleComposite(type.mangledType);
                if(result.signature.length != 1 || result.name != _dicIterSymbol)
                    return false;
                data.set(\"T\", grGetClassType(_pairSymbol, [grString, result.signature[0]]));
                return grIsKindOf"
                ~ t ~ "(result.signature[0].base);
                    })
                ], [grBool, grAny(\"T\")]);
            ");
    }

    GrType boolDictionary = grGetForeignType(_dicSymbol, [grBool]);
    library.addPrimitive(&_print_!"bool", printSymbol, [boolDictionary]);

    GrType intDictionary = grGetForeignType(_dicSymbol, [grInt]);
    library.addPrimitive(&_print_!"int", printSymbol, [intDictionary]);

    GrType realDictionary = grGetForeignType(_dicSymbol, [grReal]);
    library.addPrimitive(&_print_!"real", printSymbol, [realDictionary]);

    GrType stringDictionary = grGetForeignType(_dicSymbol, [grString]);
    library.addPrimitive(&_print_!"string", printSymbol, [stringDictionary]);
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
            auto value = pair.getPtr(_valueSymbol);
        }
        else {
            mixin("auto value = pair.get" ~ t ~ "(_valueSymbol);");
        }
        dictionary.data[pair.getString(_keySymbol)] = value;
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
        GrObject obj = new GrObject([_keySymbol, _valueSymbol]);
        obj.setString(_keySymbol, iter.pairs[iter.index][0]);
        obj.setInt(_valueSymbol, iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Real") {
        GrObject obj = new GrObject([_keySymbol, _valueSymbol]);
        obj.setString(_keySymbol, iter.pairs[iter.index][0]);
        obj.setReal(_valueSymbol, iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "String") {
        GrObject obj = new GrObject([_keySymbol, _valueSymbol]);
        obj.setString(_keySymbol, iter.pairs[iter.index][0]);
        obj.setString(_valueSymbol, iter.pairs[iter.index][1]);
        call.setObject(obj);
    }
    else static if (t == "Object") {
        GrObject obj = new GrObject([_keySymbol, _valueSymbol]);
        obj.setString(_keySymbol, iter.pairs[iter.index][0]);
        obj.setPtr(_valueSymbol, iter.pairs[iter.index][1]);
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
