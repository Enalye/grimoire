/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.compiler;

import std.stdio, std.string, std.array, std.conv, std.math, std.file;
import grimoire.runtime, grimoire.assembly;
import grimoire.compiler.lexer, grimoire.compiler.parser, grimoire.compiler.primitive;
import grimoire.compiler.type, grimoire.compiler.data, grimoire.compiler.error;

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
	this(GrData data) {
		_data = data;
	}

	/** 
	 * Compile a source file into bytecode
	 * Params:
	 *	The bytecode struct passed by ref
	 *  fileName = Path to script file to compile
	 * Returns:
	 *  True if compilation was successful, otherwise check `getError()`
	 */
	bool compileFile(ref GrBytecode bytecode, string fileName, int flags = Flags.none) {
		_error = null;
		try {
			GrLexer lexer = new GrLexer;
			lexer.scanFile(to!dstring(fileName));

			GrParser parser = new GrParser;
			if(flags & Flags.profile)
				parser.setProfiling(true);
			parser.parseScript(_data, lexer);

			bytecode = generate(parser);
		}
		catch(GrLexerException e) {
			_error = e.error;
			return false;
		}
		catch(GrParserException e) {
			_error = e.error;
			return false;
		}
		return true;
	}

	/// If an error occurred, fetch it here.
	GrError getError() {
		return _error;
	}
}

private {
	uint makeOpcode(uint instr, uint value) {
		return ((value << 8u) & 0xffffff00) | (instr & 0xff);
	}

	GrBytecode generate(GrParser parser) {
		uint nbOpcodes, lastOpcodeCount;

		foreach(func; parser.functions)
			nbOpcodes += cast(uint)func.instructions.length;

		foreach(func; parser.anonymousFunctions)
			nbOpcodes += cast(uint)func.instructions.length;

        foreach(func; parser.events)
			nbOpcodes += cast(uint)func.instructions.length;

        //We leave space for one kill instruction at the end.
        nbOpcodes ++;

		//Without "main", we put a kill instruction instead.
		if(("main"d in parser.functions) is null)
			nbOpcodes ++;

		//Opcodes
		uint[] opcodes = new uint[nbOpcodes];

        //Start with the global initializations
        auto globalScope = "@global"d in parser.functions;
        if(globalScope) {
            foreach(size_t i, instruction; globalScope.instructions)
                opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
            lastOpcodeCount += cast(uint)globalScope.instructions.length;
            parser.functions.remove("@global"d);
        }

		//Then write the main function (not callable).
		auto mainFunc = "main"d in parser.functions;
		if(mainFunc) {
			mainFunc.position = lastOpcodeCount;
			foreach(size_t i, instruction; mainFunc.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; mainFunc.functionCalls)
				call.position += lastOpcodeCount;
			lastOpcodeCount += cast(uint)mainFunc.instructions.length;
			parser.functions.remove("main"d);
		}
		else {
			opcodes[lastOpcodeCount] = makeOpcode(cast(uint) GrOpcode.kill_, 0u);
			lastOpcodeCount ++;
		}

		//Every other functions.
        uint[dstring] events;
        foreach(dstring mangledName, GrFunction func; parser.events) {
			foreach(size_t i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
            events[mangledName] = func.position;
		}
		foreach(func; parser.anonymousFunctions) {
			foreach(size_t i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
		}
		foreach(func; parser.functions) {
			foreach(size_t i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
		}
		parser.solveFunctionCalls(opcodes);

        //The contexts will jump here if the VM is panicking.
        opcodes[$ - 1] = makeOpcode(cast(uint)GrOpcode.unwind, 0);

		GrBytecode bytecode;

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
		return bytecode;
	}
}