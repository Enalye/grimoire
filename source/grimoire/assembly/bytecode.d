/**
    Bytecode definition.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.assembly.bytecode;

import std.stdio;
import std.file;
import std.outbuffer;

import grimoire.core;

/// Low level instruction for the VM
enum GrOpcode {
    Nop, Raise, Try, Catch,
    Kill, KillAll, Yield, Task, AnonymousTask, New,

    Channel_Int, Channel_Float, Channel_String, Channel_Variant, Channel_Object,
    Send_Int, Send_Float, Send_String, Send_Variant, Send_Object,
    Receive_Int, Receive_Float, Receive_String, Receive_Variant, Receive_Object,
    StartSelectChannel, EndSelectChannel, TryChannel, CheckChannel,
   
    ShiftStack_Int, ShiftStack_Float, ShiftStack_String, ShiftStack_Variant, ShiftStack_Object,
    
    LocalStore_Int, LocalStore_Float, LocalStore_String, LocalStore_Variant, LocalStore_Object,
    LocalStore2_Int, LocalStore2_Float, LocalStore2_String, LocalStore2_Variant, LocalStore2_Object,
    LocalLoad_Int, LocalLoad_Float, LocalLoad_String, LocalLoad_Variant, LocalLoad_Object,
    
    GlobalStore_Int, GlobalStore_Float, GlobalStore_String, GlobalStore_Variant, GlobalStore_Object,
    GlobalStore2_Int, GlobalStore2_Float, GlobalStore2_String, GlobalStore2_Variant, GlobalStore2_Object,
    GlobalLoad_Int, GlobalLoad_Float, GlobalLoad_String, GlobalLoad_Variant, GlobalLoad_Object,

    RefStore_Int, RefStore_Float, RefStore_String, RefStore_Variant, RefStore_Object,
    RefStore2_Int, RefStore2_Float, RefStore2_String, RefStore2_Variant, RefStore2_Object,
    
    GetField,
    FieldStore_Int, FieldStore_Float, FieldStore_String, FieldStore_Variant, FieldStore_Object,
    FieldLoad_Int, FieldLoad_Float, FieldLoad_String, FieldLoad_Variant, FieldLoad_Object,

    Const_Int, Const_Float, Const_Bool, Const_String, Const_Meta,
    
    GlobalPush_Int, GlobalPush_Float, GlobalPush_String, GlobalPush_Variant, GlobalPush_Object,
    GlobalPop_Int, GlobalPop_Float, GlobalPop_String, GlobalPop_Variant, GlobalPop_Object,

    Equal_Int, Equal_Float, Equal_String, Equal_Variant,
    NotEqual_Int, NotEqual_Float, NotEqual_String, NotEqual_Variant,
    GreaterOrEqual_Int, GreaterOrEqual_Float, GreaterOrEqual_Variant,
    LesserOrEqual_Int, LesserOrEqual_Float, LesserOrEqual_Variant,
    Greater_Int, Greater_Float, Greater_Variant,
    Lesser_Int, Lesser_Float, Lesser_Variant,

    And_Int, And_Variant, Or_Int, Or_Variant, Not_Int, Not_Variant,
    Concatenate_String, Concatenate_Variant, Concatenate_Array,
    Add_Int, Add_Float, Add_Variant,
    Substract_Int, Substract_Float, Substract_Variant,
    Multiply_Int, Multiply_Float, Multiply_Variant,
    Divide_Int, Divide_Float, Divide_Variant,
    Remainder_Int, Remainder_Float, Remainder_Variant,
    Negative_Int, Negative_Float, Negative_Variant,
    Increment_Int, Increment_Float, Increment_Variant,
    Decrement_Int, Decrement_Float, Decrement_Variant,

    SetupIterator,

    LocalStack, Call, AnonymousCall, VariantCall, PrimitiveCall,
    Return, Unwind, Defer,
    Jump, JumpEqual, JumpNotEqual,

    Array, Length,
    Index_Array, Index_Variant,
    Copy_Array, Copy_Variant,
    Append, Prepend

}

/// Compiled form of grimoire
struct GrBytecode {
	uint[] opcodes;
	int[] iconsts;
	float[] fconsts;
	dstring[] sconsts;
    uint[dstring] events;

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

pure uint grMakeInstruction(uint instr, uint value1, uint value2) {
    return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
}