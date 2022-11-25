/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.compiler;

import std.stdio, std.string, std.array, std.conv, std.math, std.file;
import grimoire.runtime, grimoire.assembly;
import grimoire.compiler.util, grimoire.compiler.lexer, grimoire.compiler.parser,
    grimoire.compiler.primitive, grimoire.compiler.type, grimoire.compiler.data,
    grimoire.compiler.error, grimoire.compiler.mangle,
    grimoire.compiler.library, grimoire.compiler.pretty;

/// Compile un fichier source en un bytecode exécutable
final class GrCompiler {
    private {
        GrData _data;
        GrError _error;
        uint _userVersion;
    }

    this(uint userVersion = 0u) {
        _userVersion = userVersion;
        _data = new GrData;
    }

    /// Ajoute les types et primitives définis dans la bibliothèque
    void addLibrary(GrLibrary library) {
        _data.addLibrary(library);
    }

    /** 
     * Compile un fichier source en bytecode
     * Paramètres:
     *  fileName = le chemin vers le fichier à compiler \
     *  options = options de compilation supplémentaires \
     *  locale = langue d’affichage des messages d’erreurs
     * Returne:
     *  Le bytecode généré, sinon vérifiez `getError()`
     */
    GrBytecode compileFile(string fileName, int options = GrOption.none,
        GrLocale locale = GrLocale.en_US) {
        _error = null;
        try {
            GrLexer lexer = new GrLexer(locale);
            lexer.scanFile(_data, fileName);

            GrParser parser = new GrParser(locale);
            parser.parseScript(_data, lexer, options);

            return generate(lexer, parser, options, locale);
        }
        catch (GrLexerException e) {
            _error = e.error;
            return null;
        }
        catch (GrParserException e) {
            _error = e.error;
            return null;
        }
    }

    /// Si une erreur survient, récupèrez l’erreur ici
    GrError getError() {
        return _error;
    }

    private uint makeOpcode(uint instr, uint value) {
        return ((value << 8u) & 0xffffff00) | (instr & 0xff);
    }

    private GrBytecode generate(GrLexer lexer, GrParser parser, int options, GrLocale locale) {
        uint nbOpcodes, lastOpcodeCount;

        GrBytecode bytecode = new GrBytecode;

        bytecode.grimoireVersion = GRIMOIRE_VERSION;
        bytecode.userVersion = _userVersion;

        foreach (func; parser.functions)
            nbOpcodes += cast(uint) func.instructions.length;

        foreach (func; parser.anonymousFunctions)
            nbOpcodes += cast(uint) func.instructions.length;

        foreach (func; parser.events)
            nbOpcodes += cast(uint) func.instructions.length;

        // On laisse de la place pour le `die`
        nbOpcodes += 2;

        // Opcodes
        uint[] opcodes = new uint[nbOpcodes];

        // On commence avec les initialisations globales
        auto globalScope = parser.getFunction("@global");
        if (globalScope) {
            if (options & GrOption.symbols) {
                auto debugSymbol = new GrFunctionSymbol;
                debugSymbol.start = lastOpcodeCount;
                debugSymbol.name = grGetPrettyFunction(globalScope);
                debugSymbol.length = cast(uint) globalScope.instructions.length;
                debugSymbol.file = lexer.getFile(globalScope.fileId);
                foreach (ref position; globalScope.debugSymbol) {
                    GrFunctionSymbol.Position pos;
                    pos.line = position.line;
                    pos.column = position.column;
                    debugSymbol.positions ~= pos;
                }
                bytecode.symbols ~= debugSymbol;
            }

            foreach (size_t i, instruction; globalScope.instructions)
                opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
                    instruction.value);
            lastOpcodeCount += cast(uint) globalScope.instructions.length;
            parser.removeFunction("@global");
        }

        // Puis on clot la section globale
        opcodes[lastOpcodeCount] = makeOpcode(cast(uint) GrOpcode.die, 0u);
        lastOpcodeCount++;

