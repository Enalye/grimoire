module grimoire.compiler.util;

import std.algorithm;
import std.algorithm.comparison;
import std.traits;
import std.typetuple;

import grimoire.assembly;
import grimoire.compiler.lexer;
import grimoire.compiler.pretty;
import grimoire.compiler.primitive;
import grimoire.compiler.type;

/// Options de compilation
enum GrOption {
    /// Par défaut
    none = 0x0,
    /// Génère des symboles de débogage dans le bytecode
    symbols = 0x1,
    /// Ajoute des commandes de profilage dans le bytecode
    profile = 0x2,
    /// Change certaines instructions par des versions plus sécurisés
    safe = 0x4,
    /// Récupère des informations sur les définitions
    definitions = 0x8,
    /// Toutes les options
    all = symbols | profile | safe | definitions,
}

/// La langue du compilateur
enum GrLocale {
    en_US,
    fr_FR
}

/// Information sur la définition des symboles
final class GrDefinitionTable {
    struct Definition {
        enum Type {
            none,
            variable,
            function_,
            primitive,
            enum_,
        }

        union {
            GrVariable variable;
            GrFunction function_;
            GrPrimitive primitive;
            GrEnumDefinition enum_;
        }

        Type type;
        GrLexeme lexeme;
    }

    private {
        GrLexeme[] _lexemes;
        Definition[] _definitions;
        size_t[string] _filePaths;
    }

    package(grimoire) void addFile(size_t fileId, string path) {
        _filePaths[path] = fileId;
    }

    package(grimoire) void setLexemes(GrLexeme[] lexemes) {
        _lexemes = lexemes;
    }

    package(grimoire) void addDefinition(T)(GrLexeme lexeme, T value) {
        Definition def;
        def.type = Definition.Type.none;
        def.lexeme = lexeme;

        static if (is(T == GrVariable)) {
            def.type = Definition.Type.variable;
            def.variable = value;
        }
        else static if (is(T == GrFunction)) {
            def.type = Definition.Type.function_;
            def.function_ = value;
        }
        else static if (is(T == GrPrimitive)) {
            def.type = Definition.Type.primitive;
            def.primitive = value;
        }
        else static if (is(T == GrEnumDefinition)) {
            def.type = Definition.Type.enum_;
            def.enum_ = value;
        }

        _definitions ~= def;
    }

    /// Transforme le chemin en chemin natif du système
    private string _sanitizePath(string path) {
        import std.path : dirName, buildNormalizedPath, absolutePath;
        import std.regex : replaceAll, regex;
        import std.path : dirSeparator;

        path = replaceAll(path, regex(r"\\/|/|\\"), dirSeparator);
        path = buildNormalizedPath(path);

        return absolutePath(path);
    }

    Definition* getDefinitionAt(size_t fileId, size_t line, size_t column) {
        foreach (ref Definition def; _definitions) {
            if (def.lexeme.fileId != fileId || def.lexeme.line != line)
                continue;

            if (column >= def.lexeme.column && column < (def.lexeme.column + def.lexeme.textLength)) {
                return &def;
            }
        }
        return null;
    }

    struct DefinitionInfo {

    }

    void fetchDefinition(string path, size_t line, size_t column) {
        path = _sanitizePath(path);
        auto p = path in _filePaths;
        if (!p)
            return;

        const size_t fileId = *p;

        import std.stdio;

        Definition* def = getDefinitionAt(fileId, line, column);
        if (!def) {
            writeln("not found");
            return;
        }

        GrLexeme lex;
        string type;
        final switch (def.type) with (Definition.Type) {
        case none:
            lex = def.lexeme;
            break;
        case function_:
            lex = _lexemes[def.function_.nameLexPosition];
            type = grGetPrettyFunction(def.function_);
            break;
        case primitive:
            lex = def.lexeme;
            type = grGetPrettyFunction(def.primitive.name,
                def.primitive.inSignature, def.primitive.outSignature);
            break;
        case variable:
            if (def.variable.hasLexPosition)
                lex = _lexemes[def.variable.lexPosition];
            else
                lex = def.lexeme;
            type = grGetPrettyType(def.variable.type, true);
            break;
        case enum_:
            lex = def.lexeme;
            type = grGetPrettyType(grGetEnumType(def.enum_.name));
            break;
        }

        writeln(type);
    }
}

/// Recherche un texte qui ressemble à peu-près à la valeur de base
package string[] findNearestStrings(const string baseValue, const(string[]) ary, size_t distance = 0) {
    struct WeightedValue {
        size_t weight;
        string value;
    }

    WeightedValue[] weightedValues;
    foreach (string value; ary) {
        size_t weight = levenshteinDistance(baseValue, value);
        if (weight > distance && distance > 0)
            continue;
        weightedValues ~= WeightedValue(weight, value);
    }
    sort!((a, b) => (a.weight < b.weight))(weightedValues);
    string[] nearestStrings;
    foreach (WeightedValue weightedValue; weightedValues) {
        nearestStrings ~= weightedValue.value;
    }
    return nearestStrings;
}

/// Est-ce qu’on peut surcharger cet opérateur ?
bool isOverridableOperator(string op) {
    switch (op) {
    case "+":
    case "-":
    case "*":
    case "/":
    case "~":
    case "%":
    case "**":
    case "==":
    case "===":
    case "<=>":
    case "!=":
    case ">=":
    case ">":
    case "<=":
    case "<":
    case "<<":
    case ">>":
    case "->":
    case "=>":
    case "&":
    case "|":
    case "^":
    case "&&":
    case "||":
    case "!":
        return true;
    default:
        return false;
    }
}

/// Est-ce que l’opérateur est unaire ?
bool isOperatorUnary(string op) {
    switch (op) {
    case "+":
    case "-":
    case "!":
    case "~":
        return true;
    case "*":
    case "/":
    case "%":
    case "**":
    case "==":
    case "===":
    case "<=>":
    case "!=":
    case ">=":
    case ">":
    case "<=":
    case "<":
    case "<<":
    case ">>":
    case "->":
    case "=>":
    case "&":
    case "|":
    case "^":
    case "&&":
    case "||":
    default:
        return false;
    }
}

/// Est-ce que l’opérateur est binaire ?
bool isOperatorBinary(string op) {
    switch (op) {
    case "+":
    case "-":
    case "~":
    case "*":
    case "/":
    case "%":
    case "**":
    case "==":
    case "===":
    case "<=>":
    case "!=":
    case ">=":
    case ">":
    case "<=":
    case "<":
    case "<<":
    case ">>":
    case "->":
    case "=>":
    case "&":
    case "|":
    case "^":
    case "&&":
    case "||":
        return true;
    case "!":
    default:
        return false;
    }
}

struct GrNativeEnum {
    string[] fields;
    GrInt[] values;
}

/// Retourne les champs et les valeurs d’une énumération en D pour GrModule
GrNativeEnum grNativeEnum(T)() if (is(T == enum) && isIntegral!(OriginalType!T)) {
    GrNativeEnum loader;
    loader.fields = [__traits(allMembers, T)];
    loader.values = cast(GrInt[])[EnumMembers!(T)];
    return loader;
}
