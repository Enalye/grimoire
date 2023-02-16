/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.library;

import std.traits;
import std.conv : to;
import std.exception : enforce;
import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.pretty;
import grimoire.compiler.util;

/**
Renseigne les types et primitives de la bibliothèque. \
* Utilisez `GrLibrary` pour la compilation et l’exécution.
* Utilisez `GrDoc` pour la documentation.
*/
interface GrLibDefinition {
    /// Type d’opérateur à surcharger
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
    GrType addVariable(string, GrType);
    GrType addVariable(string, GrType, GrValue, bool = false);
    GrType addEnum(string, string[], int[] = []);
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
    GrPrimitive addStatic(GrCallback, GrType, string, GrType[] = [],
        GrType[] = [], GrConstraint[] = []);
    GrPrimitive[] addProperty(GrCallback, GrCallback, string, GrType, GrType, GrConstraint[] = [
        ]);
}

/// Fonction renseignant une bibliothèque
alias GrLibLoader = void function(GrLibDefinition);

/// Contient les informations de types et les fonctions en D liées
final class GrLibrary : GrLibDefinition {
    package(grimoire) {
        /// Types de pointeurs opaques. \
        /// Ils ne sont utilisables que par des primitives.
        GrAbstractNativeDefinition[] _abstractNativeDefinitions;
        /// Alias de type.
        GrTypeAliasDefinition[] _aliasDefinitions;
        /// Types d’énumérations.
        GrEnumDefinition[] _enumDefinitions;
        /// Types de classes.
        GrClassDefinition[] _abstractClassDefinitions;
        /// Définitions de variables globales.
        GrVariableDefinition[] _variableDefinitions;

        /// Les primitives.
        GrPrimitive[] _abstractPrimitives;

        /// Les pointeurs de fonction liés aux primitives.
        GrCallback[] _callbacks;

        /// Alias de noms.
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

    /// Définit une variable
    override GrType addVariable(string name, GrType type) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;
        _variableDefinitions ~= variable;
        return type;
    }

