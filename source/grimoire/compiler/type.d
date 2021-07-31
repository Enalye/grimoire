/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.type;

import std.conv : to;

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
    void_,
    null_,
    int_,
    float_,
    bool_,
    string_,
    array_,
    function_,
    task,
    class_,
    foreign,
    chan,
    enum_,
    internalTuple,
    reference
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
    /// Can this type match with others ?
    bool isAny;
    /// Predicate to validate any type
    bool function(GrType, GrAnyData) predicate;

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
        if (baseType != v.baseType)
            return false;
        if (baseType == GrBaseType.function_ || baseType == GrBaseType.task)
            return mangledType == v.mangledType && mangledReturnType == v.mangledReturnType;
        if (baseType == GrBaseType.foreign || baseType == GrBaseType.class_
                || baseType == GrBaseType.enum_ || baseType == GrBaseType.array_)
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
const GrType grIntArray = GrType(GrBaseType.array_, grMangleSignature([grInt]));
/// Float array
const GrType grFloatArray = GrType(GrBaseType.array_, grMangleSignature([
            grFloat
        ]));
/// Bool array
const GrType grBoolArray = GrType(GrBaseType.array_, grMangleSignature([grBool]));
/// String array
const GrType grStringArray = GrType(GrBaseType.array_, grMangleSignature([
            grString
        ]));
/// Int channel
const GrType grIntChannel = GrType(GrBaseType.chan, grMangleSignature([grInt]));
/// Float channel
const GrType grFloatChannel = GrType(GrBaseType.chan, grMangleSignature([
            grFloat
        ]));
/// Bool channel
const GrType grBoolChannel = GrType(GrBaseType.chan, grMangleSignature([grBool]));
/// String channel
const GrType grStringChannel = GrType(GrBaseType.chan, grMangleSignature([
            grString
        ]));

/// Returns an array GrType of `subType` subtype.
GrType grArray(GrType subType) {
    return GrType(GrBaseType.array_, grMangleSignature([subType]));
}

/// Returns a channel GrType of `subType` subtype.
GrType grChannel(GrType subType) {
    return GrType(GrBaseType.chan, grMangleSignature([subType]));
}

/// Special type the matches another type with a predicate.
GrType grAny(string name, bool function(GrType, GrAnyData) predicate = (a, b) => true) {
    GrType type;
    type.baseType = GrBaseType.void_;
    type.mangledType = name;
    type.isAny = true;
    type.predicate = predicate;
    return type;
}

/// The type is handled by a int based register
bool grIsKindOfInt(GrBaseType type) {
    return type == GrBaseType.int_ || type == GrBaseType.bool_
        || type == GrBaseType.function_ || type == GrBaseType.task || type == GrBaseType.enum_;
}

/// The type is handled by a float based register
bool grIsKindOfFloat(GrBaseType type) {
    return type == GrBaseType.float_;
}

/// The type is handled by a string based register
bool grIsKindOfString(GrBaseType type) {
    return type == GrBaseType.string_;
}

/// The type is handled by a ptr based register
bool grIsKindOfObject(GrBaseType type) {
    return type == GrBaseType.class_ || type == GrBaseType.array_ || type == GrBaseType.foreign
        || type == GrBaseType.chan || type == GrBaseType.reference || type == GrBaseType.null_;
}

/// Context for any validation
final class GrAnyData {
    private {
        GrType[string] _types;
    }

    /// Clear any stored type definition
    void clear() {
        _types.clear;
    }

    /// Define a new type
    void set(string key, GrType type) {
        _types[key] = type;
    }

    /// Fetch an already defined type
    GrType get(string key) {
        return _types.get(key, grVoid);
    }
}

/// Pack multiple types as a single one.
package GrType grPackTuple(GrType[] types) {
    const string mangledName = grMangleSignature(types);
    GrType type = GrBaseType.internalTuple;
    type.mangledType = mangledName;
    return type;
}

/// Unpack multiple types from a single one.
package GrType[] grUnpackTuple(GrType type) {
    if (type.baseType != GrBaseType.internalTuple)
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
    /// Position information in case of errors.
    uint lexPosition;
}

/// Define an arbitrary D pointer.
final class GrForeignDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherit from.
    string parent;
}

/// Ditto
final class GrAbstractForeignDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherits from.
    string parent;
    /// Template values
    string[] templateVariables;
    /// Template signature
    GrType[] parentTemplateSignature;
}

/// Create a foreign GrType for the type system.
GrType grGetForeignType(string name, GrType[] signature = []) {
    GrType type = GrBaseType.foreign;
    type.mangledType = grMangleComposite(name, signature);
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
        foreach (field; fields) {
            if (field == name)
                return true;
        }
        return false;
    }

    /// Returns the value of the field
    int getField(string name) const {
        import std.conv : to;

        int fieldIndex = 0;
        foreach (field; fields) {
            if (field == name)
                return fieldIndex;
            fieldIndex++;
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
    /// List of template variables.
    string[] templateVariables;
    /// List of template types.
    GrType[] templateTypes, parentTemplateSignature;

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
    /// Is the declaration of the class already parsed ?
    bool isParsed;
}

/// Create a GrType of class for the type system.
GrType grGetClassType(string name, GrType[] signature = []) {
    GrType stType = GrBaseType.class_;
    stType.mangledType = grMangleComposite(name, signature);
    return stType;
}

/// Define a variable defined from a library
final class GrVariableDefinition {
    /// Identifier.
    string name;
    /// Its type
    GrType type;
    /// Does the variable use a custom initialization value ?
    bool isInitialized;
    /// Integral init value
    int ivalue;
    /// Floating init value
    float fvalue;
    /// String init value
    string svalue;
    /// Can the variable be mutated in script ?
    bool isConstant;
    /// Register.
    uint register;
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
    string[] inputVariables, templateVariables;
    /// Function parameters' type.
    GrType[] inSignature, outSignature, templateSignature;
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

/// Get the type of the function.
GrType grGetFunctionAsType(GrFunction func) {
    GrType type = func.isTask ? GrBaseType.task : GrBaseType.function_;
    type.mangledType = grMangleSignature(func.inSignature);
    type.mangledReturnType = grMangleSignature(func.outSignature);
    return type;
}

package class GrTemplateFunction {
    /// Unmangled function name.
    string name;
    /// Function input parameters' name.
    string[] inputVariables;
    /// Function parameters' type.
    GrType[] inSignature, outSignature;
    bool isTask;
    bool isConversion;
    /// Is the function visible from other files ?
    bool isPublic;
    /// The file where the template is declared.
    uint fileId;

    string[] templateVariables;

    uint lexPosition;
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
