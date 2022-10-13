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
string grMangleSignature(const GrType[] signature) {
    string mangledName;
    foreach (type; signature) {
        mangledName ~= grMangle(type);
    }
    return mangledName;
}

/// Reverse the mangling operation for a signature.
GrType[] grUnmangleSignature(const string mangledSignature) {
    GrType[] unmangledSignature;
    int i;
    while (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$') {
            throw new Exception("invalid unmangle signature mangling format, missing $");
        }
        i++;

        //Value
        GrType currentType = GrType.Base.void_;

        if (mangledSignature[i] == '@') {
            currentType.isPure = true;
            i++;
        }
        if (mangledSignature[i] == '#') {
            currentType.isConst = true;
            i++;
        }

        switch (mangledSignature[i]) {
        case '*':
            currentType.base = GrType.Base.void_;
            break;
        case 'a':
            i++;
            currentType.base = GrType.Base.void_;
            currentType.isAny = true;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'i':
            currentType.base = GrType.Base.int_;
            break;
        case 'r':
            currentType.base = GrType.Base.real_;
            break;
        case 'b':
            currentType.base = GrType.Base.bool_;
            break;
        case 's':
            currentType.base = GrType.Base.string_;
            break;
        case '?':
            i++;
            currentType.base = GrType.Base.optional;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'n':
            i++;
            currentType.base = GrType.Base.list;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'e':
            i++;
            currentType.base = GrType.Base.enum_;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'p':
            currentType.base = GrType.Base.class_;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("invalid mangling format");
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'u':
            currentType.base = GrType.Base.foreign;
            if ((i + 2) >= mangledSignature.length)
                throw new Exception("invalid mangling format");
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
string grMangleComposite(string name, const GrType[] signature) {
    return name ~ grMangleSignature(signature);
}

/// Reverses the grMangleComposite operation.
/// Returns a struct containing the name and the signature.
auto grUnmangleComposite(const string mangledSignature) {
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
string grUnmangleBlock(const string mangledSignature, ref int i) {
    string subString;
    int blockCount = 1;
    if (i >= mangledSignature.length || mangledSignature[i] != '(')
        throw new Exception("invalid subType mangling format, missing (");
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
    throw new Exception("invalid subType mangling format, missing )");
}

/// Mangling operation for a single type.
string grMangle(const GrType type) {
    string mangledName = "$";
    if (type.isAny) {
        mangledName ~= "a(" ~ type.mangledType ~ ")";
        return mangledName;
    }

    if (type.isPure) {
        mangledName ~= '@';
    }
    if (type.isConst) {
        mangledName ~= '#';
    }

    final switch (type.base) with (GrType.Base) {
    case void_:
        mangledName ~= "*";
        break;
    case null_:
        mangledName ~= "0";
        break;
    case int_:
        mangledName ~= "i";
        break;
    case real_:
        mangledName ~= "r";
        break;
    case bool_:
        mangledName ~= "b";
        break;
    case string_:
        mangledName ~= "s";
        break;
    case optional:
        mangledName ~= "?(" ~ type.mangledType ~ ")";
        break;
    case list:
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
        assert(false, "trying to mangle a tuple which should not exist here");
    }
    return mangledName;
}

/// Reverse the mangling operation for a single type.
GrType grUnmangle(const string mangledSignature) {
    GrType currentType = GrType.Base.void_;

    int i;
    if (i < mangledSignature.length) {
        //Type separator
        if (mangledSignature[i] != '$')
            throw new Exception("invalid unmangle mangling format, missing $");
        i++;

        if (mangledSignature[i] == '@') {
            currentType.isPure = true;
            i++;
        }
        if (mangledSignature[i] == '#') {
            currentType.isConst = true;
            i++;
        }

        //Value
        switch (mangledSignature[i]) {
        case '*':
            currentType.base = GrType.Base.void_;
            break;
        case 'a':
            currentType.base = GrType.Base.void_;
            currentType.isAny = true;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'i':
            currentType.base = GrType.Base.int_;
            break;
        case 'r':
            currentType.base = GrType.Base.real_;
            break;
        case 'b':
            currentType.base = GrType.Base.bool_;
            break;
        case 's':
            currentType.base = GrType.Base.string_;
            break;
        case '?':
            i++;
            currentType.base = GrType.Base.optional;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'n':
            i++;
            currentType.base = GrType.Base.list;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'e':
            currentType.base = GrType.Base.enum_;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'p':
            currentType.base = GrType.Base.class_;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'u':
            currentType.base = GrType.Base.foreign;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
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
