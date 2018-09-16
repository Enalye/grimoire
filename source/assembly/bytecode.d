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

module assembly.bytecode;

import std.stdio;
import std.file;
import std.outbuffer;

import core.all;

enum GrOpcode {
    Kill, Yield, Task, AnonymousTask,
    PopStack_Int, PopStack_Float, PopStack_String, PopStack_Array, PopStack_Any, PopStack_Object,
    LocalStore_Int, LocalStore_Float, LocalStore_String, LocalStore_Array, LocalStore_Any, LocalStore_Ref, LocalStore_Object,
    LocalStore2_Int, LocalStore2_Float, LocalStore2_String, LocalStore2_Array, LocalStore2_Any, LocalStore2_Ref, LocalStore2_Object,
    LocalLoad_Int, LocalLoad_Float, LocalLoad_String, LocalLoad_Array, LocalLoad_Any, LocalLoad_Ref, LocalLoad_Object,
    Const_Int, Const_Float, Const_Bool, Const_String,
    GlobalPush_Int, GlobalPush_Float, GlobalPush_String, GlobalPush_Array, GlobalPush_Any, GlobalPush_Object,
    GlobalPop_Int, GlobalPop_Float, GlobalPop_String, GlobalPop_Array, GlobalPop_Any, GlobalPop_Object,

    ConvertBoolToAny, ConvertIntToAny, ConvertFloatToAny, ConvertStringToAny, ConvertArrayToAny,
    ConvertAnyToBool, ConvertAnyToInt, ConvertAnyToFloat, ConvertAnyToString, ConvertAnyToArray,

    Equal_Int, Equal_Float, Equal_String, Equal_Any,
    NotEqual_Int, NotEqual_Float, NotEqual_String, NotEqual_Any,
    GreaterOrEqual_Int, GreaterOrEqual_Float, GreaterOrEqual_Any,
    LesserOrEqual_Int, LesserOrEqual_Float, LesserOrEqual_Any,
    GreaterInt, GreaterFloat, GreaterAny,
    LesserInt, LesserFloat, LesserAny,

    AndInt, AndAny, OrInt, OrAny, NotInt, NotAny,
    ConcatenateString, ConcatenateAny,
    AddInt, AddFloat, AddAny,
    SubstractInt, SubstractFloat, SubstractAny,
    MultiplyInt, MultiplyFloat, MultiplyAny,
    DivideInt, DivideFloat, DivideAny,
    RemainderInt, RemainderFloat, RemainderAny,
    NegativeInt, NegativeFloat, NegativeAny,
    IncrementInt, IncrementFloat, IncrementAny,
    DecrementInt, DecrementFloat, DecrementAny,

    LocalStore_upIterator,

    LocalStack, Call, AnonymousCall, PrimitiveCall, Return,
    Jump, JumpEqual, JumpNotEqual,

    ArrayBuild, ArrayLength, ArrayIndex, ArrayIndexRef
}

struct GrBytecode {
	uint[] opcodes;
	int[] iconsts;
	float[] fconsts;
	dstring[] sconsts;

	void toOutBuffer(ref OutBuffer buffer) {
		buffer.write(cast(uint)iconsts.length);
		buffer.write(cast(uint)fconsts.length);
		buffer.write(cast(uint)sconsts.length);
		buffer.write(cast(uint)opcodes.length);

		foreach(uint i; iconsts)
			buffer.write(i);
		foreach(float i; fconsts)
			buffer.write(i);
		foreach(dstring i; sconsts)
			buffer.write(cast(ubyte[])i);
		foreach(uint i; opcodes)
			buffer.write(i);
	}
}

GrBytecode grBytecode_newFromFile(string fileName) {
	GrBytecode bytecode;
	File file = File(fileName, "rb");
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
	file.close();
	return bytecode;
}

GrBytecode grBytecode_newFromFile(File file) {
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

pure uint grBytecode_getUnsignedValue(uint opcode) {
    return (opcode >> 8u) & 0xffffff;
}

pure int grBytecode_getSignedValue(uint opcode) {
    return (cast(int)((opcode >> 8u) & 0xffffff)) - 0x800000;
}

pure uint grBytecode_getOpcode(uint opcode) {
    return opcode & 0xff;
}

pure uint grBytecode_makeInstruction(uint instr, uint value1, uint value2) {
    return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
}