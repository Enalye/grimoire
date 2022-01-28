/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.mangle;

import std.conv : to;
import std.string : indexOf;
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
string grMangleSignature(GrType[] signature) {
    string mangledName;
    foreach (type; signature) {
        mangledName ~= grMangle(type);
    }
    return mangledName;
}

/// Reverse the mangling operation for a signature.
GrType[] grUnmangleSignature(string mangledSignature) {
    GrType[] unmangledSignature;

    int i;
    while (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$') {
            throw new Exception("Invalid unmangle signature mangling format, missing $");
        }
        i++;

        //Value
        GrType currentType = GrType.Base.void_;
        switch (mangledSignature[i]) {
        case '*':
            currentType.base = GrType.Base.void_;
            break;
        case 'i':
            currentType.base = GrType.Base.integer;
            break;
        case 'r':
            currentType.base = GrType.Base.real_;
            break;
        case 'b':
            currentType.base = GrType.Base.boolean;
            break;
        case 's':
            currentType.base = GrType.Base.string_;
            break;
        case 'n':
            i++;
            currentType.base = GrType.Base.array;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'e':
            currentType.base = GrType.Base.enum_;
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
            currentType.base = GrType.Base.class_;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'u':
            currentType.base = GrType.Base.foreign;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("Invalid mangling format");
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'f':
            i++;
            currentType.base = GrType.Base.function_;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            currentType.mangledReturnType = grUnmangleBlock(mangledSignature, i);
            break;
        case 't':
            i++;
            currentType.base = GrType.Base.task;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'c':
            i++;
            currentType.base = GrType.Base.channel;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
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
    Can be used to mangle a named function or a templated type.

    Example:
    ---
    func test(int i, string s, func(bool, float)) float {}
    ---
    Will be mangled as `test$i$s$f($b$f)()`

    The return type is not conserved in the mangled form as its not part of its signature.
    But function. passed as parameters have theirs.
*/
string grMangleComposite(string name, GrType[] signature) {
    return name ~ grMangleSignature(signature);
}

/// Reverses the grMangleComposite operation.
/// Returns a struct containing the name and the signature.
auto grUnmangleComposite(string mangledSignature) {
    struct UnmangleCompositeResult {
        string name;
        GrType[] signature;
    }

    UnmangleCompositeResult result;
    size_t index = mangledSignature.indexOf('$');
    if (index == -1) {
        result.name = mangledSignature;
        return result;
    }
    result.name = mangledSignature[0 .. index];
    result.signature = grUnmangleSignature(mangledSignature[index .. $]);
    return result;
}

/// Reverse the mangling operation for a function passed as a parameter.
string grUnmangleBlock(string mangledSignature, ref int i) {
    string subString;
    int blockCount = 1;
    if (i >= mangledSignature.length || mangledSignature[i] != '(')
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

/// Mangling operation for a single type.
string grMangle(GrType type) {
    string mangledName = "$";
    final switch (type.base) with (GrType.Base) {
    case void_:
        mangledName ~= "*";
        break;
    case null_:
        mangledName ~= "0";
        break;
    case integer:
        mangledName ~= "i";
        break;
    case real_:
        mangledName ~= "r";
        break;
    case boolean:
        mangledName ~= "b";
        break;
    case string_:
        mangledName ~= "s";
        break;
    case array:
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
    case channel:
        mangledName ~= "c(" ~ type.mangledType ~ ")";
        break;
    case reference:
        mangledName ~= "h(" ~ type.mangledType ~ ")";
        break;
    case internalTuple:
        throw new Exception("Trying to mangle a tuple. Tuples should not exist here.");
    }
    return mangledName;
}

/// Reverse the mangling operation for a single type.
GrType grUnmangle(string mangledSignature) {
    GrType currentType = GrType.Base.void_;

    int i;
    if (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$')
            throw new Exception("Invalid unmangle mangling format, missing $");
        i++;

        //Value
        switch (mangledSignature[i]) {
        case '*':
            currentType.base = GrType.Base.void_;
            break;
        case 'i':
            currentType.base = GrType.Base.integer;
            break;
        case 'r':
            currentType.base = GrType.Base.real_;
            break;
        case 'b':
            currentType.base = GrType.Base.boolean;
            break;
        case 's':
            currentType.base = GrType.Base.string_;
            break;
        case 'n':
            i++;
            currentType.base = GrType.Base.array;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'e':
            currentType.base = GrType.Base.enum_;
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
            currentType.base = GrType.Base.class_;
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
            currentType.base = GrType.Base.foreign;
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
            currentType.base = GrType.Base.function_;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            currentType.mangledReturnType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 't':
            i++;
            currentType.base = GrType.Base.task;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'c':
            i++;
            currentType.base = GrType.Base.channel;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        default:
            break;
        }
    }

    return currentType;
}
