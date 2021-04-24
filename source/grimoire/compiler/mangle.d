/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.mangle;

import std.conv : to;
import grimoire.compiler.type;

/**
    Mangle a signature of types.

    Example:
    ---
    [int, string, func(bool, float)]
    ---
    Will be mangled as `$i$s$f($b$f)()`

    The return type is not conserved in the mangled form as its not part of its signature.
    But function. passed as parameters have theirs.
*/
string grMangleFunction(GrType[] signature) {
    string mangledName;
    foreach (type; signature) {
        mangledName ~= "$";
        final switch (type.baseType) with (GrBaseType) {
        case void_:
            mangledName ~= "*";
            break;
        case null_:
            mangledName ~= "0";
            break;
        case int_:
            mangledName ~= "i";
            break;
        case float_:
            mangledName ~= "r";
            break;
        case bool_:
            mangledName ~= "b";
            break;
        case string_:
            mangledName ~= "s";
            break;
        case array_:
            mangledName ~= "n(" ~ type.mangledType ~ ")";
            break;
        case class_:
            mangledName ~= "p(" ~ type.mangledType ~ ")";
            break;
        case enum_:
            mangledName ~= "e(" ~ type.mangledType ~ ")";
            break;
        case foreign:
            mangledName ~= "u(" ~ type.mangledType ~ ")";
            break;
        case function_:
            mangledName ~= "f(" ~ type.mangledType ~ ")(" ~ type.mangledReturnType ~ ")";
            break;
        case task:
            mangledName ~= "t(" ~ type.mangledType ~ ")";
            break;
        case chan:
            mangledName ~= "c(" ~ type.mangledType ~ ")";
            break;
        case reference:
            mangledName ~= "h(" ~ type.mangledType ~ ")";
            break;
        case internalTuple:
            throw new Exception("Trying to mangle a tuple. Tuples should not exist here.");
        }
    }
    return mangledName;
}

/**
    Mangle a named function.

    Example:
    ---
    func test(int i, string s, func(bool, float)) float {}
    ---
    Will be mangled as `test$i$s$f($b$f)()`

    The return type is not conserved in the mangled form as its not part of its signature.
    But function. passed as parameters have theirs.
*/
string grMangleNamedFunction(string name, GrType[] signature) {
    return name ~ grMangleFunction(signature);
}

/**
    Get the type of the function.
*/
GrType grGetFunctionAsType(GrFunction func) {
    GrType type = func.isTask ? GrBaseType.task : GrBaseType.function_;
    type.mangledType = grMangleNamedFunction("", func.inSignature);
    type.mangledReturnType = grMangleNamedFunction("", func.outSignature);
    return type;
}

/**
    Reverse the mangling operation for a function passed as a parameter.
*/
string grUnmangleSubFunction(string mangledSignature, ref int i) {
    string subString;
    int blockCount = 1;
    if (i >= mangledSignature.length && mangledSignature[i] != '(')
        throw new Exception("Invalid subType mangling format, missing (");
    i++;

    for (; i < mangledSignature.length; i++) {
        switch (mangledSignature[i]) {
        case '(':
            blockCount++;
            break;
        case ')':
            blockCount--;
            if (blockCount == 0) {
                return subString;
            }
            break;
        default:
            break;
        }
        subString ~= mangledSignature[i];
    }
    throw new Exception("Invalid subType mangling format, missing )");
}

/**
    Reverse the mangling operation for a single type.
*/
GrType grUnmangle(string mangledSignature) {
    GrType currentType = GrBaseType.void_;

    int i;
    if (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$')
            throw new Exception("Invalid unmangle mangling format, missing $");
        i++;

        //Value
        switch (mangledSignature[i]) {
        case '*':
            currentType.baseType = GrBaseType.void_;
            break;
        case 'i':
            currentType.baseType = GrBaseType.int_;
            break;
        case 'r':
            currentType.baseType = GrBaseType.float_;
            break;
        case 'b':
            currentType.baseType = GrBaseType.bool_;
            break;
        case 's':
            currentType.baseType = GrBaseType.string_;
            break;
        case 'n':
            i++;
            currentType.baseType = GrBaseType.array_;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            break;
        case 'e':
            currentType.baseType = GrBaseType.enum_;
            string enumName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid unmangle mangling format in struct");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid unmangle mangling format in struct");
            i++;
            while (mangledSignature[i] != ')') {
                enumName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid unmangle mangling format in struct");
            }
            currentType.mangledType = enumName;
            break;
        case 'p':
            currentType.baseType = GrBaseType.class_;
            string structName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid unmangle mangling format in struct");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid unmangle mangling format in struct");
            i++;
            while (mangledSignature[i] != ')') {
                structName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid unmangle mangling format in struct");
            }
            currentType.mangledType = structName;
            break;
        case 'u':
            currentType.baseType = GrBaseType.foreign;
            string foreignName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid unmangle mangling format in foreign");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid unmangle mangling format in foreign");
            i++;
            while (mangledSignature[i] != ')') {
                foreignName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid unmangle mangling format in foreign");
            }
            currentType.mangledType = foreignName;
            break;
        case 'f':
            i++;
            currentType.baseType = GrBaseType.function_;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            currentType.mangledReturnType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            break;
        case 't':
            i++;
            currentType.baseType = GrBaseType.task;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            break;
        case 'c':
            i++;
            currentType.baseType = GrBaseType.chan;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            break;
        default:
            break;
        }
    }

    return currentType;
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