    /// Définit une variable avec une valeur initiale
    override GrType addVariable(string name, GrType type, GrValue defaultValue, bool isConst = false) {
        GrVariableDefinition variable = new GrVariableDefinition;
        variable.name = name;
        variable.type = type;
        variable.isConst = isConst;

        final switch (type.base) with (GrType.Base) {
        case bool_:
            variable.ivalue = defaultValue.getBool();
            break;
        case int_:
        case enum_:
            variable.ivalue = defaultValue.getInt();
            break;
        case uint_:
            variable.uvalue = defaultValue.getUInt();
            break;
        case float_:
            variable.fvalue = defaultValue.getFloat();
            break;
        case string_:
            variable.svalue = defaultValue.getString();
            break;
        case optional:
        case class_:
        case channel:
        case func:
        case task:
        case event:
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

        return type;
    }

    /// Definit une énumération
    override GrType addEnum(string name, string[] fieldNames, int[] values = []) {
        GrEnumDefinition enum_ = new GrEnumDefinition;
        enum_.name = name;

        int lastValue = -1;
        for (size_t i; i < fieldNames.length; ++i) {
            GrEnumDefinition.Field field;
            field.name = fieldNames[i];

            lastValue = i < values.length ? values[i] : lastValue + 1;
            field.value = lastValue;

            enum_.fields ~= field;
        }

        enum_.isPublic = true;
        _enumDefinitions ~= enum_;

        GrType type = GrType.Base.enum_;
        type.mangledType = name;
        return type;
    }

    /// Definit une classe
    override GrType addClass(string name, string[] fields, GrType[] signature,
        string[] templateVariables = [], string parent = "", GrType[] parentTemplateSignature = [
        ]) {
        enforce(fields.length == signature.length, "class signature mismatch");

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
        class_.fieldConsts.length = fields.length;
        for (int i; i < class_.fieldsInfo.length; ++i) {
            class_.fieldsInfo[i].fileId = 0;
            class_.fieldsInfo[i].isPublic = true;
            class_.fieldsInfo[i].position = 0;
            class_.fieldConsts[i] = false;
        }

        GrType type = GrType.Base.class_;
        GrType[] anySignature;
        foreach (tmp; templateVariables) {
            anySignature ~= grAny(tmp);
        }
        type.mangledType = grMangleComposite(name, anySignature);
        return type;
    }

    /// Definit un alias de type
    override GrType addAlias(string name, GrType type) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.isPublic = true;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Definit un type natif
    override GrType addNative(string name, string[] templateVariables = [],
        string parent = "", GrType[] parentTemplateSignature = []) {
        enforce(name != parent, "`" ~ name ~ "` can't be its own parent");

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

    /// Definit une nouvelle primitive
    override GrPrimitive addFunction(GrCallback callback, string name,
        GrType[] inSignature = [], GrType[] outSignature = [], GrConstraint[] constraints = [
        ]) {
        bool isAbstract;
        foreach (GrType type; inSignature) {
            enforce(!type.isAbstract, "`" ~ grGetPrettyFunction(name, inSignature,
                    outSignature) ~ "` can't use type `" ~ grGetPrettyType(
                    type) ~ "` as it is abstract");

            if (type.isAny) {
                isAbstract = true;
                break;
            }
        }
        foreach (GrType type; outSignature) {
            enforce(!type.isAbstract, "`" ~ grGetPrettyFunction(name, inSignature,
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

    /// Surcharge un opérateur binaire ou untaire tel que `+`, `==`, etc
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

        enforce(inSignature.length == signatureSize,
            "The operator `" ~ name ~ "` must take " ~ to!string(
                signatureSize) ~ " parameter" ~ (signatureSize > 1 ?
                "s" : "") ~ ": " ~ grGetPrettyFunctionCall("", inSignature));

        return addOperator(callback, name, inSignature, outType, constraints);
    }

    /// Ditto
    override GrPrimitive addOperator(GrCallback callback, string name,
        GrType[] inSignature, GrType outType, GrConstraint[] constraints = []) {

        enforce(isOverridableOperator(name),
            "The operator `" ~ name ~ "` is not overridable: " ~ grGetPrettyFunctionCall("",
                inSignature));

        enforce(inSignature.length <= 2,
            "The operator `" ~ name ~ "` cannot take more than 2 parameters: " ~ grGetPrettyFunctionCall("",
                inSignature));

        enforce(inSignature.length > 0,
            "The operator `" ~ name ~ "` is missing parameters: " ~ grGetPrettyFunctionCall("",
                inSignature));

        enforce(isOperatorUnary(name) || inSignature.length != 1,
            "The operator `" ~ name ~ "` is not unary: " ~ grGetPrettyFunctionCall("", inSignature));

        enforce(isOperatorBinary(name) || inSignature.length != 2,
            "The operator `" ~ name ~ "` is not binary: " ~ grGetPrettyFunctionCall("", inSignature));

        return addFunction(callback, "@operator_" ~ name, inSignature, [outType], constraints);
    }

    /// Définit une convertion entre deux types différents
    override GrPrimitive addCast(GrCallback callback, GrType srcType,
        GrType dstType, bool isExplicit = false, GrConstraint[] constraints = []) {
        auto primitive = addFunction(callback, "@as", [srcType, dstType], [
                dstType
            ], constraints);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    /// Ajoute un constructeur
    override GrPrimitive addConstructor(GrCallback callback, GrType type,
        GrType[] inSignature = [], GrConstraint[] constraints = []) {
        auto primitive = addFunction(callback, "@static_" ~ grUnmangleComposite(type.mangledType)
                .name, inSignature ~ [type], [type], constraints);
        return primitive;
    }

    /// Ajoute une fonction statique lié à un type
    override GrPrimitive addStatic(GrCallback callback, GrType type, string name,
        GrType[] inSignature = [], GrType[] outSignature = [], GrConstraint[] constraints = [
        ]) {
        auto primitive = addFunction(callback, "@static_" ~ grUnmangleComposite(type.mangledType)
                .name ~ "." ~ name, inSignature ~ [type], outSignature, constraints);
        return primitive;
    }

    /// Définit des primitives qui agiront comme un champ d’une classe mais pour un natif. \
    /// Laisser `setCallback` à `null` rendra la propriété constante.
    /// * `getCallback` prend `nativeType`  en entrée et doit renvoyer `propertyType` en sortie.
    /// * `setCallback` prend `nativeType` et `propertyType`  en entrée et doit renvoyer `propertyType` en sortie.
    override GrPrimitive[] addProperty(GrCallback getCallback, GrCallback setCallback,
        string name, GrType nativeType, GrType propertyType, GrConstraint[] constraints = [
        ]) {
        GrPrimitive[] primitives;

        if (getCallback) {
            primitives ~= addFunction(getCallback, "@property_" ~ name,
                [nativeType], [propertyType], constraints);
        }
        else {
            throw new Exception("the property `@" ~ grGetPrettyType(
                    nativeType) ~ "." ~ name ~ "`must define at least a getter");
        }
        if (setCallback) {
            primitives ~= addFunction(setCallback, "@property_" ~ name,
                [nativeType, propertyType], [propertyType], constraints);
        }
        return primitives;
    }

    /// Enjolive la primitive
    private string getPrettyPrimitive(GrPrimitive primitive) {
        import std.conv : to;

        auto nbParameters = primitive.inSignature.length;
        string result;
        if (primitive.name == "@as") {
            result ~= "as";
            nbParameters = 1;
        }
        else if (primitive.name.length >= "@static_".length &&
            primitive.name[0 .. "@static_".length] == "@static_") {

            if (nbParameters) {
                result = "@" ~ grGetPrettyType(primitive.inSignature[$ - 1]);
                nbParameters--;
            }
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
