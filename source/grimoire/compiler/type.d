/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
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
    void_, null_, int_, float_, bool_, string_,
    array_, function_, task,
    class_, foreign, chan, enum_,
    internalTuple,
    reference, 
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
    string mangledType, mangledReturnType;
    /// Is this from an object field ?
    bool isField;

    /// Init as a basic type.
    this(GrBaseType baseType_) {
        baseType = baseType_;
    }

    /// Compound type.
    this(GrBaseType baseType_, string mangledType_) {
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
        if(baseType == GrBaseType.function_ || baseType == GrBaseType.task)
            return mangledType == v.mangledType && mangledReturnType == v.mangledReturnType;
        if(baseType == GrBaseType.foreign || baseType == GrBaseType.class_ ||
            baseType == GrBaseType.enum_ || baseType == GrBaseType.array_)
            return mangledType == v.mangledType;
        return true;
	}

    /// Only to disable warnings because of opEquals.
	size_t toHash() const @safe pure nothrow {
		return 0;
	}
}

/// No type
const GrType grVoid = GrType(GrBaseType.void_);
/// Integer
const GrType grInt = GrType(GrBaseType.int_);
/// Float
const GrType grFloat = GrType(GrBaseType.float_);
/// Bool
const GrType grBool = GrType(GrBaseType.bool_);
/// String
const GrType grString = GrType(GrBaseType.string_);
/// Int array
const GrType grIntArray = GrType(GrBaseType.array_, grMangleFunction([grInt]));
/// Float array
const GrType grFloatArray = GrType(GrBaseType.array_, grMangleFunction([grFloat]));
/// Bool array
const GrType grBoolArray = GrType(GrBaseType.array_, grMangleFunction([grBool]));
/// String array
const GrType grStringArray = GrType(GrBaseType.array_, grMangleFunction([grString]));
/// Int channel
const GrType grIntChannel = GrType(GrBaseType.chan, grMangleFunction([grInt]));
/// Float channel
const GrType grFloatChannel = GrType(GrBaseType.chan, grMangleFunction([grFloat]));
/// Bool channel
const GrType grBoolChannel = GrType(GrBaseType.chan, grMangleFunction([grBool]));
/// String channel
const GrType grStringChannel = GrType(GrBaseType.chan, grMangleFunction([grString]));

/// Returns an array GrType of `subType` subtype.
GrType grArray(GrType subType) {
    return GrType(GrBaseType.array_, grMangleFunction([subType]));
}

/// Pack multiple types as a single one.
package GrType grPackTuple(GrType[] types) {
    const string mangledName = grMangleFunction(types);
    GrType type = GrBaseType.internalTuple;
    type.mangledType = mangledName;
    return type;
}

/// Unpack multiple types from a single one.
package GrType[] grUnpackTuple(GrType type) {
    if(type.baseType != GrBaseType.internalTuple)
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
    string name;
    /// Is the variable visible from other files ? (Global only)
    bool isPublic;
    /// The file where the variable is declared.
    uint fileId;
}

/// Define an arbitrary D pointer.
final class GrForeignDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherit from.
    string parent;
}

/// Create a foreign GrType for the type system.
GrType grGetForeignType(string name) {
    GrType type = GrBaseType.foreign;
    type.mangledType = name;
    return type;
}

/**
Define the content of a type alias. \
Not to be confused with GrType used by the type system.
---
type MyNewType = AnotherType;
---
*/
final class GrTypeAliasDefinition {
    /// Identifier.
    string name;
    /// The type aliased.
    GrType type;
    /// Is the type visible from other files ?
    bool isPublic;
    /// The file where the type is declared.
    uint fileId;
}

/**
Define the content of an enum. \
Not to be confused with GrType used by the type system.
---
enum MyEnum {
    field1;
    field2;
}
---
*/
final class GrEnumDefinition {
    /// Identifier.
    string name;
    /// List of field names.
    string[] fields;
    /// Unique ID of the enum definition.
    size_t index;
    /// Is the type visible from other files ?
    bool isPublic;
    /// The file where the type is declared.
    uint fileId;

