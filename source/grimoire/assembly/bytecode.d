/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.bytecode;

import std.stdio;
import std.file;
import std.outbuffer;

/// Low-level instructions for the VM.
enum GrOpcode {
    nop, raise_, try_, catch_,
    kill_, killAll_, yield, task, anonymousTask, new_,

    channel_int, channel_float, channel_string, channel_object,
    send_int, send_float, send_string, send_object,
    receive_int, receive_float, receive_string, receive_object,
    startSelectChannel, endSelectChannel, tryChannel, checkChannel,

    shiftStack_int, shiftStack_float, shiftStack_string, shiftStack_object,
    
    localStore_int, localStore_float, localStore_string, localStore_object,
    localStore2_int, localStore2_float, localStore2_string, localStore2_object,
    localLoad_int, localLoad_float, localLoad_string, localLoad_object,
    
    globalStore_int, globalStore_float, globalStore_string, globalStore_object,
    globalStore2_int, globalStore2_float, globalStore2_string, globalStore2_object,
    globalLoad_int, globalLoad_float, globalLoad_string, globalLoad_object,

    refStore_int, refStore_float, refStore_string, refStore_object,
    refStore2_int, refStore2_float, refStore2_string, refStore2_object,

    fieldStore_int, fieldStore_float, fieldStore_string, fieldStore_object,
    fieldLoad, fieldLoad2,
    fieldLoad_int, fieldLoad_float, fieldLoad_string, fieldLoad_object,
    fieldLoad2_int, fieldLoad2_float, fieldLoad2_string, fieldLoad2_object,

    const_int, const_float, const_bool, const_string, const_meta, const_null,
    
    globalPush_int, globalPush_float, globalPush_string, globalPush_object,
    globalPop_int, globalPop_float, globalPop_string, globalPop_object,

    equal_int, equal_float, equal_string,
    notEqual_int, notEqual_float, notEqual_string,
    greaterOrEqual_int, greaterOrEqual_float,
    lesserOrEqual_int, lesserOrEqual_float,
    greater_int, greater_float,
    lesser_int, lesser_float,
    isNonNull_object,

    and_int, or_int, not_int,
    concatenate_string,
    add_int, add_float,
    substract_int, substract_float,
    multiply_int, multiply_float,
    divide_int, divide_float,
    remainder_int, remainder_float,
    negative_int, negative_float,
    increment_int, increment_float,
    decrement_int, decrement_float,

    swap_int, swap_float, swap_string, swap_object,

    setupIterator,

    localStack_int, localStack_float, localStack_string, localStack_object,
    call, anonymousCall, primitiveCall,
    return_, unwind, defer,
    jump, jumpEqual, jumpNotEqual,

    array_int, array_float, array_string, array_object,
    length_int, length_float, length_string, length_object,
    index_int, index_float, index_string, index_object,
    index2_int, index2_float, index2_string, index2_object,
    index3_int, index3_float, index3_string, index3_object,

    concatenate_intArray, concatenate_floatArray, concatenate_stringArray, concatenate_objectArray,
    append_int, append_float, append_string, append_object,
    prepend_int, prepend_float, prepend_string, prepend_object,

    equal_intArray, equal_floatArray, equal_stringArray,
    notEqual_intArray, notEqual_floatArray, notEqual_stringArray,

    debugProfileBegin, debugProfileEnd
}

/// Compiled form of grimoire.
struct GrBytecode {
    /// All the instructions.
	uint[] opcodes;

    /// Integer constants.
	int[] iconsts;

    /// Floating point constants.
	float[] fconsts;

    /// String constants.
	dstring[] sconsts;

    /// Number of int based global variables declared.
    uint iglobalsCount,
    /// Number of float based global variables declared.
        fglobalsCount,
    /// Number of string based global variables declared.
        sglobalsCount,
    /// Number of ptr based global variables declared.
        oglobalsCount;

    /// global event functions.
    /// Their name are in a mangled state.
    uint[dstring] events;

    /// Serialize the content.
	void toOutBuffer(ref OutBuffer buffer) {
		buffer.write(cast(uint)iconsts.length);
		buffer.write(cast(uint)fconsts.length);
		buffer.write(cast(uint)sconsts.length);
		buffer.write(cast(uint)opcodes.length);
		buffer.write(cast(uint)events.length);

		foreach(uint i; iconsts)
			buffer.write(i);
		foreach(float i; fconsts)
			buffer.write(i);
		foreach(dstring i; sconsts)
			buffer.write(cast(ubyte[])i);
		foreach(uint i; opcodes)
			buffer.write(i);
        foreach(dstring ev, uint pos; events) {
			buffer.write(cast(ubyte[])ev);
			buffer.write(pos);
        }
	}
}

/// Fetch a compiled grimoire file
GrBytecode grCreateBytecodeFromFile(string fileName) {
	GrBytecode bytecode;
	File file = File(fileName, "rb");
    bytecode = grCreateBytecodeFromFile(file);
	file.close();
	return bytecode;
}

/// Fetch a compiled grimoire file
GrBytecode grCreateBytecodeFromFile(File file) {
	GrBytecode bytecode;
	uint[4] header;
	file.rawRead(header);
	bytecode.iconsts.length = cast(size_t)header[0];
	bytecode.fconsts.length = cast(size_t)header[1];
	bytecode.sconsts.length = cast(size_t)header[2];
	bytecode.opcodes.length = cast(size_t)header[3];

	if(bytecode.iconsts.length)
		file.rawRead(bytecode.iconsts);

	if(bytecode.fconsts.length)
		file.rawRead(bytecode.fconsts);

	if(bytecode.sconsts.length)
		file.rawRead(bytecode.sconsts);

	file.rawRead(bytecode.opcodes);
	return bytecode;
}

/// Get the unsigned value part of an instruction
pure uint grGetInstructionUnsignedValue(uint instruction) {
    return (instruction >> 8u) & 0xffffff;
}

/// Get the signed value part of an instruction
pure int grGetInstructionSignedValue(uint instruction) {
    return (cast(int)((instruction >> 8u) & 0xffffff)) - 0x800000;
}

/// Get the opcode part of an instruction
pure uint grGetInstructionOpcode(uint instruction) {
    return instruction & 0xff;
}

/// Format an instruction.
pure uint grMakeInstruction(uint instr, uint value1, uint value2) {
    return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
}