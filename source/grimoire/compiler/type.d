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

enum GrBaseType {
    VoidType, IntType, FloatType, BoolType, StringType,
    ArrayType, VariantType, FunctionType, TaskType,
    StructType, TupleType, UserType, ChanType,
    InternalTupleType
}

struct GrType {
    GrBaseType baseType;
    dstring mangledType, mangledReturnType;
    bool isField;

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
const GrType grVariant = GrType(GrBaseType.VariantType);


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

class GrVariable {
	GrType type;
	uint index;
	bool isGlobal, isField, isInitialized, isAuto, isConstant;
    dstring name;
}

/// Primitive global constants, call registerIntConstant at the start of the parser.
GrType grAddIntConstant(dstring name, int value) {
    if(value + 1 > value)
        throw new Exception("TODO: Implement later");
    return grVoid;
}

dstring[] usertypes;
GrType grAddUserType(dstring name) {
    bool isDeclared;
    foreach(usertype; usertypes) {
        if(usertype == name)
            isDeclared = true;
    }

    if(!isDeclared)
        usertypes ~= name;

    GrType type = GrBaseType.UserType;
    type.mangledType = name;
    return type;
}

bool grIsUserType(dstring name) {
    foreach(usertype; usertypes) {
        if(usertype == name)
            return true;
    }
    return false;
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
GrTuple[dstring] tuples;

GrType grAddTuple(dstring name, dstring[] fields, GrType[] signature) {
    if(fields.length != signature.length)
        throw new Exception("GrTuple signature mismatch");
    GrTuple st = new GrTuple;
    st.signature = signature;
    st.fields = fields;
    tuples[name] = st;

    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}

bool grIsTuple(dstring name) {
    if(name in tuples)
        return true;
    return false;
}

GrType grGetTupleType(dstring name) {
    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}

GrTuple grGetTuple(dstring name) {
    auto tuple = (name in tuples);
    if(tuple is null)
        throw new Exception("Undefined tuple \'" ~ to!string(name) ~ "\'");
    return *tuple;
}

void grResolveTupleSignature() {
    foreach(tuple; tuples) {
        for(int i; i < tuple.signature.length; i ++) {
            if(tuple.signature[i].baseType == GrBaseType.VoidType) {
                if(grIsTuple(tuple.signature[i].mangledType)) {
                    tuple.signature[i].baseType = GrBaseType.TupleType;
                }
                else
                    throw new Exception("Cannot resolve tuple field");
            }
        }
    }
}

class GrStruct {
    GrType[] signature;
    dstring[] fields;
}
GrStruct[dstring] structures;

GrType grAddStruct(dstring name, dstring[] fields, GrType[] signature) {
    if(fields.length != signature.length)
        throw new Exception("GrStruct signature mismatch");
    GrStruct st = new GrStruct;
    st.signature = signature;
    st.fields = fields;
    structures[name] = st;

    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

bool grIsStruct(dstring name) {
    if(name in structures)
        return true;
    return false;
}

GrType grGetStructType(dstring name) {
    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

GrStruct grGetStruct(dstring name) {
    auto structure = (name in structures);
    if(structure is null)
        throw new Exception("Undefined structure \'" ~ to!string(name) ~ "\'");
    return *structure;
}

void grResolveStructSignature() {
    foreach(structure; structures) {
        for(int i; i < structure.signature.length; i ++) {
            if(structure.signature[i].baseType == GrBaseType.VoidType) {
                if(grIsStruct(structure.signature[i].mangledType)) {
                    structure.signature[i].baseType = GrBaseType.StructType;
                }
                else
                    throw new Exception("Cannot resolve structure field");
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
	GrType[] inSignature, outSignature;
	bool isTask, isAnonymous;

	GrFunctionCall[] functionCalls;
	GrFunction anonParent;
	uint position, anonReference, localVariableIndex;

	uint nbIntegerParameters, nbFloatParameters, nbStringParameters,
        nbVariantParameters, nbUserDataParameters;

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