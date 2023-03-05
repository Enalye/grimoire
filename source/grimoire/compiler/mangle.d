/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.mangle;

import std.exception : enforce;
import std.conv : to;
import std.string : indexOf;

import grimoire.compiler.type;

/**
Décore une signature de type.

Exemple:
---
[int, string, func(bool, float)]
---
Sera transformé en `$i$s$p($b$f)()`

Les types de retour ne sont pas conservé dans le forme décorée car ils ne font pas partie de la signature. \
En revanche, les fonctions passées en paramètres ont le leur.
*/
string grMangleSignature(const GrType[] signature) {
    string mangledName;
    foreach (type; signature) {
        mangledName ~= grMangle(type);
    }
    return mangledName;
}

/// Inverse l’opération de décoration pour une signature
GrType[] grUnmangleSignature(const string mangledSignature) {
    GrType[] unmangledSignature;
    int i;
    while (i < mangledSignature.length) {
        // Séparateur de type
        enforce(mangledSignature[i] == '$',
            "invalid unmangle signature mangling format, missing `$`");

        i++;

        // Valeur
        GrType currentType = GrType.Base.void_;

        if (mangledSignature[i] == '@') {
            currentType.isPure = true;
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
        case 'u':
            currentType.base = GrType.Base.uint_;
            break;
        case 'y':
            currentType.base = GrType.Base.byte_;
            break;
        case 'g':
            currentType.base = GrType.Base.char_;
            break;
        case 'f':
            currentType.base = GrType.Base.float_;
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
        case 'l':
            i++;
            currentType.base = GrType.Base.list;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'e':
            i++;
            currentType.base = GrType.Base.enum_;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'k':
            currentType.base = GrType.Base.class_;
            enforce((i + 2) < mangledSignature.length, "invalid mangling format");
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'n':
            currentType.base = GrType.Base.native;
            enforce((i + 2) < mangledSignature.length, "invalid mangling format");
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            break;
        case 'p':
            i++;
            currentType.base = GrType.Base.func;
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
Peut-être utilisé pour décorer une fonction nommée ou un type générique.

Exemple:
---
func test(int i, string s, func(bool, float)) (float) {}
---
Sera transformé en `test$i$s$p($b$f)()`

Les types de retour ne sont pas conservé dans la forme décorée car ils ne font pas partie de la signature. \
En revanche, les fonctions passées en paramètres ont le leur.
*/
string grMangleComposite(string name, const GrType[] signature) {
    return name ~ grMangleSignature(signature);
}

/// Inverse l’opération de `grMangleComposite`. \
/// Retourne une structure contenant le nom et la signature.
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

/// Inverse l’opération de décoration pour une fonction passé en paramètre.
string grUnmangleBlock(const string mangledSignature, ref int i) {
    string subString;
    int blockCount = 1;
    enforce(i < mangledSignature.length && mangledSignature[i] == '(',
        "invalid subType mangling format, missing `(`");
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
    throw new Exception("invalid subType mangling format, missing `)`");
}

/// Opération de décoration pour un simple type
string grMangle(const GrType type) {
    string mangledName = "$";

    if (type.isAny) {
        mangledName ~= "a(" ~ type.mangledType ~ ")";
        return mangledName;
    }

    if (type.isPure) {
        mangledName ~= '@';
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
    case uint_:
        mangledName ~= "u";
        break;
    case byte_:
        mangledName ~= "y";
        break;
    case char_:
        mangledName ~= "g";
        break;
    case float_:
        mangledName ~= "f";
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
        mangledName ~= "l(" ~ type.mangledType ~ ")";
        break;
    case class_:
        mangledName ~= "k(" ~ type.mangledType ~ ")";
        break;
    case enum_:
        mangledName ~= "e(" ~ type.mangledType ~ ")";
        break;
    case native:
        mangledName ~= "n(" ~ type.mangledType ~ ")";
        break;
    case func:
        mangledName ~= "p(" ~ type.mangledType ~ ")(" ~ type.mangledReturnType ~ ")";
        break;
    case task:
        mangledName ~= "t(" ~ type.mangledType ~ ")";
        break;
    case event:
        mangledName ~= "v(" ~ type.mangledType ~ ")";
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

/// Inverse l’opération de décoration pour un simple type
GrType grUnmangle(const string mangledSignature) {
    GrType currentType = GrType.Base.void_;

    int i;
    if (i < mangledSignature.length) {
        // Séparateur de type
        enforce(mangledSignature[i] == '$', "invalid unmangle mangling format, missing `$`");
        i++;

        if (mangledSignature[i] == '@') {
            currentType.isPure = true;
            i++;
        }

        // Valeur
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
        case 'u':
            currentType.base = GrType.Base.uint_;
            break;
        case 'y':
            currentType.base = GrType.Base.byte_;
            break;
        case 'g':
            currentType.base = GrType.Base.char_;
            break;
        case 'f':
            currentType.base = GrType.Base.float_;
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
        case 'l':
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
        case 'k':
            currentType.base = GrType.Base.class_;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'n':
            currentType.base = GrType.Base.native;
            i++;
            currentType.mangledType = grUnmangleBlock(mangledSignature, i);
            i++;
            break;
        case 'p':
            i++;
            currentType.base = GrType.Base.func;
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
