/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module compiler.compiler;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;

import runtime.all;
import assembly.all;
import compiler.lexer;
import compiler.parser;
import lib.all;

GrBytecode grCompiler_compileFile(string fileName) {
	grLib_std_load();

	GrLexer lexer = new GrLexer;
	lexer.scanFile(to!dstring(fileName));

	Parser parser = new Parser;
	parser.parseScript(lexer);

	return generate(parser);
}

private {
	uint makeOpcode(uint instr, uint value) {
		return ((value << 8u) & 0xffffff00) | (instr & 0xff);
	}

	GrBytecode generate(Parser parser) {
		uint nbOpcodes, lastOpcodeCount;

		foreach(func; parser.functions)
			nbOpcodes += cast(uint)func.instructions.length;

		foreach(func; parser.anonymousFunctions)
			nbOpcodes += cast(uint)func.instructions.length;

		//Opcodes
		uint[] opcodes = new uint[nbOpcodes];

		//Write the main function first (not callable).
		auto mainFunc = "main"d in parser.functions;
		if(mainFunc is null)
			throw new Exception("No main declared.");

		foreach(uint i, instruction; mainFunc.instructions)
			opcodes[i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
		lastOpcodeCount = cast(uint)mainFunc.instructions.length;
		parser.functions.remove("main");

		//Every other functions.
		foreach(func; parser.anonymousFunctions) {
			foreach(uint i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
		}
		foreach(func; parser.functions) {
			foreach(uint i, instruction; func.instructions)
				opcodes[lastOpcodeCount + i] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
			foreach(call; func.functionCalls)
				call.position += lastOpcodeCount;
			func.position = lastOpcodeCount;
			lastOpcodeCount += func.instructions.length;
		}
		parser.solveFunctionCalls(opcodes);

		GrBytecode bytecode;
		bytecode.iconsts = parser.iconsts;
		bytecode.fconsts = parser.fconsts;
		bytecode.sconsts = parser.sconsts;
		bytecode.opcodes = opcodes;
		return bytecode;
	}
}