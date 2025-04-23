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

struct GrDefinition {
    private {
        enum Type {
            none,
            variable,
            function_,
            primitive,
            enum_,
        }

        union {
            GrVariable _variable;
            GrFunction _function;
            GrPrimitive _primitive;
            GrEnumDefinition _enum;
        }

        Type _type;
        GrLexeme _lexeme;
        GrDefinitionTable _table;
    }

    string getName() {
        final switch (_type) with (GrDefinition.Type) {
        case none:
            return "";
        case function_:
            return grGetPrettyFunction(_function);
        case primitive:
            return grGetPrettyFunction(_primitive.name, _primitive.inSignature,
                _primitive.outSignature);
        case variable:
            return (_variable.isConst ? "const " : "var ") ~
                _variable.name ~ ": " ~
                grGetPrettyType(_variable.type, true);
        case enum_:
            return "enum " ~ grGetPrettyType(grGetEnumType(_enum.name));
        }
    }

    GrLexeme getDeclaration() {
        final switch (_type) with (GrDefinition.Type) {
        case none:
            return _lexeme;
        case function_:
            return _table._lexemes[_function.nameLexPosition];
        case primitive:
            return _lexeme;
        case variable:
            if (_variable.hasLexPosition)
                return _table._lexemes[_variable.lexPosition];
            return _lexeme;
        case enum_:
            return _lexeme;
        }
    }
}

/// Information sur la définition des symboles
final class GrDefinitionTable {
    private {
        GrLexeme[] _lexemes;
        GrDefinition[] _definitions;
        size_t[string] _filePaths;
    }

    package(grimoire) void addFile(size_t fileId, string path) {
        _filePaths[path] = fileId;
    }

    package(grimoire) void setLexemes(GrLexeme[] lexemes) {
        _lexemes = lexemes;
    }

    package(grimoire) void addDefinition(T)(GrLexeme lexeme, T value) {
        GrDefinition def;
        def._table = this;
        def._type = GrDefinition.Type.none;
        def._lexeme = lexeme;

        static if (is(T == GrVariable)) {
            def._type = GrDefinition.Type.variable;
            def._variable = value;
        }
        else static if (is(T == GrFunction)) {
            def._type = GrDefinition.Type.function_;
            def._function = value;
        }
        else static if (is(T == GrPrimitive)) {
            def._type = GrDefinition.Type.primitive;
            def._primitive = value;
        }
        else static if (is(T == GrEnumDefinition)) {
            def._type = GrDefinition.Type.enum_;
            def._enum_ = value;
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

    GrDefinition* getDefinitionAt(size_t fileId, size_t line, size_t column) {
        foreach (ref GrDefinition def; _definitions) {
            if (def._lexeme.fileId == fileId) {
                writeln(def._lexeme.line, ":", def._lexeme.column, " -> ", def._lexeme.getLine());
            }
            if (def._lexeme.fileId != fileId || def._lexeme.line != line)
                continue;

            if (column >= def._lexeme.column && column < (
                    def._lexeme.column + def._lexeme.textLength)) {
                return &def;
            }
        }
        return null;
    }

    GrDefinition fetchDefinition(string path, size_t line, size_t column) {
        GrDefinition noDef;

        path = _sanitizePath(path);
        auto p = path in _filePaths;
        if (!p)
            return noDef;

        const size_t fileId = *p;

        import std.stdio;

        GrDefinition* def = getDefinitionAt(fileId, line, column);
        if (!def) {
            return noDef;
        }

        return *def;
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
