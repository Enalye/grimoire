/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.data;

import std.conv : to;
import std.exception : enforce;

import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.library;
import grimoire.compiler.pretty;

/**
Contient les informations de types et les fonctions en D liées. \
Ces informations doivent rester cohérents entre la compilation et l’exécution.
___
N’utilisez les fonctions `add[…]()` qu’avant la compilation, \
sinon elles ne seront pas utilisées.
*/
final class GrData {
    package(grimoire) {
        /// Types de pointeurs opaques. \
        /// Ils ne sont utilisables que par des primitives.
        GrNativeDefinition[] _nativeDefinitions;
        /// Types abstraits de natifs.
        GrAbstractNativeDefinition[] _abstractNativeDefinitions;
        /// Alias de type.
        GrTypeAliasDefinition[] _aliasDefinitions, _templateAliasDefinitions;
        /// Types d’énumérations.
        GrEnumDefinition[] _enumDefinitions;
        /// Types de classes.
        GrClassDefinition[] _classDefinitions;
        /// Types abstraits de classes.
        GrClassDefinition[] _abstractClassDefinitions;
        /// Définitions de variables globales.
        GrVariableDefinition[] _variableDefinitions;

        /// Les primitives.
        GrPrimitive[] _primitives, _abstractPrimitives;

        /// Utilisé pour valider des primitives génériques.
        GrAnyData _anyData;

        /// Les pointeurs de fonction liés aux primitives.
        GrCallback[] _callbacks;

        /// Restriction de modèle de fonction
        GrConstraint.Data[string] _constraints;

        GrPrimitive _currentPrimitive;
    }

    /// Ajoute une nouvelle bibliothèque contenant ses définitions de type et de primitives
    void addLibrary(GrLibrary library) {
        _abstractNativeDefinitions ~= library._abstractNativeDefinitions;
        _aliasDefinitions ~= library._aliasDefinitions;
        _abstractClassDefinitions ~= library._abstractClassDefinitions;
        _variableDefinitions ~= library._variableDefinitions;
        foreach (GrEnumDefinition enum_; library._enumDefinitions) {
            enum_.index = _enumDefinitions.length;
            _enumDefinitions ~= enum_;
        }
        const uint libStartIndex = cast(uint) _callbacks.length;
        foreach (GrPrimitive primitive; library._abstractPrimitives) {
            GrPrimitive prim = new GrPrimitive(primitive);
            prim.callbackId += libStartIndex;
            _abstractPrimitives ~= prim;
        }
        _callbacks ~= library._callbacks;

        foreach (string name, GrConstraint.Data constraint; library._constraints) {
            _constraints[name] = new GrConstraint.Data(constraint);
        }
    }

    /// Ce type est-il déjà déclaré dans ce fichier ?
    package bool isTypeDeclared(const string name, size_t fileId, bool isExport) const {
        if (isEnum(name, fileId, isExport))
            return true;
        if (isClass(name, fileId, isExport))
            return true;
        if (isTypeAlias(name, fileId, isExport))
            return true;
        if (isNative(name))
            return true;
        return false;
    }

    /// Ditto
    private bool isTypeDeclared(const string name) const {
        if (isEnum(name))
            return true;
        if (isClass(name))
            return true;
        if (isTypeAlias(name))
            return true;
        if (isNative(name))
            return true;
        return false;
    }

    /// Définit une énumération
    package GrType addEnum(const string name, const string[] fieldNames,
        const int[] values, size_t fileId, bool isExport) {
        GrEnumDefinition enumDef = new GrEnumDefinition;
        enumDef.name = name;

        int lastValue = -1;
        for (size_t i; i < fieldNames.length; ++i) {
            GrEnumDefinition.Field field;
            field.name = fieldNames[i];

            lastValue = i < values.length ? values[i] : lastValue + 1;
            field.value = lastValue;

            enumDef.fields ~= field;
        }

        enumDef.index = _enumDefinitions.length;
        enumDef.fileId = fileId;
        enumDef.isExport = isExport;
        _enumDefinitions ~= enumDef;

        GrType stType = GrType.Base.enum_;
        stType.mangledType = name;
        return stType;
    }

    /// Définit une classe
    package void registerClass(const string name, size_t fileId, bool isExport,
        string[] templateVariables, uint position) {
        GrClassDefinition class_ = new GrClassDefinition;
        class_.name = name;
        class_.position = position;
        class_.fileId = fileId;
        class_.isExport = isExport;
        class_.templateVariables = templateVariables;
        _abstractClassDefinitions ~= class_;
    }