        // Toutes les autres fonctions
        uint[string] events;
        foreach (GrFunction func; parser.events) {
            if (options & GrOption.symbols) {
                auto debugSymbol = new GrFunctionSymbol();
                debugSymbol.start = lastOpcodeCount;
                debugSymbol.name = grGetPrettyFunction(func);
                debugSymbol.length = cast(uint) func.instructions.length;
                debugSymbol.file = lexer.getFile(func.fileId);

                foreach (ref position; func.debugSymbol) {
                    GrFunctionSymbol.Position pos;
                    pos.line = position.line;
                    pos.column = position.column;
                    debugSymbol.positions ~= pos;
                }

                bytecode.symbols ~= debugSymbol;
            }

            foreach (size_t i, instruction; func.instructions)
                opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
                    instruction.value);

            foreach (call; func.functionCalls)
                call.position += lastOpcodeCount;

            func.position = lastOpcodeCount;
            lastOpcodeCount += cast(uint) func.instructions.length;
            events[func.mangledName] = func.position;
        }

        foreach (func; parser.anonymousFunctions) {
            if (options & GrOption.symbols) {
                auto debugSymbol = new GrFunctionSymbol();
                debugSymbol.start = lastOpcodeCount;
                debugSymbol.name = grGetPrettyFunction(func);
                debugSymbol.length = cast(uint) func.instructions.length;
                debugSymbol.file = lexer.getFile(func.fileId);
                foreach (ref position; func.debugSymbol) {
                    GrFunctionSymbol.Position pos;
                    pos.line = position.line;
                    pos.column = position.column;
                    debugSymbol.positions ~= pos;
                }
                bytecode.symbols ~= debugSymbol;
            }

            foreach (size_t i, instruction; func.instructions)
                opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
                    instruction.value);

            foreach (call; func.functionCalls)
                call.position += lastOpcodeCount;

            func.position = lastOpcodeCount;
            lastOpcodeCount += func.instructions.length;

            if (func.isEvent)
                events[func.mangledName] = func.position;
        }

        foreach (func; parser.functions) {
            if (options & GrOption.symbols) {
                auto debugSymbol = new GrFunctionSymbol();
                debugSymbol.start = lastOpcodeCount;
                debugSymbol.name = grGetPrettyFunction(func);
                debugSymbol.length = cast(uint) func.instructions.length;
                debugSymbol.file = lexer.getFile(func.fileId);
                foreach (ref position; func.debugSymbol) {
                    GrFunctionSymbol.Position pos;
                    pos.line = position.line;
                    pos.column = position.column;
                    debugSymbol.positions ~= pos;
                }
                bytecode.symbols ~= debugSymbol;
            }

            foreach (size_t i, instruction; func.instructions)
                opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
                    instruction.value);

            foreach (call; func.functionCalls)
                call.position += lastOpcodeCount;

            func.position = lastOpcodeCount;
            lastOpcodeCount += func.instructions.length;
        }
        parser.solveFunctionCalls(opcodes);

        // Les tâches sauteront ici si jamais la machine virtuelle panique
        opcodes[$ - 1] = makeOpcode(cast(uint) GrOpcode.unwind, 0);

        // les constantes
        bytecode.iconsts = parser.iconsts;
        bytecode.rconsts = parser.rconsts;
        bytecode.sconsts = parser.sconsts;

        // Les variables globales
        bytecode.globalsCount = parser.globalsCount;

        foreach (variableDef; _data._variableDefinitions) {
            GrBytecode.Variable variable;
            variable.index = variableDef.register;
            final switch (variableDef.type.base) with (GrType.Base) {
            case bool_:
            case int_:
            case func:
            case task:
            case event:
            case enum_:
                variable.typeMask = 0x1;
                variable.ivalue = variableDef.isInitialized ? variableDef.ivalue : 0;
                break;
            case float_:
                variable.typeMask = 0x2;
                variable.rvalue = variableDef.isInitialized ? variableDef.rvalue : 0f;
                break;
            case string_:
                variable.typeMask = 0x4;
                variable.svalue = variableDef.isInitialized ? variableDef.svalue : "";
                break;
            case list:
            case class_:
            case native:
            case channel:
            case optional:
                variable.typeMask = 0x8;
                break;
            case void_:
            case internalTuple:
            case reference:
            case null_:
                final switch (locale) with (GrLocale) {
                case en_US:
                    throw new Exception(
                        "invalid global variable type, the type cannot be " ~ grGetPrettyType(
                            variableDef.type));
                case fr_FR:
                    throw new Exception(
                        "type de variable globale invalide, le type ne peut pas être " ~ grGetPrettyType(
                            variableDef.type));
                }
            }
            bytecode.variables[variableDef.name] = variable;
        }

        // Les instuctions
        bytecode.opcodes = opcodes;

        // Les événements globaux
        bytecode.events = events;

        // On initialize toutes les primitives
        bytecode.primitives.length = _data._primitives.length;
        for (size_t id; id < bytecode.primitives.length; ++id) {
            bytecode.primitives[id].index = _data._primitives[id].callbackId;
            GrType[] inSignature = _data._primitives[id].inSignature;
            if (_data._primitives[id].name == "@as")
                inSignature.length = 1;
            else if (_data._primitives[id].name.length >= "@static_".length &&
                _data._primitives[id].name[0 .. "@static_".length] == "@static_")
                inSignature.length--;
            for (size_t i; i < inSignature.length; ++i) {
                const GrType type = inSignature[i];
                bytecode.primitives[id].inSignature ~= grMangle(type);
                final switch (type.base) with (GrType.Base) {
                case bool_:
                case int_:
                case func:
                case task:
                case event:
                case enum_:
                    bytecode.primitives[id].parameters ~= 0x10000 | (
                        bytecode.primitives[id].params & 0xFFFF);
                    bytecode.primitives[id].params++;
                    break;
                case float_:
                    bytecode.primitives[id].parameters ~= 0x20000 | (
                        bytecode.primitives[id].params & 0xFFFF);
                    bytecode.primitives[id].params++;
                    break;
                case string_:
                    bytecode.primitives[id].parameters ~= 0x40000 | (
                        bytecode.primitives[id].params & 0xFFFF);
                    bytecode.primitives[id].params++;
                    break;
                case list:
                case class_:
                case native:
                case channel:
                case optional:
                    bytecode.primitives[id].parameters ~= 0x80000 | (
                        bytecode.primitives[id].params & 0xFFFF);
                    bytecode.primitives[id].params++;
                    break;
                case void_:
                case internalTuple:
                case reference:
                case null_:
                    final switch (locale) with (GrLocale) {
                    case en_US:
                        throw new Exception("invalid parameter type in " ~ grGetPrettyFunctionCall(
                                _data._primitives[id].name,
                                inSignature) ~ ", the type cannot be " ~ grGetPrettyType(type));
                    case fr_FR:
                        throw new Exception("type de paramètre invalide " ~ grGetPrettyFunctionCall(
                                _data._primitives[id].name,
                                inSignature) ~ ", le type ne peut pas être " ~ grGetPrettyType(
                                type));
                    }
                }
            }
            for (size_t i; i < _data._primitives[id].outSignature.length; ++i) {
                bytecode.primitives[id].outSignature ~= grMangle(
                    _data._primitives[id].outSignature[i]);
            }
        }

        // On renseigne les définitions de classes
        for (size_t i; i < _data._classDefinitions.length; ++i) {
            GrClassBuilder class_ = new GrClassBuilder;
            class_.name = _data._classDefinitions[i].name;
            class_.fields = _data._classDefinitions[i].fields;
            bytecode.classes ~= class_;
        }

        return bytecode;
    }
}
