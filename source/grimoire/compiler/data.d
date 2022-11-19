/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.data;

import std.conv : to;
import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.constraint;
import grimoire.compiler.mangle;
import grimoire.compiler.library;
import grimoire.compiler.pretty;

/**
Contains type information and D linked functions. \
Must be the same between the compilation and the runtime.
___
Only use the *add*X() functions ***before*** compilation happen,
else they won't be linked.
*/
final class GrData {
    package(grimoire) {
        /// Opaque pointer types. \
        /// They're pointer only defined by a name. \
        /// Can only be used with primitives.
        GrNativeDefinition[] _nativeDefinitions;
        /// Abstract native types.
        GrAbstractNativeDefinition[] _abstractNativeDefinitions;
        /// Type aliases
        GrTypeAliasDefinition[] _aliasDefinitions, _templateAliasDefinitions;
        /// Enum types.
        GrEnumDefinition[] _enumDefinitions;
        /// Object types.
        GrClassDefinition[] _classDefinitions;
        /// Abstract object types.
        GrClassDefinition[] _abstractClassDefinitions;
        /// Variable types
        GrVariableDefinition[] _variableDefinitions;

        /// All primitives, used for both the compiler and the runtime.
        GrPrimitive[] _primitives, _abstractPrimitives;

        /// Used to validate special primitives.
        GrAnyData _anyData;

        GrCallback[] _callbacks;

        /// Name aliases
        string[string] _aliases;
    }

    /// Add types and primitives defined in the library
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