/// Prettify a function class.
string grGetPrettyFunction(GrFunction func) {
    string result = to!string(func.name) ~ "(";
    int i;
    foreach (type; func.inSignature) {
        result ~= grGetPrettyType(type);
        if ((i + 2) <= func.inSignature.length)
            result ~= ", ";
        i++;
    }
    result ~= ")";
    if (func.outSignature.length)
        result ~= " ";
    foreach (type; func.outSignature) {
        result ~= grGetPrettyType(type);
        if ((i + 2) <= func.outSignature.length)
            result ~= ", ";
        i++;
    }
    return result;
}

/**
    Reverse the mangling operation for a function signature (not named).
*/
GrType[] grUnmangleSignature(string mangledSignature) {
    GrType[] unmangledSignature;

    int i;
    while (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$')
            throw new Exception("Invalid unmangle signature mangling format, missing $");
        i++;

        //Value
        GrType currentType = GrBaseType.void_;
        switch (mangledSignature[i]) {
        case '*':
            currentType.baseType = GrBaseType.void_;
            break;
        case 'i':
            currentType.baseType = GrBaseType.int_;
            break;
        case 'r':
            currentType.baseType = GrBaseType.float_;
            break;
        case 'b':
            currentType.baseType = GrBaseType.bool_;
            break;
        case 's':
            currentType.baseType = GrBaseType.string_;
            break;
        case 'n':
            i++;
            currentType.baseType = GrBaseType.array_;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            break;
        case 'e':
            currentType.baseType = GrBaseType.enum_;
            string enumName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid mangling format");
            i++;
            while (mangledSignature[i] != ')') {
                enumName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid mangling format");
            }
            currentType.mangledType = enumName;
            break;
        case 'p':
            currentType.baseType = GrBaseType.class_;
            string structName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid mangling format");
            i++;
            while (mangledSignature[i] != ')') {
                structName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid mangling format");
            }
            currentType.mangledType = structName;
            break;
        case 'u':
            currentType.baseType = GrBaseType.foreign;
            string foreignName;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i++;
            if (mangledSignature[i] != '(')
                throw new Exception("Invalid mangling format");
            i++;
            while (mangledSignature[i] != ')') {
                foreignName ~= mangledSignature[i];
                i++;
                if (i >= mangledSignature.length)
                    throw new Exception("Invalid mangling format");
            }
            currentType.mangledType = foreignName;
            break;
        case 'f':
            i++;
            currentType.baseType = GrBaseType.function_;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            i++;
            currentType.mangledReturnType = grUnmangleSubFunction(mangledSignature, i);
            break;
        case 't':
            i++;
            currentType.baseType = GrBaseType.task;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            break;
        case 'c':
            i++;
            currentType.baseType = GrBaseType.chan;
            currentType.mangledType = grUnmangleSubFunction(mangledSignature, i);
            break;
        default:
            break;
        }
        unmangledSignature ~= currentType;
        i++;
    }
    return unmangledSignature;
}

/**
    Convert a type into a pretty format for display.
*/
string grGetPrettyType(GrType variableType) {
    final switch (variableType.baseType) with (GrBaseType) {
    case void_:
        return "void";
    case null_:
        return "null";
    case int_:
        return "int";
    case float_:
        return "float";
    case bool_:
        return "bool";
    case string_:
        return "string";
    case array_:
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
    case function_:
        string result = "func(";
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
    case chan:
        string result = "chan(";
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
    case enum_:
    case foreign:
        return to!string(variableType.mangledType);
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
