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

class GrTypesDatabase {
    private {
        dstring[] _userTypes;
        GrStruct[dstring] _structures;
        GrTuple[dstring] _tuples;
    }
}

private {
    GrTypesDatabase _typesDatabase;
}

/// Call this before compilation
void grInitTypesDatabase() {
    _typesDatabase = new GrTypesDatabase;
}

/// Don't call this until the end of compilation
void grCloseTypesDatabase() {
    _typesDatabase = null;
}

GrTypesDatabase GrGetTypesDatabase() {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    return _typesDatabase;
}

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

/// Primitive global constants, call registerIntConstant at the start of the parser.
GrType grAddIntConstant(dstring name, int value) {
    if(value + 1 > value)
        throw new Exception("TODO: Implement later");
    return grVoid;
}

GrType grAddUserType(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    bool isDeclared;
    foreach(usertype; _typesDatabase._userTypes) {
        if(usertype == name)
            isDeclared = true;
    }

    if(!isDeclared)
        _typesDatabase._userTypes ~= name;

    GrType type = GrBaseType.UserType;
    type.mangledType = name;
    return type;
}

bool grIsUserType(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    foreach(usertype; _typesDatabase._userTypes) {
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

GrType grAddTuple(dstring name, dstring[] fields, GrType[] signature) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    if(fields.length != signature.length)
        throw new Exception("GrTuple signature mismatch");
    GrTuple st = new GrTuple;
    st.signature = signature;
    st.fields = fields;
    _typesDatabase._tuples[name] = st;

    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}

bool grIsTuple(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    if(name in _typesDatabase._tuples)
        return true;
    return false;
}

GrType grGetTupleType(dstring name) {
    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}

GrTuple grGetTuple(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    auto tuple = (name in _typesDatabase._tuples);
    if(tuple is null)
        throw new Exception("Undefined tuple \'" ~ to!string(name) ~ "\'");
    return *tuple;
}

void grResolveTupleSignature() {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    foreach(tuple; _typesDatabase._tuples) {
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

GrType grAddStruct(dstring name, dstring[] fields, GrType[] signature) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    if(fields.length != signature.length)
        throw new Exception("GrStruct signature mismatch");
    GrStruct st = new GrStruct;
    st.signature = signature;
    st.fields = fields;
    _typesDatabase._structures[name] = st;

    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

bool grIsStruct(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    if(name in _typesDatabase._structures)
        return true;
    return false;
}

GrType grGetStructType(dstring name) {
    GrType stType = GrBaseType.StructType;
    stType.mangledType = name;
    return stType;
}

GrStruct grGetStruct(dstring name) {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    auto structure = (name in _typesDatabase._structures);
    if(structure is null)
        throw new Exception("Undefined structure \'" ~ to!string(name) ~ "\'");
    return *structure;
}

void grResolveStructSignature() {
    if(!_typesDatabase)
        throw new Exception("Types database not initialized");
    foreach(structure; _typesDatabase._structures) {
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
        nbVariantParameters, nbObjectParameters;

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