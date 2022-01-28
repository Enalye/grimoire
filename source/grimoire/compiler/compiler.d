/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.compiler;

import std.stdio, std.string, std.array, std.conv, std.math, std.file;
import grimoire.runtime, grimoire.assembly;
import grimoire.compiler.util, grimoire.compiler.lexer, grimoire.compiler.parser,
grimoire.compiler.primitive, grimoire.compiler.type, grimoire.compiler.data,
grimoire.compiler.error, grimoire.compiler.mangle,
grimoire.compiler.library, grimoire.compiler.pretty;

/// Compiler class, generate bytecode and hold errors.
final class GrCompiler {
    private {
        GrData _data;
        GrError _error;
    }

    /// Ctor
    this() {
        _data = new GrData;
    }

    /// Add types and primitives defined in the library
    void addLibrary(GrLibrary library) {
        _data.addLibrary(library);
    }

    /** 
     * Compile a source file into bytecode
     * Params:
     *  fileName = the path to the file to compile
     *  options = optional compilation flags
     *  locale = in which language should errors be reported in
     * Returns:
     *  The generated bytecode, otherwise check `getError()`
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

    /// If an error occurred, fetch it here.
    GrError getError() {
        return _error;
    }

    private uint makeOpcode(uint instr, uint value) {
        return ((value << 8u) & 0xffffff00) | (instr & 0xff);
    }

    private GrBytecode generate(GrLexer lexer, GrParser parser, int options, GrLocale locale) {
        uint nbOpcodes, lastOpcodeCount;

        GrBytecode bytecode = new GrBytecode;

        foreach (func; parser.functions)
            nbOpcodes += cast(uint) func.instructions.length;

        foreach (func; parser.anonymousFunctions)
            nbOpcodes += cast(uint) func.instructions.length;

        foreach (func; parser.events)
            nbOpcodes += cast(uint) func.instructions.length;

        //We leave space for die instructions.
        nbOpcodes += 2;

        //Opcodes
        uint[] opcodes = new uint[nbOpcodes];

        //Start with the global initializations
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

        //Then we terminate the global section
        opcodes[lastOpcodeCount] = makeOpcode(cast(uint) GrOpcode.die, 0u);
        lastOpcodeCount++;

        //Every other functions.
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

        //The contexts will jump here if the VM is panicking.
        opcodes[$ - 1] = makeOpcode(cast(uint) GrOpcode.unwind, 0);

        //Constants.
        bytecode.iconsts = parser.iconsts;
        bytecode.rconsts = parser.rconsts;
        bytecode.sconsts = parser.sconsts;

        //Global variables.
        bytecode.iglobalsCount = parser.iglobalsCount;
        bytecode.rglobalsCount = parser.rglobalsCount;
        bytecode.sglobalsCount = parser.sglobalsCount;
        bytecode.oglobalsCount = parser.oglobalsCount;

        foreach (variableDef; _data._variableDefinitions) {
            GrBytecode.Variable variable;
            variable.index = variableDef.register;
            final switch (variableDef.type.base) with (GrType.Base) {
            case boolean:
            case integer:
            case function_:
            case task:
            case enumeration:
            case channel:
                variable.typeMask = 0x1;
                variable.ivalue = variableDef.isInitialized ? variableDef.ivalue : 0;
                break;
            case real_:
                variable.typeMask = 0x2;
                variable.rvalue = variableDef.isInitialized ? variableDef.rvalue : 0f;
                break;
            case string_:
                variable.typeMask = 0x4;
                variable.svalue = variableDef.isInitialized ? variableDef.svalue : "";
                break;
            case array:
            case class_:
            case foreign:
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

        //Instuctions.
        bytecode.opcodes = opcodes;

        //Global events.
        bytecode.events = events;

        //Initialize every primitives.
        bytecode.primitives.length = _data._primitives.length;
        for (size_t id; id < bytecode.primitives.length; ++id) {
            bytecode.primitives[id].index = _data._primitives[id].callbackId;
            GrType[] inSignature = _data._primitives[id].inSignature;
            if (_data._primitives[id].name == "@conv")
                inSignature.length = 1;
            for (size_t i; i < inSignature.length; ++i) {
                const GrType type = inSignature[i];
                bytecode.primitives[id].inSignature ~= grMangle(type);
                final switch (type.base) with (GrType.Base) {
                case boolean:
                case integer:
                case function_:
                case task:
                case enumeration:
                    bytecode.primitives[id].parameters ~= 0x10000 | (
                        bytecode.primitives[id].iparams & 0xFFFF);
                    bytecode.primitives[id].iparams++;
                    break;
                case real_:
                    bytecode.primitives[id].parameters ~= 0x20000 | (
                        bytecode.primitives[id].fparams & 0xFFFF);
                    bytecode.primitives[id].fparams++;
                    break;
                case string_:
                    bytecode.primitives[id].parameters ~= 0x40000 | (
                        bytecode.primitives[id].sparams & 0xFFFF);
                    bytecode.primitives[id].sparams++;
                    break;
                case array:
                case class_:
                case foreign:
                case channel:
                    bytecode.primitives[id].parameters ~= 0x80000 | (
                        bytecode.primitives[id].oparams & 0xFFFF);
                    bytecode.primitives[id].oparams++;
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

        /// Fill in class information
        for (size_t i; i < _data._classDefinitions.length; ++i) {
            GrClassBuilder class_ = new GrClassBuilder;
            class_.name = _data._classDefinitions[i].name;
            class_.fields = _data._classDefinitions[i].fields;
            bytecode.classes ~= class_;
        }

        return bytecode;
    }
}
