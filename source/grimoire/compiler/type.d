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
import grimoire.compiler.constraint;

/**
Compiler type definition for Grimoire's type system.
It doesn't mean anything for the VM.
*/
struct GrType {
    /**
    Type category.

    Complex types use mangledType and mangledReturnType
    to represent them.
    */
    enum Base {
        void_,
        null_,
        int_,
        float_,
        bool_,
        string_,
        optional,
        list,
        function_,
        task,
        class_,
        native,
        channel,
        enum_,
        internalTuple,
        reference
    }

    /// General type, basic types only use that while compound types also use mangledType
    /// and mangledReturnType.
    Base base;
    /// Used for compound types like lists, functions, etc.
    string mangledType, mangledReturnType;
    /// Is this from an object field ?
    bool isField;
    /// Can this type match with others ?
    bool isAny;
    /// Is the type abstract ?
    /// An abstract type cannot be used in signatures.
    bool isAbstract;
    /// Can we modify its value ?
    bool isConst;
    /// Can we modify the referenced value ?
    bool isPure;

    /// Init as a basic type.
    this(Base base_) {
        base = base_;
    }

    /// Compound type.
    this(Base base_, string mangledType_) {
        base = base_;
        mangledType = mangledType_;
    }

    /// Only assign a simple type (base).
    GrType opOpAssign(string op)(GrType.Base t) {
        mixin("base = base" ~ op ~ "t;");
        return this;
    }

    /// Check general type equality.
    bool opEquals(const GrType.Base v) const {
        return (base == v);
    }

    /// Check full type equality.
    bool opEquals(const GrType v) const {
        if (base != v.base)
            return false;
        if (base == GrType.Base.function_ || base == GrType.Base.task)
            return mangledType == v.mangledType && mangledReturnType == v.mangledReturnType;
        if (base == GrType.Base.native || base == GrType.Base.class_ ||
            base == GrType.Base.enum_ || base == GrType.Base.list)
            return mangledType == v.mangledType;
        return true;
    }

    /// Only to disable warnings because of opEquals.
    size_t toHash() const @safe pure nothrow {
        return 0;
    }
}

/// No type
const GrType grVoid = GrType(GrType.Base.void_);
/// Integer
const GrType grInt = GrType(GrType.Base.int_);
/// Float
const GrType grFloat = GrType(GrType.Base.float_);
/// Bool
const GrType grBool = GrType(GrType.Base.bool_);
/// String
const GrType grString = GrType(GrType.Base.string_);

/// Make an optional version of the type.
GrType grOptional(GrType subType) {
    GrType type = GrType(GrType.Base.optional, grMangleSignature([subType]));
    type.isPure = subType.isPure;
    type.isConst = subType.isConst;
    return type;
}

/// Returns a GrType of type list and of `subType` subtype.
GrType grList(GrType subType) {
    return GrType(GrType.Base.list, grMangleSignature([subType]));
}

/// Returns a GrType of type channel and of `subType` subtype.
GrType grChannel(GrType subType) {
    return GrType(GrType.Base.channel, grMangleSignature([subType]));
}

/// Returns a GrType of type function with given signatures.
GrType grFunction(GrType[] inSignature, GrType[] outSignature = []) {
    GrType type = GrType.Base.function_;
    type.mangledType = grMangleSignature(inSignature);
    type.mangledReturnType = grMangleSignature(outSignature);
    return type;
}

/// Returns a GrType of type task with given signature.
GrType grTask(GrType[] signature) {
    return GrType(GrType.Base.task, grMangleSignature(signature));
}

/// Temporary type for template functions.
GrType grAny(string name) {
    GrType type;
    type.base = GrType.Base.void_;
    type.mangledType = name;
    type.isAny = true;
    return type;
}

/// Make a const version of the type.
GrType grConst(GrType type) {
    type.isConst = true;
    return type;
}

/// Make a pure version of the type.
GrType grPure(GrType type) {
    type.isPure = true;
    return type;
}

/// The type is handled by a int based register
bool grIsKindOfInt(GrType.Base type) {
    return type == GrType.Base.int_ || type == GrType.Base.bool_ ||
        type == GrType.Base.function_ || type == GrType.Base.task || type == GrType.Base.enum_;
}

/// The type is handled by a float based register
bool grIsKindOfFloat(GrType.Base type) {
    return type == GrType.Base.float_;
}

/// The type is handled by a string based register
bool grIsKindOfString(GrType.Base type) {
    return type == GrType.Base.string_;
}

/// The type is handled by a ptr based register
bool grIsKindOfObject(GrType.Base type) {
    return type == GrType.Base.class_ || type == GrType.Base.list ||
        type == GrType.Base.native || type == GrType.Base.channel ||
        type == GrType.Base.reference || type == GrType.Base.null_;
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
    void set(const string key, GrType type) {
        _types[key] = type;
    }

    /// Fetch an already defined type
    GrType get(const string key) const {
        return _types.get(key, grVoid);
    }
}

