/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.library;

import std.traits;
import std.conv : to;
import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.pretty;
import grimoire.compiler.util;

interface GrLibDefinition {
    /// Type of operator overloading
    enum Operator {
        plus,
        minus,
        add,
        substract,
        multiply,
        divide,
        concatenate,
        remainder,
        power,
        equal,
        doubleEqual,
        threeWayComparison,
        notEqual,
        greaterOrEqual,
        greater,
        lesserOrEqual,
        lesser,
        leftShift,
        rightShift,
        interval,
        arrow,
        bitwiseAnd,
        bitwiseOr,
        bitwiseXor,
        bitwiseNot,
        and,
        or,
        not,
    }

    void setModule(string[]);
    void setDescription(GrLocale, string = "");
    void setParameters(GrLocale, string[] = []);
    void setModuleInfo(GrLocale, string);
    void setModuleDescription(GrLocale, string);
    void addVariable(string, GrType);
    void addVariable(string, GrType, GrValue);
    GrType addEnum(string, string[]);
    GrType addClass(string, string[], GrType[], string[] = [], string = "", GrType[] = [
        ]);
    GrType addAlias(string, GrType);
    GrType addNative(string, string[] = [], string = "", GrType[] = []);
    GrPrimitive addFunction(GrCallback, string, GrType[] = [], GrType[] = [], GrConstraint[] = [
        ]);
    GrPrimitive addOperator(GrCallback, Operator operator, GrType[],
        GrType outType, GrConstraint[] = []);
    GrPrimitive addOperator(GrCallback, string, GrType[], GrType outType, GrConstraint[] = [
        ]);
    GrPrimitive addCast(GrCallback, GrType, GrType, bool = false, GrConstraint[] = [
        ]);
    GrPrimitive addConstructor(GrCallback, GrType, GrType[] = [], GrConstraint[] = [
        ]);
    GrPrimitive[] addProperty(GrCallback, GrCallback, string, GrType, GrType, GrConstraint[] = [
        ]);
}

/**
Contains type information and D linked functions.
*/
final class GrLibrary : GrLibDefinition {
    package(grimoire) {
        /// Opaque pointer types. \
        /// They're pointer only defined by a name. \
        /// Can only be used with primitives.
        GrAbstractNativeDefinition[] _abstractNativeDefinitions;
        /// Type aliases
        GrTypeAliasDefinition[] _aliasDefinitions;
        /// Enum types.
        GrEnumDefinition[] _enumDefinitions;
        /// Object types.
        GrClassDefinition[] _abstractClassDefinitions;
        /// Variable types
        GrVariableDefinition[] _variableDefinitions;

        /// All primitives, used for both the compiler and the runtime.
        GrPrimitive[] _abstractPrimitives;

        /// All the primitive callbacks.
        GrCallback[] _callbacks;

        /// Name aliases
        string[string] _aliases;
    }

    override void setModule(string[]) {
    }

    override void setDescription(GrLocale, string = "") {
    }

    override void setParameters(GrLocale, string[] = []) {
    }

    override void setModuleInfo(GrLocale, string) {
    }

    override void setModuleDescription(GrLocale, string) {
    }