        foreach (string name, string alias_; library._aliases) {
            _aliases[name] = alias_;
        }
    }

    /// Primitive global constants, call registerIntConstant at the start of the parser. \
    /// Not used for now.
    GrType addIntConstant(const string name, int value) {
        if (value + 1 > value)
            assert(false, "TODO: Implement later");
        return grVoid;
    }

    /// Is a type already declared in this file
    package bool isTypeDeclared(const string name, uint fileId, bool isPublic) const {
        if (isEnum(name, fileId, isPublic))
            return true;
        if (isClass(name, fileId, isPublic))
            return true;
        if (isTypeAlias(name, fileId, isPublic))
            return true;
        if (isNative(name))
            return true;
        return false;
    }

    /// Is a type already declared in this file
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

    /// Define an enum type.
    package GrType addEnum(const string name, const string[] fields, uint fileId, bool isPublic) {
        GrEnumDefinition enumDef = new GrEnumDefinition;
        enumDef.name = name;
        enumDef.fields = fields.dup;
        enumDef.index = _enumDefinitions.length;
        enumDef.fileId = fileId;
        enumDef.isPublic = isPublic;
        _enumDefinitions ~= enumDef;

        GrType stType = GrType.Base.enum_;
        stType.mangledType = name;
        return stType;
    }

    package void registerClass(const string name, uint fileId, bool isPublic,
        string[] templateVariables, uint position) {
        GrClassDefinition class_ = new GrClassDefinition;
        class_.name = name;
        class_.position = position;
        class_.fileId = fileId;
        class_.isPublic = isPublic;
        class_.templateVariables = templateVariables;
        _abstractClassDefinitions ~= class_;
    }

    /// Define an alias of another type.
    package GrType addAlias(const string name, const GrType type, uint fileId, bool isPublic) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isPublic = isPublic;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Define an alias of another type.
    package GrType addTemplateAlias(const string name, const GrType type, uint fileId, bool isPublic) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isPublic = isPublic;
        _templateAliasDefinitions ~= typeAlias;
        return type;
    }

    package void clearTemplateAliases() {
        _templateAliasDefinitions.length = 0;
    }

    /// Is the enum defined ?
    package bool isEnum(const string name, uint fileId, bool isPublic) const {
        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isPublic || isPublic))
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

    /// Is the class defined ?
    package bool isClass(const string name, uint fileId, bool isPublic) const {
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && (class_.fileId == fileId || class_.isPublic || isPublic))
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

    /// Is the type alias defined ?
    package bool isTypeAlias(const string name, uint fileId, bool isPublic) const {
        foreach (typeAlias; _templateAliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isPublic || isPublic))
                return true;
        }
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId ||
                    typeAlias.isPublic || isPublic))
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

    /// Is the user-type defined ?
    package bool isNative(const string name) const {
        foreach (native; _abstractNativeDefinitions) {
            if (native.name == name)
                return true;
        }
        return false;
    }

    /// Return the user-type definition.
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

    /// Return the enum definition.
    GrEnumDefinition getEnum(const string name, uint fileId) {
        import std.conv : to;

        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isPublic))
                return enumType;
        }
        return null;
    }

    /// Return the class definition.
    GrClassDefinition getClass(const string mangledName, uint fileId, bool isPublic = false) {
        import std.algorithm.searching : findSplitBefore;

        foreach (class_; _classDefinitions) {
            if (class_.name == mangledName && (class_.fileId == fileId || class_.isPublic ||
                    isPublic))
                return class_;
        }
        const mangledTuple = findSplitBefore(mangledName, "$");
        string name = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && class_.templateVariables.length == templateTypes.length &&
                (class_.fileId == fileId || class_.isPublic || isPublic)) {
                GrClassDefinition generatedClass = new GrClassDefinition;
                generatedClass.name = mangledName;
                generatedClass.parent = class_.parent;
                generatedClass.signature = class_.signature;
                generatedClass.fields = class_.fields;
                generatedClass.templateVariables = class_.templateVariables;
                generatedClass.templateTypes = templateTypes;
                generatedClass.position = class_.position;
                generatedClass.isParsed = class_.isParsed;
                generatedClass.isPublic = class_.isPublic;
                generatedClass.fileId = class_.fileId;
                generatedClass.fieldsInfo = class_.fieldsInfo;
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

    /// Return the type alias definition.
    GrTypeAliasDefinition getTypeAlias(const string name, uint fileId) {
        foreach (typeAlias; _templateAliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId || typeAlias.isPublic))
                return typeAlias;
        }
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId || typeAlias.isPublic))
                return typeAlias;
        }
        return null;
    }

    /**
    Is the primitive already declared ?
    */
    bool isPrimitiveDeclared(const string mangledName) {
        foreach (primitive; _primitives) {
            if (primitive.mangledName == mangledName)
                return true;
        }
        return false;
    }

    /**
    Returns the declared primitive definition.
    */
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
                    foreach (GrConstraint constraint; primitive.constraints) {
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
                    assert(name.length == 0);
                    foreach (GrConstraint constraint; primitive.constraints) {
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

    package GrPrimitive reifyPrimitive(const GrPrimitive templatePrimitive) {
        // We assume the signature was already validated with `isSignatureCompatible` to be fully compatible with the primitive
        GrPrimitive primitive = new GrPrimitive(templatePrimitive);
        for (int i; i < primitive.inSignature.length; ++i) {
            primitive.inSignature[i] = reifyType(primitive.inSignature[i]);
            checkUnknownClasses(primitive.inSignature[i]);
            assert(!primitive.inSignature[i].isAbstract, "the primitive `" ~ grGetPrettyFunction(primitive.name,
                    primitive.inSignature, primitive.outSignature) ~ "` is abstract");
        }
        for (int i; i < primitive.outSignature.length; ++i) {
            primitive.outSignature[i] = reifyType(primitive.outSignature[i]);
            checkUnknownClasses(primitive.outSignature[i]);
            assert(!primitive.outSignature[i].isAbstract, "the primitive `" ~ grGetPrettyFunction(primitive.name,
                    primitive.inSignature, primitive.outSignature) ~ "` is abstract");
        }
        primitive.mangledName = grMangleComposite(primitive.name, primitive.inSignature);
        primitive.index = cast(uint) _primitives.length;
        assert(!isPrimitiveDeclared(primitive.mangledName),
            "`" ~ getPrettyPrimitive(primitive) ~ "` is already declared");
        _primitives ~= primitive;
        return primitive;
    }

    private GrType reifyType(const GrType type) {
        GrType result = type;
        if (type.isAny) {
            assert(_anyData, "missing template database");
            result = _anyData.get(type.mangledType);
            if (result.base == GrType.Base.void_)
                result.isAbstract = true;
        }
        final switch (type.base) with (GrType.Base) {
        case int_:
        case float_:
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
        case function_:
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
        result.isConst = type.isConst;
        result.isPure = type.isPure;
        return result;
    }

    // Forcing the classes to be reified they aren't already
    private void checkUnknownClasses(GrType type) {
        switch (type.base) with (GrType.Base) {
        case class_:
            GrClassDefinition classDef = getClass(type.mangledType, 0, true);
            if (!classDef)
                throw new Exception("undefined class `" ~ type.mangledType ~ "`");
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
        case function_:
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

    /// Check if the first signature match or can be upgraded (by inheritance) to the second one.
    bool isSignatureCompatible(const GrType[] first, const GrType[] second,
        bool isAbstract, uint fileId, bool isPublic = false) {
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
            case float_:
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
                        [grUnmangle(second[i].mangledType)], isAbstract, fileId, isPublic))
                    continue;
                return false;
            case function_:
                if (first[i].base != second[i].base)
                    return false;
                if (!isSignatureCompatible(grUnmangleSignature(first[i].mangledType),
                        grUnmangleSignature(second[i].mangledType), isAbstract, fileId, isPublic))
                    return false;
                if (!isSignatureCompatible(grUnmangleSignature(first[i].mangledReturnType),
                        grUnmangleSignature(second[i].mangledReturnType),
                        isAbstract, fileId, isPublic))
                    return false;
                continue;
            case task:
                if (first[i].base != second[i].base)
                    return false;
                if (isSignatureCompatible(grUnmangleSignature(first[i].mangledType),
                        grUnmangleSignature(second[i].mangledType), isAbstract, fileId, isPublic))
                    continue;
                return false;
            case class_:
                if (first[i].base != second[i].base)
                    return false;

                if (!isSignatureCompatible(grUnmangleComposite(first[i].mangledType).signature,
                        grUnmangleComposite(second[i].mangledType).signature,
                        isAbstract, fileId, isPublic))
                    return false;

                string className = first[i].mangledType;
                for (;;) {
                    if (grUnmangleComposite(className)
                        .name == grUnmangleComposite(second[i].mangledType).name) {
                        continue __signatureLoop;
                    }
                    const GrClassDefinition classType = getClass(className, fileId, isPublic);
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
                        isAbstract, fileId, isPublic))
                    return false;

                string nativeName = first[i].mangledType;
                for (;;) {
                    if (grUnmangleComposite(nativeName)
                        .name == grUnmangleComposite(second[i].mangledType).name) {
                        continue __signatureLoop;
                    }
                    const GrNativeDefinition nativeType = getNative(nativeName);
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

    /**
    Prettify a primitive signature.
    */
    private string getPrimitiveDisplayById(uint id) {
        if (id >= _primitives.length)
            throw new Exception("invalid primitive id");
        return getPrettyPrimitive(_primitives[id]);
    }

    private string getPrettyPrimitive(const GrPrimitive primitive) {
        import std.conv : to;

        string result = primitive.name;
        auto nbParameters = primitive.inSignature.length;
        if (primitive.name == "@as")
            nbParameters = 1;
        else if (primitive.name == "@new")
            nbParameters--;
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
