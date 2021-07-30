/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.compiler;

import std.stdio, std.string, std.array, std.conv, std.math, std.file;
import grimoire.runtime, grimoire.assembly;
import grimoire.compiler.lexer, grimoire.compiler.parser, grimoire.compiler.primitive;
import grimoire.compiler.type, grimoire.compiler.data, grimoire.compiler.error,
	grimoire.compiler.mangle, grimoire.compiler.library, grimoire.compiler.pretty;

/// Compiler class, generate bytecode and hold errors.
final class GrCompiler {
	/// Compiler options
	enum Flags {
		/// Default
		none = 0x0,
		/// Add profiling commands to bytecode to fill profiling information
		profile = 0x1
	}

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
	 *	The bytecode struct passed by ref
	 *  fileName = Path to script file to compile
	 * Returns:
	 *  True if compilation was successful, otherwise check `getError()`
	 */
	GrBytecode compileFile(string fileName, int flags = Flags.none) {
		_error = null;
		try {
			GrLexer lexer = new GrLexer;
			lexer.scanFile(fileName);

			GrParser parser = new GrParser;
			if (flags & Flags.profile)
				parser.setProfiling(true);
			parser.parseScript(_data, lexer);

			return generate(parser);
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

	private GrBytecode generate(GrParser parser) {
		uint nbOpcodes, lastOpcodeCount;

		foreach (func; parser.functions)
			nbOpcodes += cast(uint) func.instructions.length;

		foreach (func; parser.anonymousFunctions)
			nbOpcodes += cast(uint) func.instructions.length;

		foreach (func; parser.events)
			nbOpcodes += cast(uint) func.instructions.length;

		//We leave space for one kill instruction at the end.
		nbOpcodes++;

		//Without "main", we put a kill instruction instead.
		if (parser.getFunction("main") is null)
			nbOpcodes++;

		//Opcodes
		uint[] opcodes = new uint[nbOpcodes];

		//Start with the global initializations
		auto globalScope = parser.getFunction("@global");
		if (globalScope) {
			foreach (size_t i, instruction; globalScope.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
						instruction.value);
			lastOpcodeCount += cast(uint) globalScope.instructions.length;
			parser.removeFunction("@global");
		}

		//Then write the main function (not callable).
		auto mainFunc = parser.getFunction("main");
		if (mainFunc) {
			mainFunc.position = lastOpcodeCount;
			foreach (size_t i, instruction; mainFunc.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
						instruction.value);
			foreach (call; mainFunc.functionCalls)
				call.position += lastOpcodeCount;
			lastOpcodeCount += cast(uint) mainFunc.instructions.length;
			parser.removeFunction("main");
		}
		else {
			opcodes[lastOpcodeCount] = makeOpcode(cast(uint) GrOpcode.kill_, 0u);
			lastOpcodeCount++;
		}

		//Every other functions.
		uint[string] events;
		foreach (GrFunction func; parser.events) {
			foreach (size_t i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
						instruction.value);
			foreach (call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
			events[func.mangledName] = func.position;
		}
		foreach (func; parser.anonymousFunctions) {
			foreach (size_t i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint) instruction.opcode,
						instruction.value);
			foreach (call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
		}
		foreach (func; parser.functions) {
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

		GrBytecode bytecode = new GrBytecode;

		//Constants.
		bytecode.iconsts = parser.iconsts;
		bytecode.fconsts = parser.fconsts;
		bytecode.sconsts = parser.sconsts;

		//Global variables.
		bytecode.iglobalsCount = parser.iglobalsCount;
		bytecode.fglobalsCount = parser.fglobalsCount;
		bytecode.sglobalsCount = parser.sglobalsCount;
		bytecode.oglobalsCount = parser.oglobalsCount;

		//Instuctions.
		bytecode.opcodes = opcodes;

		//Global events.
		bytecode.events = events;

		//Initialize every primitives.
		bytecode.primitives.length = _data._primitives.length;
		for (int id; id < bytecode.primitives.length; ++id) {
			bytecode.primitives[id].index = _data._primitives[id].callbackId;
			GrType[] inSignature = _data._primitives[id].inSignature;
			if (_data._primitives[id].name == "@as")
				inSignature.length = 1;
			for (int i; i < inSignature.length; ++i) {
				const GrType type = inSignature[i];
				final switch (type.baseType) with (GrBaseType) {
				case bool_:
				case int_:
				case function_:
				case task:
				case enum_:
				case chan:
					bytecode.primitives[id].parameters ~= 0x10000 | (bytecode.primitives[id].iparams & 0xFFFF);
					bytecode.primitives[id].iparams++;
					break;
				case float_:
					bytecode.primitives[id].parameters ~= 0x20000 | (bytecode.primitives[id].fparams & 0xFFFF);
					bytecode.primitives[id].fparams++;
					break;
				case string_:
					bytecode.primitives[id].parameters ~= 0x40000 | (bytecode.primitives[id].sparams & 0xFFFF);
					bytecode.primitives[id].sparams++;
					break;
				case array_:
				case class_:
				case foreign:
					bytecode.primitives[id].parameters ~= 0x80000 | (bytecode.primitives[id].oparams & 0xFFFF);
					bytecode.primitives[id].oparams++;
					break;
				case void_:
				case internalTuple:
				case reference:
				case null_:
					throw new Exception("invalid parameter type in " ~ grGetPrettyFunctionCall(
							_data._primitives[id].name,
							inSignature) ~ ", the type cannot be " ~ grGetPrettyType(type));
				}
			}
		}

		/// Fill in class information
		for (int i; i < _data._classDefinitions.length; ++i) {
			GrClassBuilder class_ = new GrClassBuilder;
			class_.name = _data._classDefinitions[i].name;
			class_.fields = _data._classDefinitions[i].fields;
			bytecode.classes ~= class_;
		}

		return bytecode;
	}
}
