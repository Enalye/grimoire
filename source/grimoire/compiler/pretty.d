/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.pretty;

import std.conv : to;
import grimoire.compiler.util, grimoire.compiler.type, grimoire.compiler.mangle;

/// Convert a type into a pretty format for display.
string grGetPrettyType(GrType variableType, GrLocale locale = GrLocale.en_US) {
    final switch (variableType.base) with (GrType.Base) {
    case void_:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "void";
        case fr_FR:
            return "vide";
        }
    case null_:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "null";
        case fr_FR:
            return "nul";
        }
    case integer:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "integer";
        case fr_FR:
            return "entier";
        }
    case real_:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "real";
        case fr_FR:
            return "réel";
        }
    case boolean:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "boolean";
        case fr_FR:
            return "booléen";
        }
    case string_:
        final switch (locale) with (GrLocale) {
        case en_US:
            return "string";
        case fr_FR:
            return "chaîne";
        }
    case list_:
        string result;
        final switch (locale) with (GrLocale) {
        case en_US:
            result = "list(";
            break;
        case fr_FR:
            result = "liste(";
            break;
        }
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter, locale);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case function_:
        string result;
        final switch (locale) with (GrLocale) {
        case en_US:
            result = "function(";
            break;
        case fr_FR:
            result = "fonction(";
            break;
        }
        int i;
        auto inSignature = grUnmangleSignature(variableType.mangledType);
        foreach (type; inSignature) {
            result ~= grGetPrettyType(type, locale);
            if ((i + 2) <= inSignature.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        auto outSignature = grUnmangleSignature(variableType.mangledReturnType);
        if (outSignature.length)
            result ~= " ";
        foreach (type; outSignature) {
            result ~= grGetPrettyType(type, locale);
            if ((i + 2) <= outSignature.length)
                result ~= ", ";
            i++;
        }
        return result;
    case channel:
        string result;
        final switch (locale) with (GrLocale) {
        case en_US:
            result = "channel(";
            break;
        case fr_FR:
            result = "canal(";
            break;
        }
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter, locale);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case reference:
        string result;
        final switch (locale) with (GrLocale) {
        case en_US:
            result = "ref(";
            break;
        case fr_FR:
            result = "réf(";
            break;
        }
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter, locale);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case task:
        string result;
        final switch (locale) with (GrLocale) {
        case en_US:
            result = "task(";
            break;
        case fr_FR:
            result = "tâche(";
            break;
        }
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter, locale);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case enumeration:
        return to!string(variableType.mangledType);
    case foreign:
    case class_:
        import std.algorithm.searching : findSplitBefore;

        const mangledTuple = findSplitBefore(variableType.mangledType, "$");
        string result = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        if (templateTypes.length) {
            result ~= "<";
            int i;
            foreach (templateType; templateTypes) {
                result ~= grGetPrettyType(templateType, locale);
                if ((i + 2) <= templateTypes.length)
                    result ~= ", ";
                i++;
            }
            result ~= ">";
        }
        return result;
    case internalTuple:
        string result = "(";
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter, locale);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    }
}

/// Displayable format for a mangled string of format: function$signature \
/// Return signature is not used.
string grGetPrettyFunctionCall(string mangledName, GrLocale locale = GrLocale.en_US) {
    import std.string : indexOf;

    int index = cast(int) indexOf(mangledName, '$');
    assert(index != 0 && mangledName.length,
        "Invalid mangling format, named function have no name.");

    if (index < 0)
        return to!string(mangledName) ~ "()";

    string name = mangledName[0 .. index];
    mangledName = mangledName[index .. $];

    string result = to!string(name) ~ "(";
    int i;
    auto inSignature = grUnmangleSignature(mangledName);
    foreach (type; inSignature) {
        result ~= grGetPrettyType(type, locale);
        if ((i + 2) <= inSignature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    return result;
}

/// Displayable format for a mangled string of format: function$signature \
/// Return signature is not used.
string grGetPrettyFunctionCall(string name, GrType[] signature, GrLocale locale = GrLocale.en_US) {
    string result = to!string(name) ~ "(";
    int i;
    foreach (type; signature) {
        result ~= grGetPrettyType(type, locale);
        if ((i + 2) <= signature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    return result;
}

/// Prettify a function.
string grGetPrettyFunction(string name, GrType[] inSignature, GrType[] outSignature, GrLocale locale = GrLocale
        .en_US) {
    string result = to!string(name) ~ "(";
    int i;
    foreach (type; inSignature) {
        result ~= grGetPrettyType(type, locale);
        if ((i + 2) <= inSignature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    if (outSignature.length)
        result ~= "(";
    foreach (type; outSignature) {
        result ~= grGetPrettyType(type, locale);
        if ((i + 2) <= outSignature.length)
            result ~= ", ";
        i++;
    }
    if (outSignature.length)
        result ~= ")";
    return result;
}

/// Ditto
string grGetPrettyFunction(GrFunction func, GrLocale locale = GrLocale.en_US) {
    return grGetPrettyFunction(func.name, func.inSignature, func.outSignature, locale);
}