    /// Define a variable
    override void addVariable(string name, GrType type) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;
        _variableDefinitions ~= variable;
    }

    /// Define a variable with a default value
    override void addVariable(string name, GrType type, GrValue defaultValue) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;

        final switch (type.base) with (GrType.Base) {
        case bool_:
            variable.ivalue = defaultValue.getBool();
            break;
        case int_:
        case enum_:
            variable.ivalue = defaultValue.getInt();
            break;
        case real_:
            variable.rvalue = defaultValue.getReal();
            break;
        case string_:
            variable.svalue = defaultValue.getString();
            break;
        case optional:
        case class_:
        case channel:
        case function_:
        case task:
        case list:
        case native:
        case void_:
        case null_:
        case internalTuple:
        case reference:
            throw new Exception(
                "can't initialize library variable of type `" ~ grGetPrettyType(type) ~ "`");
        }

        variable.isInitialized = true;
        _variableDefinitions ~= variable;
    }

    /// Define an enum
    override GrType addEnum(string name, string[] fields) {
        GrEnumDefinition enum_ = new GrEnumDefinition;
        enum_.name = name;
        enum_.fields = fields;
        enum_.isPublic = true;
        _enumDefinitions ~= enum_;

        GrType type = GrType.Base.enum_;
        type.mangledType = name;
        return type;
    }

    /// Define a class type.
    override GrType addClass(string name, string[] fields, GrType[] signature,
        string[] templateVariables = [], string parent = "", GrType[] parentTemplateSignature = [
        ]) {
        if (fields.length != signature.length)
            throw new Exception("class signature mismatch");
        GrClassDefinition class_ = new GrClassDefinition;
        class_.name = name;
        class_.parent = parent;
        class_.signature = signature;
        class_.fields = fields;
        class_.templateVariables = templateVariables;
        class_.parentTemplateSignature = parentTemplateSignature;
        class_.isPublic = true;
        class_.isParsed = true;
        _abstractClassDefinitions ~= class_;

        class_.fieldsInfo.length = fields.length;
        for (int i; i < class_.fieldsInfo.length; ++i) {
            class_.fieldsInfo[i].fileId = 0;
            class_.fieldsInfo[i].isPublic = true;
            class_.fieldsInfo[i].position = 0;
        }

        GrType type = GrType.Base.class_;
        GrType[] anySignature;
        foreach (tmp; templateVariables) {
            anySignature ~= grAny(tmp);
        }
        type.mangledType = grMangleComposite(name, anySignature);
        return type;
    }

    /// Define a type alias
    override GrType addAlias(string name, GrType type) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.isPublic = true;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Define an opaque pointer type.
    override GrType addNative(string name, string[] templateVariables = [],
        string parent = "", GrType[] parentTemplateSignature = []) {
        if (name == parent)
            throw new Exception("`" ~ name ~ "` can't be its own parent");
        GrAbstractNativeDefinition native = new GrAbstractNativeDefinition;
        native.name = name;
        native.templateVariables = templateVariables;
        native.parent = parent;
        native.parentTemplateSignature = parentTemplateSignature;
        _abstractNativeDefinitions ~= native;

        GrType type = GrType.Base.native;
        GrType[] anySignature;
        foreach (tmp; templateVariables) {
            anySignature ~= grAny(tmp);
        }
        type.mangledType = grMangleComposite(name, anySignature);
        return type;
    }

    /// Define a new primitive.
    override GrPrimitive addFunction(GrCallback callback, string name,
        GrType[] inSignature = [], GrType[] outSignature = [], GrConstraint[] constraints = [
        ]) {
        bool isAbstract;
        foreach (GrType type; inSignature) {
            if (type.isAbstract)
                throw new Exception("`" ~ grGetPrettyFunction(name, inSignature,
                        outSignature) ~ "` can't use type `" ~ grGetPrettyType(
                        type) ~ "` as it is abstract");
            if (type.isAny) {
                isAbstract = true;
                break;
            }
        }
        foreach (GrType type; outSignature) {
            if (type.isAbstract)
                throw new Exception("`" ~ grGetPrettyFunction(name, inSignature,
                        outSignature) ~ "` can't use type `" ~ grGetPrettyType(
                        type) ~ "` as it is abstract");
        }

        GrPrimitive primitive = new GrPrimitive;
        primitive.inSignature = inSignature;
        primitive.outSignature = outSignature;
        primitive.name = name;
        primitive.callbackId = cast(int) _callbacks.length;
        primitive.constraints = constraints;

        _callbacks ~= callback;

        _abstractPrimitives ~= primitive;
        return primitive;
    }

    /**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
    */
    override GrPrimitive addOperator(GrCallback callback, Operator operator,
        GrType[] inSignature, GrType outType, GrConstraint[] constraints = []) {
        string name;
        uint signatureSize = 2;
        final switch (operator) with (Operator) {
        case plus:
            name = "+";
            signatureSize = 1;
            break;
        case minus:
            name = "-";
            signatureSize = 1;
            break;
        case add:
            name = "+";
            break;
        case substract:
            name = "-";
            break;
        case multiply:
            name = "*";
            break;
        case divide:
            name = "/";
            break;
        case concatenate:
            name = "~";
            break;
        case remainder:
            name = "%";
            break;
        case power:
            name = "**";
            break;
        case equal:
            name = "==";
            break;
        case doubleEqual:
            name = "===";
            break;
        case threeWayComparison:
            name = "<=>";
            break;
        case notEqual:
            name = "!=";
            break;
        case greaterOrEqual:
            name = ">=";
            break;
        case greater:
            name = ">";
            break;
        case lesserOrEqual:
            name = "<=";
            break;
        case lesser:
            name = "<";
            break;
        case leftShift:
            name = "<<";
            break;
        case rightShift:
            name = ">>";
            break;
        case interval:
            name = "->";
            break;
        case arrow:
            name = "=>";
            break;
        case bitwiseAnd:
            name = "&";
            break;
        case bitwiseOr:
            name = "|";
            break;
        case bitwiseXor:
            name = "^";
            break;
        case bitwiseNot:
            name = "~";
            signatureSize = 1;
            break;
        case and:
            name = "&&";
            break;
        case or:
            name = "||";
            break;
        case not:
            name = "!";
            signatureSize = 1;
            break;
        }
        if (inSignature.length != signatureSize)
            throw new Exception("The operator `" ~ name ~ "` must take " ~ to!string(
                    signatureSize) ~ " parameter" ~ (signatureSize > 1 ?
                    "s" : "") ~ ": " ~ grGetPrettyFunctionCall("", inSignature));
        return addOperator(callback, name, inSignature, outType, constraints);
    }
    /// Ditto
    override GrPrimitive addOperator(GrCallback callback, string name,
        GrType[] inSignature, GrType outType, GrConstraint[] constraints = []) {
        if (inSignature.length > 2uL)
            throw new Exception(
                "The operator `" ~ name ~ "` cannot take more than 2 parameters: " ~ grGetPrettyFunctionCall("",
                    inSignature));
        return addFunction(callback, "@operator_" ~ name, inSignature, [outType], constraints);
    }

    /**
    A cast operator allows to convert from one type to another.
    It must have only one parameter and return the casted value.
    */
    override GrPrimitive addCast(GrCallback callback, GrType srcType,
        GrType dstType, bool isExplicit = false, GrConstraint[] constraints = []) {
        auto primitive = addFunction(callback, "@as", [srcType, dstType], [
                dstType
            ], constraints);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    /**
    Define a function that will be called with the `new` operation.
    It must return the defined type.
    */
    override GrPrimitive addConstructor(GrCallback callback, GrType newType,
        GrType[] inSignature = [], GrConstraint[] constraints = []) {
        auto primitive = addFunction(callback, "@new", inSignature ~ [newType],
            [newType], constraints);
        return primitive;
    }

    /**
    Define functions that access and modify a native’s property.
    */
    override GrPrimitive[] addProperty(GrCallback getCallback, GrCallback setCallback,
        string name, GrType nativeType, GrType propertyType, GrConstraint[] constraints = [
        ]) {
        GrPrimitive[] primitives;
        /*assert(callbacks.length <= operations.length,
            "the number of callbacks of the property `" ~ name ~
                "` of the type `" ~ grGetPrettyType(
                    nativeType) ~ "` exceed the number of operations");*/

        if (getCallback) {
            primitives ~= addFunction(getCallback, name ~ "@get", [nativeType],
                [propertyType], constraints);
        }
        if (setCallback) {
            primitives ~= addFunction(setCallback, name ~ "@set", [
                    nativeType, propertyType
                ], [propertyType], constraints);
        }
        return primitives;
    }

    private string getPrettyPrimitive(GrPrimitive primitive) {
        import std.conv : to;

        auto nbParameters = primitive.inSignature.length;
        string result;
        if (primitive.name == "@new") {
            result ~= "new ";
            if (nbParameters > 0) {
                result ~= grGetPrettyType(primitive.inSignature[$ - 1]);
                nbParameters--;
            }
        }
        else if (primitive.name == "@as") {
            result ~= "as";
            nbParameters = 1;
        }
        else {
            result ~= primitive.name;
        }
        result ~= "(";
        for (int i; i < nbParameters; i++) {
            result ~= grGetPrettyType(primitive.inSignature[i]);
            if ((i + 2) <= nbParameters)
                result ~= ", ";
        }
        result ~= ")";
        for (int i; i < primitive.outSignature.length; i++) {
            result ~= i ? ", " : " ";
            result ~= grGetPrettyType(primitive.outSignature[i]);
        }
        return result;
    }
}
