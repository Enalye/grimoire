/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.pretty;

import std.conv : to;
import grimoire.compiler.util, grimoire.compiler.type, grimoire.compiler.mangle;

/// Convert a type into a pretty format for display.
string grGetPrettyType(const GrType variableType) {
    string result;

    if (variableType.isPure) {
        result ~= "pure ";
    }
    if (variableType.isConst) {
        result ~= "const ";
    }

    if (variableType.isAny) {
        result ~= variableType.mangledType;
    }
    else {
        final switch (variableType.base) with (GrType.Base) {
        case void_:
            result ~= "void";
            break;
        case null_:
            result ~= "null";
            break;
        case int_:
            result ~= "int";
            break;
        case float_:
            result ~= "float";
            break;
        case bool_:
            result ~= "bool";
            break;
        case string_:
            result ~= "string";
            break;
        case optional:
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= "?";
            break;
        case list:
            result ~= "list(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        case channel:
            result ~= "channel(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        case enum_:
            result ~= to!string(variableType.mangledType);
            break;
        case func:
            result ~= "func(";
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
                result ~= " (";
            foreach (type; outSignature) {
                result ~= grGetPrettyType(type);
                if ((i + 2) <= outSignature.length)
                    result ~= ", ";
                i++;
            }
            if (outSignature.length)
                result ~= ")";
            break;
        case task:
            result ~= "task(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        case event:
            result ~= "event(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        case reference:
            result ~= "ref(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        case native:
        case class_:
            import std.algorithm.searching : findSplitBefore;

            const mangledTuple = findSplitBefore(variableType.mangledType, "$");
            result ~= mangledTuple[0];
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
            break;
        case internalTuple:
            result ~= "(";
            int i;
            auto parameters = grUnmangleSignature(variableType.mangledType);
            foreach (parameter; parameters) {
                result ~= grGetPrettyType(parameter);
                if ((i + 2) <= parameters.length)
                    result ~= ", ";
                i++;
            }
            result ~= ")";
            break;
        }
    }

    return result;
}

/// Displayable format for a mangled string of format: function$signature \
/// Return signature is not used.
string grGetPrettyFunctionCall(const string mangledName) {
    import std.string : indexOf;

    int index = cast(int) indexOf(mangledName, '$');
    assert(index != 0 && mangledName.length,
        "Invalid mangling format, named function have no name.");

    if (index < 0)
        return to!string(mangledName) ~ "()";

    string result;
    const string name = mangledName[0 .. index];
    auto inSignature = grUnmangleSignature(mangledName[index .. $]);

    if (name == "@new") {
        result = "new ";
        if (inSignature.length) {
            result ~= grGetPrettyType(inSignature[$ - 1]);
            inSignature.length--;
        }
        result ~= "(";
    }
    else {
        result = name ~ "(";
    }

    int i;
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
string grGetPrettyFunctionCall(const string name, const GrType[] inSignature) {
    string result;
    GrType[] signature = inSignature.dup;
    result = to!string(name) ~ "(";

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
string grGetPrettyFunction(const string name, const GrType[] inSignature, const GrType[] outSignature) {
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
string grGetPrettyFunction(const GrFunction func) {
    return grGetPrettyFunction(func.name, func.inSignature, func.outSignature);
}
