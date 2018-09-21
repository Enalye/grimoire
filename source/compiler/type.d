/**
    Type definitions.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module compiler.type;

import std.conv: to;

import runtime.all;
import assembly.all;
import compiler.mangle;

enum GrBaseType {
    VoidType, IntType, FloatType, BoolType, StringType,
    ArrayType, ObjectType, DynamicType, FunctionType, TaskType,
    StructType
}

struct GrType {
    GrBaseType baseType;
    dstring mangledType, mangledReturnType;

    this(GrBaseType newBaseType) {
        baseType = newBaseType;
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
           return mangledType == v.mangledType && mangledReturnType && v.mangledReturnType; 
        return true;
	}
}

const GrType grVoid = GrType(GrBaseType.VoidType);
const GrType grInt = GrType(GrBaseType.IntType);
const GrType grFloat = GrType(GrBaseType.FloatType);
const GrType grBool = GrType(GrBaseType.BoolType);
const GrType grString = GrType(GrBaseType.StringType);
const GrType grArray = GrType(GrBaseType.ArrayType);
const GrType grObject = GrType(GrBaseType.ObjectType);
const GrType grDynamic = GrType(GrBaseType.DynamicType);


class GrVariable {
	GrType type;
	uint index;
	bool isGlobal, isInitialized, isAuto;
    dstring name;
}

class GrStructure {
    GrType[] signature;
    dstring[] fields;
}
GrStructure[dstring] structures;

GrType grType_addStructure(dstring name, dstring[] fields, GrType[] signature) {
    if(fields.length != signature.length)
        throw new Exception("GrStructure signature mismatch");
    GrStructure st = new GrStructure;
    st.signature = signature;
    st.fields = fields;
    structures[name] = st;

    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

bool grType_isStructure(dstring name) {
    if(name in structures)
        return true;
    return false;
}

GrStructure grType_getStructure(dstring name) {
    auto structure = (name in structures);
    if(structure is null)
        throw new Exception("Undefined struct \'" ~ to!string(name) ~ "\'");
    return *structure;
}

void grType_resolveStructSignature() {
    foreach(structure; structures) {
        for(int i; i < structure.signature.length; i ++) {
            if(structure.signature[i].baseType == GrBaseType.VoidType) {
                if(grType_isStructure(structure.signature[i].mangledType)) {
                    structure.signature[i].baseType = GrBaseType.StructType;
                }
                else
                    throw new Exception("Cannot resolve def field");
            }
        }
    }
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
	GrType[] signature;
	GrType returnType;
	bool isTask, isAnonymous;

	GrFunctionCall[] functionCalls;
	GrFunction anonParent;
	uint position, anonReference, anonIndex, localVariableIndex;

	uint nbIntegerParameters, nbFloatParameters, nbStringParameters,
		nbArrayParameters, nbAnyParameters, nbObjectParameters;
}

class GrFunctionCall {
	dstring mangledName;
	uint position;
	GrFunction caller, functionToCall;
	GrType expectedType;
    bool isAddress;
}
