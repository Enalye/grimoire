/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.library;

import std.conv : to;
import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.mangle;

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

        /// All primitives, used for both the compiler and the runtime.
        GrPrimitive[] _primitives, _abstractPrimitives;
    }

    /// Define an enumeration
    GrType addEnum(string name, string[] fields) {
        GrEnumDefinition enum_ = new GrEnumDefinition;
        enum_.name = name;
        enum_.fields = fields;
        enum_.isPublic = true;
        _enumDefinitions ~= enum_;

        GrType stType = GrBaseType.enum_;
        stType.mangledType = name;
        return stType;
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

        GrType stType = GrBaseType.class_;
        stType.mangledType = name;
        return stType;
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
        GrType type = GrBaseType.foreign;
        type.mangledType = name;
        return type;
    }

    /// Define a new primitive.
    GrPrimitive addPrimitive(GrCallback callback, string name,
            string[] parameters, GrType[] inSignature, GrType[] outSignature = [
            ]) {
        bool isAbstract;
        foreach (GrType type; inSignature) {
            if (type.isAny) {
                isAbstract = true;
                break;
            }
        }

        GrPrimitive primitive = new GrPrimitive;
        primitive.callback = callback;
        primitive.inSignature = inSignature;
        primitive.parameters = parameters;
        primitive.outSignature = outSignature;
        primitive.name = name;

        if (isAbstract) {
            _abstractPrimitives ~= primitive;
        }
        else {
            foreach (GrType type; outSignature) {
                if (type.isAny)
                    throw new Exception("`" ~ getPrettyPrimitive(primitive,
                            true) ~ "` is not abstract but its return types are");
            }
            primitive.mangledName = grMangleNamedFunction(name, inSignature);
            _primitives ~= primitive;
        }
        return primitive;
    }

    /**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
    */
    GrPrimitive addOperator(GrCallback callback, string name, string[] parameters,
            GrType[] inSignature, GrType outType) {
        import std.conv : to;

        if (inSignature.length > 2uL)
            throw new Exception(
                    "The operator `" ~ name ~ "` cannot take more than 2 parameters: " ~ to!string(
                    parameters));
        return addPrimitive(callback, "@op_" ~ name, parameters, inSignature, [
                outType
                ]);
    }

    /**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
    */
    GrPrimitive addCast(GrCallback callback, string parameter, GrType srcType,
            GrType dstType, bool isExplicit = false) {
        auto primitive = addPrimitive(callback, "@as", [parameter], [
                srcType, dstType
                ], [dstType]);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    private string getPrettyPrimitive(GrPrimitive primitive, bool showParameters = false) {
        import std.conv : to;

        string result = primitive.name;
        auto nbParameters = primitive.inSignature.length;
        if (primitive.name == "@as")
            nbParameters = 1;
        result ~= "(";
        for (int i; i < nbParameters; i++) {
            result ~= grGetPrettyType(primitive.inSignature[i]);
            if (showParameters)
                result ~= " " ~ primitive.parameters[i];
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
