/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.pretty;

import std.conv : to;
import grimoire.compiler.util, grimoire.compiler.type, grimoire.compiler.mangle;

/// Convert a type into a pretty format for display.
string grGetPrettyType(GrType variableType) {
    final switch (variableType.base) with (GrType.Base) {
    case void_:
        return "void";
    case null_:
        return "null";
    case integer:
        return "int";
    case real_:
        return "real";
    case boolean:
        return "bool";
    case string_:
        return "string";
    case array:
        string result = "array(";
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case channel:
        string result = "channel(";
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case enum_:
        return to!string(variableType.mangledType);
    case function_:
        string result = "function(";
        int i;
        auto inSignature = grUnmangleSignature(variableType.mangledType);
        foreach (type; inSignature) {
            result ~= grGetPrettyType(type);
            if ((i + 2) <= inSignature.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        auto outSignature = grUnmangleSignature(variableType.mangledReturnType);
        if (outSignature.length)
            result ~= " ";
        foreach (type; outSignature) {
            result ~= grGetPrettyType(type);
            if ((i + 2) <= outSignature.length)
                result ~= ", ";
            i++;
        }
        return result;
    case task:
        string result = "task(";
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
    case reference:
        string result = "ref(";
        int i;
        auto parameters = grUnmangleSignature(variableType.mangledType);
        foreach (parameter; parameters) {
            result ~= grGetPrettyType(parameter);
            if ((i + 2) <= parameters.length)
                result ~= ", ";
            i++;
        }
        result ~= ")";
        return result;
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
                result ~= grGetPrettyType(templateType);
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
            result ~= grGetPrettyType(parameter);
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
string grGetPrettyFunctionCall(string mangledName) {
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
        result ~= grGetPrettyType(type);
        if ((i + 2) <= inSignature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    return result;
}

/// Displayable format for a mangled string of format: function$signature \
/// Return signature is not used.
string grGetPrettyFunctionCall(string name, GrType[] signature) {
    string result = to!string(name) ~ "(";
    int i;
    foreach (type; signature) {
        result ~= grGetPrettyType(type);
        if ((i + 2) <= signature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    return result;
}

/// Prettify a function.
string grGetPrettyFunction(string name, GrType[] inSignature, GrType[] outSignature) {
    string result = to!string(name) ~ "(";
    int i;
    foreach (type; inSignature) {
        result ~= grGetPrettyType(type);
        if ((i + 2) <= inSignature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    if (outSignature.length)
        result ~= "(";
    foreach (type; outSignature) {
        result ~= grGetPrettyType(type);
        if ((i + 2) <= outSignature.length)
            result ~= ", ";
        i++;
    }
    if (outSignature.length)
        result ~= ")";
    return result;
}

/// Ditto
string grGetPrettyFunction(GrFunction func) {
    return grGetPrettyFunction(func.name, func.inSignature, func.outSignature);
}