/// Pack multiple types as a single one.
package GrType grPackTuple(const GrType[] types) {
    const string mangledName = grMangleSignature(types);
    GrType type = GrType.Base.internalTuple;
    type.mangledType = mangledName;
    return type;
}

/// Unpack multiple types from a single one.
package GrType[] grUnpackTuple(GrType type) {
    if (type.base != GrType.Base.internalTuple)
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
    /// Its unique name inside its scope (function based scope).
    string name;
    /// Is the variable visible from other files ? (Global only)
    bool isPublic;
    /// The file where the variable is declared.
    uint fileId;
    /// Position information in case of errors.
    uint lexPosition;
    /// The variable may be null.
    bool isOptional;
    /// Position of the optional instruction.
    uint optionalPosition;
}

/// Define an arbitrary D pointer.
final class GrNativeDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherit from.
    string parent;
}

/// Ditto
final class GrAbstractNativeDefinition {
    /// Identifier.
    string name;
    /// Mother class it inherits from.
    string parent;
    /// Template values
    string[] templateVariables;
    /// Template signature
    GrType[] parentTemplateSignature;
}

/// Create a native GrType for the type system.
GrType grGetNativeType(string name, const GrType[] signature = []) {
    GrType type = GrType.Base.native;
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
    bool hasField(const string name) const {
        foreach (field; fields) {
            if (field == name)
                return true;
        }
        return false;
    }

    /// Returns the value of the field
    int getField(const string name) const {
        import std.conv : to;

        int fieldIndex = 0;
        foreach (field; fields) {
            if (field == name)
                return fieldIndex;
            fieldIndex++;
        }
        assert(false, "undefined enum \'" ~ name ~ "\'");
    }
}

/// Create a GrType of enum for the type system.
GrType grGetEnumType(const string name) {
    GrType stType = GrType.Base.enum_;
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
GrType grGetClassType(const string name, const GrType[] signature = []) {
    GrType type = GrType.Base.class_;
    type.mangledType = grMangleComposite(name, signature);
    return type;
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
    GrInt ivalue;
    /// Floating init value
    GrFloat rvalue;
    /// String init value
    GrStringValue svalue;
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
    /// Local scoping
    struct Scope {
        /// Every variable declared within its scope.
        GrVariable[string] localVariables;
    }
    /// Ditto
    Scope[] scopes;

    uint[] registerAvailables;

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
    bool isTask, isAnonymous, isEvent;

    /// Function calls made from within its scope.
    GrFunctionCall[] functionCalls;
    GrFunction anonParent;
    uint position, anonReference;

    uint nbParameters;
    uint localsCount;

    GrDeferrableSection[] deferrableSections;
    GrDeferBlock[] registeredDeferBlocks;
    bool[] isDeferrableSectionLocked = [false];

    /// Is the function visible from other files ?
    bool isPublic;
    /// The file where the function is declared.
    uint fileId;

    uint lexPosition;

    struct DebugPositionSymbol {
        uint line, column;
    }

    DebugPositionSymbol[] debugSymbol;

    this() {
        scopes.length = 1;
    }

    GrVariable getLocal(string name) {
        foreach_reverse (ref Scope scope_; scopes) {
            //Check if declared locally.
            GrVariable* variable = (name in scope_.localVariables);
            if (variable !is null)
                return *variable;
        }
        return null;
    }

    void setLocal(GrVariable variable_) {
        GrVariable* oldVariable = (variable_.name in scopes[$ - 1].localVariables);
        if (oldVariable !is null) {
            freeRegister(*oldVariable);
        }
        scopes[$ - 1].localVariables[variable_.name] = variable_;
    }

    void openScope() {
        scopes.length++;
    }

    void closeScope() {
        foreach (GrVariable variable; scopes[$ - 1].localVariables) {
            freeRegister(variable);
        }
        scopes.length--;
    }

    private void freeRegister(const GrVariable variable) {
        final switch (variable.type.base) with (GrType.Base) {
        case int_:
        case bool_:
        case function_:
        case task:
        case enum_:
        case float_:
        case string_:
        case list:
        case optional:
        case class_:
        case native:
        case channel:
            registerAvailables ~= variable.register;
            break;
        case internalTuple:
        case reference:
        case null_:
        case void_:
            break;
        }
    }
}

/// Get the type of the function.
GrType grGetFunctionAsType(const GrFunction func) {
    GrType type = func.isTask ? GrType.Base.task : GrType.Base.function_;
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

    GrConstraint[] constraints;

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
