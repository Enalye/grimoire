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
    ObjectType, TupleType, UserType, ChanType,
    InternalTupleType,
    ReferenceType, 
}

/**
Compiler type definition for Grimoire's type system.
It doesn't mean anything for the VM.
*/
struct GrType {
    /// General type, basic types only use that while compound types also use mangledType
    /// and mangledReturnType.
    GrBaseType baseType;
    /// Used for compound types like arrays, functions, etc.
    dstring mangledType, mangledReturnType;
    /// Is this from an object field ?
    bool isField;

    /// Init as a basic type.
    this(GrBaseType baseType_) {
        baseType = baseType_;
    }

    /// Compound type.
    this(GrBaseType baseType_, dstring mangledType_) {
        baseType = baseType_;
        mangledType = mangledType_;
    }

    /// Only assign a simple type (baseType).
    GrType opOpAssign(string op)(GrBaseType t) {
		mixin("baseType = baseType" ~ op ~ "t;");
		return this;
	}

    /// Check general type equality.
    bool opEquals(const GrBaseType v) const {
		return (baseType == v);
	}
    
    /// Check full type equality.
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

/// Pack multiple types as a single one.
package GrType grPackTuple(GrType[] types) {
    const dstring mangledName = grMangleFunction(types);
    GrType type = GrBaseType.InternalTupleType;
    type.mangledType = mangledName;
    return type;
}

/// Unpack multiple types from a single one.
package GrType[] grUnpackTuple(GrType type) {
    if(type.baseType != GrBaseType.InternalTupleType)
        throw new Exception("Cannot unpack a not tuple type.");
    return grUnmangleSignature(type.mangledType);
}

/**
A local or global variable.
*/
package class GrVariable {
    /// Its type.
	GrType type;
    /// Register position, separate for each type (int, float, string and objects);
    uint register = uint.max;
    /// Declared from the global scope ?
	bool isGlobal;
    /// Declared from an object definition ?
    bool isField;
    /// Does it have a value yet ?
    bool isInitialized;
    /// Is the type to be infered automatically ? (e.g. the `let` keyword).
    bool isAuto;
    /// Can we modify its value ?
    bool isConstant;
    /// Its unique name inside its scope (function based scope).
    dstring name;
}

/// Create a GrType of UserType for the type system.
GrType grGetUserType(dstring name) {
    GrType type = GrBaseType.UserType;
    type.mangledType = name;
    return type;
}

/**
Define the content of a tuple. \
Not to be confused with GrType used by the type system.
*/
class GrTupleDefinition {
    /// List of field types.
    GrType[] signature;
    /// List of field names.
    dstring[] fields;
}

/// Create a GrType of TupleType for the type system.
GrType grGetTupleType(dstring name) {
    GrType stType = GrBaseType.TupleType;
    stType.mangledType = name;
    return stType;
}

/**
Define the content of an object. \
Not to be confused with GrType used by the type system.
---
object MyObject {
    // Fields
}
---
*/
class GrObjectDefinition {
    /// Identifier.
    dstring name;
    /// List of field types.
    GrType[] signature;
    /// List of field names.
    dstring[] fields;
    /// Unique ID of the object definition.
    size_t index;
}

/// Create a GrType of ObjectType for the type system.
GrType grGetObjectType(dstring name) {
    GrType stType = GrBaseType.ObjectType;
    stType.mangledType = name;
    return stType;
}

/// A single instruction used by the VM.
struct GrInstruction {
    /// What needs to be done.
	GrOpcode opcode;
    /// Payload, may not be used.
	uint value;
}

/**
Function/Task/Event definition.
*/
class GrFunction {
    /// Every variable declared within its scope.
	GrVariable[dstring] localVariables;
    /// All the function instructions.
	GrInstruction[] instructions;
	uint stackSize, index, offset;

    /// Unmangled function name.
	dstring name;
    /// Function parameters' type.
	GrType[] inSignature, outSignature;
	bool isTask, isAnonymous;

    /// Function calls made from within its scope.
	GrFunctionCall[] functionCalls;
	GrFunction anonParent;
	uint position, anonReference;

	uint nbIntegerParameters, nbFloatParameters, nbStringParameters, nbObjectParameters;
    uint ilocalsCount, flocalsCount, slocalsCount, olocalsCount;

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