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
import grimoire.compiler.mangle;
import grimoire.compiler.pretty;

/**
Contains type information and D linked functions.
*/
class GrLibrary {
    package(grimoire) {
        /// Opaque pointer types. \
        /// They're pointer only defined by a name. \
        /// Can only be used with primitives.
        GrAbstractForeignDefinition[] _abstractForeignDefinitions;
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

    void addAlias(string name, string alias_) {
        _aliases[name] = alias_;
    }

    /// Define a variable
    void addVariable(string name, GrType type, bool isConstant) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;
        variable.isConstant = isConstant;
        _variableDefinitions ~= variable;
    }

    /// Define a variable with a default value
    void addVariable(T)(string name, GrType type, T defaultValue, bool isConstant) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;
        variable.isConstant = isConstant;

        final switch (type.base) with (GrType.Base) {
        case bool_:
        case int_:
        case enum_:
        case float_:
        case string_:
            break;
        case class_:
        case channel:
        case function_:
        case task:
        case list_:
        case foreign:
        case void_:
        case null_:
        case internalTuple:
        case reference:
            throw new Exception(
                    "can't initialize library variable of type `" ~ grGetPrettyType(type) ~ "`");
        }
        static if (isIntegral!T) {
            if (type.base != GrType.Base.int_ && type.base != GrType.Base.enum_)
                throw new Exception(
                        "the default value of `" ~ name ~ "` doesn't match the type of  `" ~ grGetPrettyType(
                        type) ~ "`");
            variable.ivalue = cast(int) defaultValue;
        }
        else static if (is(T == bool)) {
            if (type.base != GrType.Base.bool_)
                throw new Exception(
                        "the default value of `" ~ name ~ "` doesn't match the type of  `" ~ grGetPrettyType(
                        type) ~ "`");
            variable.ivalue = defaultValue ? 1 : 0;
        }
        else static if (isFloatingPoint!T) {
            if (type.base != GrType.Base.float_)
                throw new Exception(
                        "the default value of `" ~ name ~ "` doesn't match the type of  `" ~ grGetPrettyType(
                        type) ~ "`");
            variable.fvalue = cast(float) defaultValue;
        }
        static if (is(T == string)) {
            if (type.base != GrType.Base.string_)
                throw new Exception(
                        "the default value of `" ~ name ~ "` doesn't match the type of  `" ~ grGetPrettyType(
                        type) ~ "`");
            variable.svalue = defaultValue;
        }
        variable.isInitialized = true;
        _variableDefinitions ~= variable;
    }

    /// Define an enumeration
    GrType addEnum(string name, string[] fields) {
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
    GrType addClass(string name, string[] fields, GrType[] signature,
            string[] templateVariables = [], string parent = "",
            GrType[] parentTemplateSignature = []) {
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
        type.mangledType = name;
        type.isAbstract = class_.templateVariables.length > 0;
        return type;
    }

    /// Define a type alias
    GrType addTypeAlias(string name, GrType type) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.isPublic = true;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Define an opaque pointer type.
    GrType addForeign(string name, string[] templateVariables = [],
            string parent = "", GrType[] parentTemplateSignature = []) {
        if (name == parent)
            throw new Exception("`" ~ name ~ "` can't be its own parent");
        GrAbstractForeignDefinition foreign = new GrAbstractForeignDefinition;
        foreign.name = name;
        foreign.templateVariables = templateVariables;
        foreign.parent = parent;
        foreign.parentTemplateSignature = parentTemplateSignature;
        _abstractForeignDefinitions ~= foreign;

        GrType type = GrType.Base.foreign;
        type.mangledType = name;
        type.isAbstract = foreign.templateVariables.length > 0;
        return type;
    }

    /// Define a new primitive.
    GrPrimitive addPrimitive(GrCallback callback, string name,
            GrType[] inSignature = [], GrType[] outSignature = []) {
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

        _callbacks ~= callback;

        _abstractPrimitives ~= primitive;
        return primitive;
    }

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

    /**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
    */
    GrPrimitive addOperator(GrCallback callback, Operator operator,
            GrType[] inSignature, GrType outType) {
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
                    signatureSize) ~ " parameter" ~ (signatureSize > 1
                    ? "s" : "") ~ ": " ~ grGetPrettyFunctionCall("", inSignature));
        return addOperator(callback, name, inSignature, outType);
    }
    /// Ditto
    GrPrimitive addOperator(GrCallback callback, string name, GrType[] inSignature, GrType outType) {
        if (inSignature.length > 2uL)
            throw new Exception(
                    "The operator `" ~ name ~ "` cannot take more than 2 parameters: " ~ grGetPrettyFunctionCall("",
                    inSignature));
        return addPrimitive(callback, "@op_" ~ name, inSignature, [outType]);
    }

    /**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
    */
    GrPrimitive addCast(GrCallback callback, GrType srcType, GrType dstType, bool isExplicit = false) {
        auto primitive = addPrimitive(callback, "@conv", [srcType, dstType], [
                dstType
                ]);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    private string getPrettyPrimitive(GrPrimitive primitive) {
        import std.conv : to;

        string result = primitive.name;
        auto nbParameters = primitive.inSignature.length;
        if (primitive.name == "@conv")
            nbParameters = 1;
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
