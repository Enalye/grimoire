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

    channel_Int, channel_Float, channel_String, channel_Object,
    send_Int, send_Float, send_String, send_Object,
    receive_Int, receive_Float, receive_String, receive_Object,
    startSelectChannel, endSelectChannel, tryChannel, checkChannel,

    shiftStack_Int, shiftStack_Float, shiftStack_String, shiftStack_Object,
    
    localStore_Int, localStore_Float, localStore_String, localStore_Object,
    localStore2_Int, localStore2_Float, localStore2_String, localStore2_Object,
    localLoad_Int, localLoad_Float, localLoad_String, localLoad_Object,
    
    globalStore_Int, globalStore_Float, globalStore_String, globalStore_Object,
    globalStore2_Int, globalStore2_Float, globalStore2_String, globalStore2_Object,
    globalLoad_Int, globalLoad_Float, globalLoad_String, globalLoad_Object,

    refStore_Int, refStore_Float, refStore_String, refStore_Object,
    refStore2_Int, refStore2_Float, refStore2_String, refStore2_Object,

    fieldStore_Int, fieldStore_Float, fieldStore_String, fieldStore_Object,
    fieldLoad,
    fieldLoad_Int, fieldLoad_Float, fieldLoad_String, fieldLoad_Object,
    fieldLoad2_Int, fieldLoad2_Float, fieldLoad2_String, fieldLoad2_Object,

    const_Int, const_Float, const_Bool, const_String, const_Meta,
    
    globalPush_Int, globalPush_Float, globalPush_String, globalPush_Object,
    globalPop_Int, globalPop_Float, globalPop_String, globalPop_Object,

    equal_Int, equal_Float, equal_String,
    notEqual_Int, notEqual_Float, notEqual_String,
    greaterOrEqual_Int, greaterOrEqual_Float,
    lesserOrEqual_Int, lesserOrEqual_Float,
    greater_Int, greater_Float,
    lesser_Int, lesser_Float,
    isNonNull_Object,

    and_Int, or_Int, not_Int,
    concatenate_String,
    add_Int, add_Float,
    substract_Int, substract_Float,
    multiply_Int, multiply_Float,
    divide_Int, divide_Float,
    remainder_Int, remainder_Float,
    negative_Int, negative_Float,
    increment_Int, increment_Float,
    decrement_Int, decrement_Float,

    swap_Int, swap_Float, swap_String, swap_Object,

    setupIterator,

    localStack_Int, localStack_Float, localStack_String, localStack_Object,
    call, anonymousCall, primitiveCall,
    return_, unwind, defer,
    jump, jumpEqual, jumpNotEqual,

    array_Int, array_Float, array_String, array_Object,
    length_Int, length_Float, length_String, length_Object,
    index_Int, index_Float, index_String, index_Object,
    index2_Int, index2_Float, index2_String, index2_Object,
    index3_Int, index3_Float, index3_String, index3_Object,

    concatenate_IntArray, concatenate_FloatArray, concatenate_StringArray, concatenate_ObjectArray,
    append_Int, append_Float, append_String, append_Object,
    prepend_Int, prepend_Float, prepend_String, prepend_Object,

    equal_IntArray, equal_FloatArray, equal_StringArray,
    notEqual_IntArray, notEqual_FloatArray, notEqual_StringArray,

    debug_ProfileBegin, debug_ProfileEnd
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