    /// Does the field name exists ?
    bool hasField(string name) const {
        foreach(field; fields) {
            if(field == name)
                return true;
        }
        return false;
    }

    /// Returns the value of the field
    int getField(string name) const {
        import std.conv: to;
        int fieldIndex = 0;
        foreach(field; fields) {
            if(field == name)
                return fieldIndex;
            fieldIndex ++;
        }
        assert(false, "Undefined enum \'" ~ name ~ "\'");
    }
}

/// Create a GrType of enum for the type system.
GrType grGetEnumType(string name) {
    GrType stType = GrBaseType.enum_;
    stType.mangledType = name;
    return stType;
}

/**
Define the content of a class. \
Not to be confused with GrType used by the type system.
---
class MyClass {
    // Fields
}
---
*/
final class GrClassDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherit from.
    string parent;
    /// List of field types.
    GrType[] signature;
    /// List of field names.
    string[] fields;

    package {
        struct FieldInfo {
            bool isPublic;
            uint fileId;
            uint position;
        }

        FieldInfo[] fieldsInfo;

        /// The lexeme that declared it.
        uint position;
    }
    /// Unique ID of the object definition.
    size_t index;
    /// Is the type visible from other files ?
    bool isPublic;
    /// The file where the type is declared.
    uint fileId;
}

/// Create a GrType of class for the type system.
GrType grGetClassType(string name) {
    GrType stType = GrBaseType.class_;
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
package class GrFunction {
    /// Every variable declared within its scope.
	GrVariable[string] localVariables;
    /// All the function instructions.
	GrInstruction[] instructions;
	uint stackSize, index, offset;

    /// Unmangled function name.
	string name;
    /// Mangled function name.
	string mangledName;
    /// Function input parameters' name.
    string[] inputVariables;
    /// Function parameters' type.
	GrType[] inSignature, outSignature;
	bool isTask, isAnonymous, isEvent, isMain;

    /// Function calls made from within its scope.
	GrFunctionCall[] functionCalls;
	GrFunction anonParent;
	uint position, anonReference;

	uint nbIntegerParameters, nbFloatParameters, nbStringParameters, nbObjectParameters;
    uint ilocalsCount, flocalsCount, slocalsCount, olocalsCount;

    GrDeferrableSection[] deferrableSections;
    GrDeferBlock[] registeredDeferBlocks;
    bool[] isDeferrableSectionLocked = [false];

    /// Is the function visible from other files ?
    bool isPublic;
    /// The file where the function is declared.
    uint fileId;

    uint lexPosition;
}

package class GrTemplateFunction {
    /// Unmangled function name.
	string name;
    /// Function input parameters' name.
    string[] inputVariables;
    /// Function parameters' type.
	GrType[] inSignature, outSignature;
	bool isTask;
    /// Is the function visible from other files ?
    bool isPublic;
    /// The file where the template is declared.
    uint fileId;

    string[] templateVariables;

    uint lexPosition;

    GrFunction generate(GrType[] templateList) {
        GrFunction func = new GrFunction;
        func.isTask = isTask;
        func.name = name;
        func.inputVariables = inputVariables;
        func.inSignature = inSignature;
        func.outSignature = outSignature;
        func.fileId = fileId;
        func.isPublic = isPublic;
        func.lexPosition = lexPosition;
        return func;
    }
}

package class GrFunctionCall {
	string name;
    GrType[] signature;
	uint position;
	GrFunction caller, functionToCall;
	GrType expectedType;
    bool isAddress;
    uint fileId;
}

package class GrDeferrableSection {
    GrDeferBlock[] deferredBlocks;
    uint deferInitPositions;
    uint[] deferredCalls;
}

package class GrDeferBlock {
    uint position;
    uint parsePosition;
    uint scopeLevel;
}