    /// Definit un alias de type
    package GrType addAlias(const string name, const GrType type, size_t fileId, bool isExport) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isExport = isExport;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Definit un alias temporaire pour la généricité
    package GrType addTemplateAlias(const string name, const GrType type,
        size_t fileId, bool isExport) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isExport = isExport;
        _templateAliasDefinitions ~= typeAlias;
        return type;
    }

    /// Nettoie les alias génériques
    package void clearTemplateAliases() {
        _templateAliasDefinitions.length = 0;
    }

    /// L’énumération existe-elle ?
    package bool isEnum(const string name, size_t fileId, bool isExport) const {
        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isExport || isExport))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isEnum(const string name) const {
        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name)
                return true;
        }
        return false;
    }

    /// La classe existe-elle ?
    package bool isClass(const string name, size_t fileId, bool isExport) const {
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && (class_.fileId == fileId || class_.isExport || isExport))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isClass(const string name) const {
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name)
                return true;
        }
        return false;
    }

    /// L’alias existe-il ?
    package bool isTypeAlias(const string name, size_t fileId, bool isExport) const {
        foreach (typeAlias; _templateAliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isExport || isExport))
                return true;
        }
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isExport || isExport))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isTypeAlias(const string name) const {
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name)
                return true;
        }
        return false;
    }

    /// Le natif exite-il ?
    package bool isNative(const string name) const {
        foreach (native; _abstractNativeDefinitions) {
            if (native.name == name)
                return true;
        }
        return false;
    }

    /// Renvoie la définition du natif
    GrNativeDefinition getNative(const string mangledName) {
        import std.algorithm.searching : findSplitBefore;

        foreach (native; _nativeDefinitions) {
            if (native.name == mangledName)
                return native;
        }

        const mangledTuple = findSplitBefore(mangledName, "$");
        string name = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        foreach (native; _abstractNativeDefinitions) {
            if (native.name == name && native.templateVariables.length == templateTypes.length) {
                GrNativeDefinition generatedNative = new GrNativeDefinition;
                generatedNative.name = mangledName;
                generatedNative.parent = native.parent;

                _anyData = new GrAnyData;
                for (int i; i < native.templateVariables.length; ++i) {
                    _anyData.set(native.templateVariables[i], templateTypes[i]);
                }

                GrType[] parentTemplateSignature = native.parentTemplateSignature;
                for (int i; i < parentTemplateSignature.length; ++i) {
                    if (parentTemplateSignature[i].isAny) {
                        parentTemplateSignature[i] = _anyData.get(
                            parentTemplateSignature[i].mangledType);
                    }
                }
                generatedNative.parent = grMangleComposite(generatedNative.parent,
                    parentTemplateSignature);

                _nativeDefinitions ~= generatedNative;
                return generatedNative;
            }
        }
        return null;
    }

    /// Renvoie la définition de l’énumération
    GrEnumDefinition getEnum(const string name, size_t fileId) {
        import std.conv : to;

        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isExport))
                return enumType;
        }
        return null;
    }

    /// Renvoie la définition de la classe
    GrClassDefinition getClass(const string mangledName, size_t fileId, bool isExport = false) {
        import std.algorithm.searching : findSplitBefore;

        foreach (class_; _classDefinitions) {
            if (class_.name == mangledName && (class_.fileId == fileId || class_.isExport ||
                    isExport))
                return class_;
        }
        const mangledTuple = findSplitBefore(mangledName, "$");
        string name = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && class_.templateVariables.length == templateTypes.length &&
                (class_.fileId == fileId || class_.isExport || isExport)) {
                GrClassDefinition generatedClass = new GrClassDefinition;
                generatedClass.name = mangledName;
                generatedClass.parent = class_.parent;
                generatedClass.signature = class_.signature;
                generatedClass.fields = class_.fields;
                generatedClass.templateVariables = class_.templateVariables;
                generatedClass.templateTypes = templateTypes;
                generatedClass.position = class_.position;
                generatedClass.isParsed = class_.isParsed;
                generatedClass.isExport = class_.isExport;
                generatedClass.fileId = class_.fileId;
                generatedClass.fieldsInfo = class_.fieldsInfo;
                generatedClass.fieldConsts = class_.fieldConsts;
                generatedClass.index = _classDefinitions.length;

                _anyData = new GrAnyData;
                for (int i; i < generatedClass.templateVariables.length; ++i) {
                    _anyData.set(generatedClass.templateVariables[i],
                        generatedClass.templateTypes[i]);
                }

                for (int i; i < generatedClass.signature.length; ++i) {
                    if (generatedClass.signature[i].isAny) {
                        generatedClass.signature[i] = _anyData.get(
                            generatedClass.signature[i].mangledType);
                        if (generatedClass.signature[i].base == GrType.Base.void_)
                            return null;
                    }
                }

                GrType[] parentTemplateSignature = class_.parentTemplateSignature;
                for (int i; i < parentTemplateSignature.length; ++i) {
                    if (parentTemplateSignature[i].isAny) {
                        parentTemplateSignature[i] = _anyData.get(
                            parentTemplateSignature[i].mangledType);
                    }
                }
                generatedClass.parent = grMangleComposite(generatedClass.parent,
                    parentTemplateSignature);

                _classDefinitions ~= generatedClass;
                return generatedClass;
            }
        }
        return null;
    }

    /// Renvoie la définition de l’alias de type
    GrTypeAliasDefinition getTypeAlias(const string name, size_t fileId, bool isExport = false) {
        foreach (typeAlias; _templateAliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isExport || isExport))
                return typeAlias;
        }
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isExport || isExport))
                return typeAlias;
        }
        return null;
    }

    /// La primitive exite-elle ?
    bool isPrimitiveDeclared(const string mangledName) {
        foreach (primitive; _primitives) {
            if (primitive.mangledName == mangledName)
                return true;
        }
        return false;
    }

    /// Renvoie la définition de la primitive
    GrPrimitive getPrimitive(const string mangledName) {
        import std.conv : to;

        foreach (primitive; _primitives) {
            if (primitive.mangledName == mangledName)
                return primitive;
        }
        return null;
    }

    /// Ditto
    package GrPrimitive getCompatiblePrimitive(const string name, const GrType[] signature) {
        foreach (GrPrimitive primitive; _primitives) {
            if (primitive.name == name) {
                if (isSignatureCompatible(signature, primitive.inSignature, false, 0, true))
                    return primitive;
            }
        }
        _anyData = new GrAnyData;
        foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                if (isSignatureCompatible(signature, primitive.inSignature, false, 0, true)) {
                    GrPrimitive reifiedPrimitive = reifyPrimitive(primitive);
                    if (!reifiedPrimitive)
                        continue;
                    return reifiedPrimitive;
                }
            }
        }
        return null;
    }

    /// Ditto
    package GrPrimitive getAbstractPrimitive(const string name, const GrType[] signature) {
        __primitiveLoop: foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                _anyData = new GrAnyData;
                if (isSignatureCompatible(signature, primitive.inSignature, true, 0, true)) {
                    foreach (ref GrConstraint constraint; primitive.constraints) {
                        if (!constraint.evaluate(this, _anyData))
                            continue __primitiveLoop;
                    }
                    GrPrimitive reifiedPrimitive = reifyPrimitive(primitive);
                    if (!reifiedPrimitive)
                        continue;
                    return reifiedPrimitive;
                }
            }
        }
        return null;
    }

    /// Ditto
    package GrPrimitive getPrimitive(const string name, const GrType[] signature) {
        const string mangledName = grMangleComposite(name, signature);
        foreach (GrPrimitive primitive; _primitives) {
            if (primitive.name == name) {
                if (primitive.mangledName == mangledName)
                    return primitive;
            }
        }
        foreach (GrPrimitive primitive; _primitives) {
            if (primitive.name == name) {
                if (isSignatureCompatible(signature, primitive.inSignature, 0, true))
                    return primitive;
            }
        }
        __primitiveLoop: foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                _anyData = new GrAnyData;
                if (isSignatureCompatible(signature, primitive.inSignature, true, 0, true)) {
                    enforce(name.length == 0);
                    foreach (ref GrConstraint constraint; primitive.constraints) {
                        if (!constraint.evaluate(this, _anyData))
                            continue __primitiveLoop;
                    }
                    GrPrimitive reifiedPrimitive = reifyPrimitive(primitive);
                    if (!reifiedPrimitive)
                        continue;
                    return reifiedPrimitive;
                }
            }
        }
        return null;
    }

    /// Vérifie si les bibliothèques se réfèrent à des types inconnus
    package void checkUnknownTypes() {
        bool checkType(GrType type) {
            import std.algorithm.searching : findSplitBefore;

            switch (type.base) with (GrType.Base) {
            case native:
                const string name = findSplitBefore(type.mangledType, "$")[0];
                return isNative(name);
            case class_:
                const string name = findSplitBefore(type.mangledType, "$")[0];
                return isClass(name);
            case enum_:
                return isEnum(type.mangledType);
            case optional:
            case channel:
            case list:
                return checkType(grUnmangle(type.mangledType));
            case func:
                foreach (GrType param; grUnmangleSignature(type.mangledReturnType)) {
                    if (!checkType(param))
                        return false;
                }
                goto case event;
            case event:
            case task:
                foreach (GrType param; grUnmangleSignature(type.mangledType)) {
                    if (!checkType(param))
                        return false;
                }
                return true;
            default:
                return true;
            }
        }

        void checkPrimitiveSignature(GrPrimitive primitive) {
            foreach (type; primitive.inSignature) {
                enforce(checkType(type), "type `" ~ grGetPrettyType(
                        type) ~ "` is not declared in primitive `" ~ getPrettyPrimitive(
                        primitive) ~ "`");
            }
            foreach (type; primitive.outSignature) {
                enforce(checkType(type), "type `" ~ grGetPrettyType(
                        type) ~ "` is not declared in primitive `" ~ getPrettyPrimitive(
                        primitive) ~ "`");
            }
        }

        void checkClassSignature(GrClassDefinition class_) {
            foreach (type; class_.signature) {
                enforce(checkType(type),
                    "type `" ~ grGetPrettyType(
                        type) ~ "` is not declared in class `" ~ class_.name ~ "`");
            }
        }

        foreach (alias_; _aliasDefinitions) {
            enforce(checkType(alias_.type), "type `" ~ grGetPrettyType(
                    alias_.type) ~ "` is not declared in alias `" ~ alias_.name ~ "`");
        }

        foreach (class_; _abstractClassDefinitions) {
            checkClassSignature(class_);
        }

        foreach (class_; _classDefinitions) {
            checkClassSignature(class_);
        }

        foreach (primitive; _abstractPrimitives) {
            checkPrimitiveSignature(primitive);
        }

        foreach (primitive; _primitives) {
            checkPrimitiveSignature(primitive);
        }

        foreach (variable; _variableDefinitions) {
            enforce(checkType(variable.type), "type `" ~ grGetPrettyType(
                    variable.type) ~ "` is not declared in variable `" ~ variable.name ~ "`");
        }
    }

    /// Transforme un modèle de primitive en primitive concrète
    package GrPrimitive reifyPrimitive(const GrPrimitive templatePrimitive) {
        // On considère que la signature a déjà été validé par `isSignatureCompatible`
        // pour être entièrement compatible avec la primitive
        GrPrimitive primitive = new GrPrimitive(templatePrimitive);
        _currentPrimitive = primitive;
        for (int i; i < primitive.inSignature.length; ++i) {
            primitive.inSignature[i] = reifyType(primitive.inSignature[i]);
            checkUnknownClasses(primitive.inSignature[i]);
            enforce(!primitive.inSignature[i].isAbstract, "the primitive `" ~ grGetPrettyFunction(primitive.name,
                    primitive.inSignature, primitive.outSignature) ~ "` is abstract");
        }
        for (int i; i < primitive.outSignature.length; ++i) {
            primitive.outSignature[i] = reifyType(primitive.outSignature[i]);
            checkUnknownClasses(primitive.outSignature[i]);
            enforce(!primitive.outSignature[i].isAbstract, "the primitive `" ~ grGetPrettyFunction(primitive.name,
                    primitive.inSignature, primitive.outSignature) ~ "` is abstract");
        }
        primitive.mangledName = grMangleComposite(primitive.name, primitive.inSignature);
        primitive.index = cast(uint) _primitives.length;
        enforce(!isPrimitiveDeclared(primitive.mangledName),
            "`" ~ getPrettyPrimitive(primitive) ~ "` is already declared");
        _primitives ~= primitive;
        return primitive;
    }

    /// On transforme un type générique en type concret
    private GrType reifyType(const GrType type) {
        GrType result = type;
        if (type.isAny) {
            enforce(_anyData, "missing template database");
            result = _anyData.get(type.mangledType);
            if (result.base == GrType.Base.void_)
                result.isAbstract = true;
        }
        final switch (type.base) with (GrType.Base) {
        case int_:
        case uint_:
        case byte_:
        case char_:
        case float_:
        case double_:
        case bool_:
        case string_:
            break;
        case list:
        case channel:
        case optional:
            GrType subType = reifyType(grUnmangle(type.mangledType));
            result.mangledType = grMangle(subType);
            result.isAbstract = subType.isAbstract;
            break;
        case func:
            auto composite = grUnmangleComposite(type.mangledType);
            for (int i; i < composite.signature.length; ++i) {
                composite.signature[i] = reifyType(composite.signature[i]);
                result.isAbstract |= composite.signature[i].isAbstract;
            }
            GrType[] outSignature = grUnmangleSignature(type.mangledReturnType);
            for (int i; i < outSignature.length; ++i) {
                outSignature[i] = reifyType(outSignature[i]);
                result.isAbstract |= outSignature[i].isAbstract;
            }
            result.mangledType = grMangleComposite(composite.name, composite.signature);
            result.mangledReturnType = grMangleSignature(outSignature);
            break;
        case task:
            auto composite = grUnmangleComposite(type.mangledType);
            for (int i; i < composite.signature.length; ++i) {
                composite.signature[i] = reifyType(composite.signature[i]);
                result.isAbstract |= composite.signature[i].isAbstract;
            }
            result.mangledType = grMangleComposite(composite.name, composite.signature);
            break;
        case event:
            auto composite = grUnmangleComposite(type.mangledType);
            for (int i; i < composite.signature.length; ++i) {
                composite.signature[i] = reifyType(composite.signature[i]);
                result.isAbstract |= composite.signature[i].isAbstract;
            }
            result.mangledType = grMangleComposite(composite.name, composite.signature);
            break;
        case class_:
        case native:
            auto temp = grUnmangleComposite(type.mangledType);
            for (int i; i < temp.signature.length; ++i) {
                temp.signature[i] = reifyType(temp.signature[i]);
                result.isAbstract |= temp.signature[i].isAbstract;
            }
            result.mangledType = grMangleComposite(temp.name, temp.signature);
            break;
        case enum_:
            break;
        case void_:
        case null_:
        case internalTuple:
        case reference:
            break;
        }
        result.isPure = type.isPure;
        return result;
    }

    // Force les classes à être réifiées quand elle ne le sont pas encore
    private void checkUnknownClasses(GrType type) {
        switch (type.base) with (GrType.Base) {
        case class_:
            GrClassDefinition classDef = getClass(type.mangledType, 0, true);
            enforce(classDef,
                "undefined class `" ~ type.mangledType ~ "` in `" ~ getPrettyPrimitive(
                    _currentPrimitive) ~ "`");
            foreach (GrType fieldType; classDef.signature) {
                if (fieldType == type)
                    continue;
                checkUnknownClasses(fieldType);
            }
            break;
        case list:
        case channel:
            GrType subType = grUnmangle(type.mangledType);
            checkUnknownClasses(subType);
            break;
        case func:
            foreach (GrType inType; grUnmangleSignature(type.mangledType))
                checkUnknownClasses(inType);
            foreach (GrType outType; grUnmangleSignature(type.mangledReturnType))
                checkUnknownClasses(outType);
            break;
        case task:
            foreach (GrType inType; grUnmangleSignature(type.mangledType))
                checkUnknownClasses(inType);
            break;
        default:
            return;
        }
    }

    /// Vérifie si la première signature correspond ou peut être promu (par héritage) à la seconde
    bool isSignatureCompatible(const GrType[] first, const GrType[] second,
        bool isAbstract, size_t fileId, bool isExport = false) {
        if (first.length != second.length)
            return false;
        __signatureLoop: for (int i; i < first.length; ++i) {
            if (second[i].isAny) {
                if (!isAbstract)
                    return false;

                const GrType registeredType = _anyData.get(second[i].mangledType);
                if (registeredType.base == GrType.Base.void_) {
                    _anyData.set(second[i].mangledType, first[i]);
                }
                else {
                    if (registeredType != first[i])
                        return false;
                }
                continue;
            }
            final switch (second[i].base) with (GrType.Base) {
            case int_:
            case uint_:
            case byte_:
            case char_:
            case float_:
            case double_:
            case bool_:
            case string_:
                if (first[i].base == second[i].base)
                    continue;
                return false;
            case list:
            case channel:
            case optional:
                if (first[i].base != second[i].base)
                    return false;
                if (isSignatureCompatible([grUnmangle(first[i].mangledType)],
                        [grUnmangle(second[i].mangledType)], isAbstract, fileId, isExport))
                    continue;
                return false;
            case func:
                if (first[i].base != second[i].base)
                    return false;
                if (!isSignatureCompatible(grUnmangleSignature(first[i].mangledType),
                        grUnmangleSignature(second[i].mangledType), isAbstract, fileId, isExport))
                    return false;
                if (!isSignatureCompatible(grUnmangleSignature(first[i].mangledReturnType),
                        grUnmangleSignature(second[i].mangledReturnType),
                        isAbstract, fileId, isExport))
                    return false;
                continue;
            case task:
                if (first[i].base != second[i].base)
                    return false;
                if (isSignatureCompatible(grUnmangleSignature(first[i].mangledType),
                        grUnmangleSignature(second[i].mangledType), isAbstract, fileId, isExport))
                    continue;
                return false;
            case event:
                if (first[i].base != second[i].base)
                    return false;
                if (isSignatureCompatible(grUnmangleSignature(first[i].mangledType),
                        grUnmangleSignature(second[i].mangledType), isAbstract, fileId, isExport))
                    continue;
                return false;
            case class_:
                if (first[i].base != second[i].base)
                    return false;

                if (!isSignatureCompatible(grUnmangleComposite(first[i].mangledType).signature,
                        grUnmangleComposite(second[i].mangledType).signature,
                        isAbstract, fileId, isExport))
                    return false;

                string className = first[i].mangledType;
                for (;;) {
                    if (grUnmangleComposite(className)
                        .name == grUnmangleComposite(second[i].mangledType).name) {
                        continue __signatureLoop;
                    }
                    const GrClassDefinition classType = getClass(className, fileId, isExport);
                    enforce(classType, "class type `" ~ className ~ "` does not exist");

                    if (!classType.parent.length)
                        return false;
                    className = classType.parent;
                }
                continue;
            case native:
                if (first[i].base != second[i].base)
                    return false;

                if (!isSignatureCompatible(grUnmangleComposite(first[i].mangledType).signature,
                        grUnmangleComposite(second[i].mangledType).signature,
                        isAbstract, fileId, isExport))
                    return false;

                string nativeName = first[i].mangledType;
                for (;;) {
                    if (grUnmangleComposite(nativeName)
                        .name == grUnmangleComposite(second[i].mangledType).name) {
                        continue __signatureLoop;
                    }
                    const GrNativeDefinition nativeType = getNative(nativeName);
                    enforce(nativeType, "native type `" ~ nativeName ~ "` does not exist");

                    if (!nativeType.parent.length)
                        return false;
                    nativeName = nativeType.parent;
                }
                continue;
            case enum_:
                if (first[i] != second[i])
                    return false;
                continue;
            case void_:
            case null_:
            case internalTuple:
            case reference:
                return false;
            }
        }
        return true;
    }

    void setAnyData(GrAnyData anyData) {
        _anyData = anyData;
    }

    /// Récupère les données d’une contrainte enregistrée
    package GrConstraint.Data getConstraintData(string name) {
        GrConstraint.Data* constraint = name in _constraints;
        return constraint ? *constraint : null;
    }

    /// Récupère tous les noms des constraintes enregistrées
    package const(string[]) getAllConstraintsName() {
        return _constraints.keys;
    }

    /// Formate une primitive pour être affichable
    private string getPrimitiveDisplayById(uint id) {
        enforce(id < _primitives.length, "invalid primitive id");
        return getPrettyPrimitive(_primitives[id]);
    }

    /// Ditto
    private string getPrettyPrimitive(const GrPrimitive primitive) {
        import std.string : indexOf;

        if (!primitive)
            return "";

        string result = primitive.name;
        auto nbParameters = primitive.inSignature.length;

        if (primitive.name == "@as")
            nbParameters = 1;
        else if (primitive.name.length >= "@static_".length &&
            primitive.name[0 .. "@static_".length] == "@static_") {

            if (primitive.inSignature.length) {
                result = "@" ~ grGetPrettyType(primitive.inSignature[$ - 1]);
                nbParameters--;
            }

            size_t methodIndex = primitive.name.indexOf('.');
            if (methodIndex != -1) {
                result ~= primitive.name[methodIndex .. $];
            }
        }

        result ~= "(";
        for (int i; i < nbParameters; i++) {
            result ~= grGetPrettyType(primitive.inSignature[i]);
            if ((i + 2) <= nbParameters)
                result ~= ", ";
        }
        result ~= ")";
        for (int i; i < primitive.outSignature.length; i++) {
            result ~= i ? ", " : " (";
            result ~= grGetPrettyType(primitive.outSignature[i]);
        }
        if (primitive.outSignature.length)
            result ~= ")";
        return result;
    }
}
