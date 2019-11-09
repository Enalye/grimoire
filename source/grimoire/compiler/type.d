/**
    Type definitions.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.compiler.type;

import std.conv: to;

import grimoire.runtime;
import grimoire.assembly;
import grimoire.compiler.mangle;
import grimoire.compiler.data;

/**
Type category.

Complex types use mangledType and mangledReturnType
to represent them.
*/
enum GrBaseType {
    VoidType, IntType, FloatType, BoolType, StringType,
    ArrayType, FunctionType, TaskType,
    StructType, TupleType, UserType, ChanType,
    InternalTupleType,
    ReferenceType, 
}

/**
Compiler type definition for Grimoire's type system.
It doesn't mean anything for the VM.
*/
struct GrType {
    GrBaseType baseType;
    dstring mangledType, mangledReturnType;
    bool isField;

    this(GrBaseType newBaseType) {
        baseType = newBaseType;
    }

    this(GrBaseType newBaseType, dstring newMangledType) {
        baseType = newBaseType;
        mangledType = newMangledType;
    }

    GrType opOpAssign(string op)(GrBaseType t) {
		mixin("baseType = baseType" ~ op ~ "t;");
		return this;
	}

    bool opEquals(const GrBaseType v) const {
		return (baseType == v);
	}
    
    bool opEquals(const GrType v) const {
        if(baseType != v.baseType)
            return false;
        if(baseType == GrBaseType.FunctionType || baseType == GrBaseType.TaskType)
            return mangledType == v.mangledType && mangledReturnType == v.mangledReturnType;
        return true;
	}
}

const GrType grVoid = GrType(GrBaseType.VoidType);
const GrType grInt = GrType(GrBaseType.IntType);
const GrType grFloat = GrType(GrBaseType.FloatType);
const GrType grBool = GrType(GrBaseType.BoolType);
const GrType grString = GrType(GrBaseType.StringType);
const GrType grIntArray = GrType(GrBaseType.ArrayType, grMangleFunction([grInt]));
const GrType grFloatArray = GrType(GrBaseType.ArrayType, grMangleFunction([grFloat]));
const GrType grStringArray = GrType(GrBaseType.ArrayType, grMangleFunction([grString]));


GrType grPackTuple(GrType[] types) {
    const dstring mangledName = grMangleFunction(types);
    GrType type = GrBaseType.InternalTupleType;
    type.mangledType = mangledName;
    return type;
}

GrType[] grUnpackTuple(GrType type) {
    if(type.baseType != GrBaseType.InternalTupleType)
        throw new Exception("Cannot unpack a not tuple type.");
    return grUnmangleSignature(type.mangledType);
}

/**
    A local or global variable.
*/
class GrVariable {
	GrType type;
	uint index;
	bool isGlobal, isField, isInitialized, isAuto, isConstant;
    dstring name;
}


GrType grGetUserType(dstring name) {
    GrType type = GrBaseType.UserType;
    type.mangledType = name;
    return type;
}

class GrTuple {
    GrType[] signature;
    dstring[] fields;
}

GrType grGetTupleType(dstring name) {
    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}



class GrStruct {
    GrType[] signature;
    dstring[] fields;
}

GrType grGetStructType(dstring name) {
    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

struct GrInstruction {
	GrOpcode opcode;
	uint value;
}

class GrFunction {
	GrVariable[dstring] localVariables;
    uint[] localFreeVariables;
	GrInstruction[] instructions;
	uint stackSize, index;

	dstring name;
	GrType[] inSignature, outSignature;
	bool isTask, isAnonymous;

	GrFunctionCall[] functionCalls;
	GrFunction anonParent;
	uint position, anonReference, localVariableIndex;

	uint nbIntegerParameters, nbFloatParameters, nbStringParameters, nbObjectParameters;

    GrDeferrableSection[] deferrableSections;
    GrDeferBlock[] registeredDeferBlocks;
    bool[] isDeferrableSectionLocked = [false];
}

class GrFunctionCall {
	dstring mangledName;
	uint position;
	GrFunction caller, functionToCall;
	GrType expectedType;
    bool isAddress;
}

class GrDeferrableSection {
    GrDeferBlock[] deferredBlocks;
    uint deferInitPositions;
    uint[] deferredCalls;
}

class GrDeferBlock {
    uint position;
    uint parsePosition;
    uint scopeLevel;
}