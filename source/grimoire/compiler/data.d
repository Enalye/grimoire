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
class GrData {
    package(grimoire) {
        /// Opaque pointer types. \
        /// They're pointer only defined by a name. \
        /// Can only be used with primitives.
        GrForeignDefinition[] _foreignDefinitions;
        /// Abstract foreign types.
        GrAbstractForeignDefinition[] _abstractForeignDefinitions;
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
        _abstractForeignDefinitions ~= library._abstractForeignDefinitions;
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
            import std.stdio;

            writeln(name, " -> ", alias_);
        }
    }

    /// Primitive global constants, call registerIntConstant at the start of the parser. \
    /// Not used for now.
    GrType addIntConstant(string name, int value) {
        if (value + 1 > value)
            assert(false, "TODO: Implement later");
        return grVoid;
    }

    /// Is a type already declared in this file
    package bool isTypeDeclared(string name, uint fileId, bool isPublic) {
        if (isEnum(name, fileId, isPublic))
            return true;
        if (isClass(name, fileId, isPublic))
            return true;
        if (isTypeAlias(name, fileId, isPublic))
            return true;
        if (isForeign(name))
            return true;
        return false;
    }

    /// Is a type already declared in this file
    private bool isTypeDeclared(string name) {
        if (isEnum(name))
            return true;
        if (isClass(name))
            return true;
        if (isTypeAlias(name))
            return true;
        if (isForeign(name))
            return true;
        return false;
    }

    /// Define an enum type.
    package GrType addEnum(string name, string[] fields, uint fileId, bool isPublic) {
        GrEnumDefinition enumDef = new GrEnumDefinition;
        enumDef.name = name;
        enumDef.fields = fields;
        enumDef.index = _enumDefinitions.length;
        enumDef.fileId = fileId;
        enumDef.isPublic = isPublic;
        _enumDefinitions ~= enumDef;

        GrType stType = GrType.Base.enum_;
        stType.mangledType = name;
        return stType;
    }

    package void registerClass(string name, uint fileId, bool isPublic,
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
    package GrType addTypeAlias(string name, GrType type, uint fileId, bool isPublic) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isPublic = isPublic;
        _aliasDefinitions ~= typeAlias;
        return type;
    }

    /// Define an alias of another type.
    package GrType addTemplateAlias(string name, GrType type, uint fileId, bool isPublic) {
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
    package bool isEnum(string name, uint fileId, bool isPublic) {
        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isEnum(string name) {
        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name)
                return true;
        }
        return false;
    }

    /// Is the class defined ?
    package bool isClass(string name, uint fileId, bool isPublic) {
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && (class_.fileId == fileId || class_.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isClass(string name) {
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name)
                return true;
        }
        return false;
    }

    /// Is the type alias defined ?
    package bool isTypeAlias(string name, uint fileId, bool isPublic) {
        foreach (typeAlias; _templateAliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId
                    || typeAlias.isPublic || isPublic))
                return true;
        }
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name && (typeAlias.fileId == fileId
                    || typeAlias.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isTypeAlias(string name) {
        foreach (typeAlias; _aliasDefinitions) {
            if (typeAlias.name == name)
                return true;
        }
        return false;
    }

    /// Is the user-type defined ?
    package bool isForeign(string name) {
        foreach (foreign; _abstractForeignDefinitions) {
            if (foreign.name == name)
                return true;
        }
        return false;
    }

    /// Return the user-type definition.
    GrForeignDefinition getForeign(string mangledName) {
        import std.algorithm.searching : findSplitBefore;

        foreach (foreign; _foreignDefinitions) {
            if (foreign.name == mangledName)
                return foreign;
        }

        const mangledTuple = findSplitBefore(mangledName, "$");
        string name = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        foreach (foreign; _abstractForeignDefinitions) {
            if (foreign.name == name && foreign.templateVariables.length == templateTypes.length) {
                GrForeignDefinition generatedForeign = new GrForeignDefinition;
                generatedForeign.name = mangledName;
                generatedForeign.parent = foreign.parent;

                _anyData = new GrAnyData;
                for (int i; i < foreign.templateVariables.length; ++i) {
                    _anyData.set(foreign.templateVariables[i], templateTypes[i]);
                }

                GrType[] parentTemplateSignature = foreign.parentTemplateSignature;
                for (int i; i < parentTemplateSignature.length; ++i) {
                    if (parentTemplateSignature[i].isAny) {
                        parentTemplateSignature[i] = _anyData.get(
                            parentTemplateSignature[i].mangledType);
                    }
                }
                generatedForeign.parent = grMangleComposite(generatedForeign.parent,
                    parentTemplateSignature);

                _foreignDefinitions ~= generatedForeign;
                return generatedForeign;
            }
        }
        return null;
    }

    /// Return the enum definition.
    GrEnumDefinition getEnum(string name, uint fileId) {
        import std.conv : to;

        foreach (enumType; _enumDefinitions) {
            if (enumType.name == name && (enumType.fileId == fileId || enumType.isPublic))
                return enumType;
        }
        return null;
    }

    /// Return the class definition.
    package GrClassDefinition getClass(string mangledName, uint fileId, bool isPublic = false) {
        import std.algorithm.searching : findSplitBefore;

        foreach (class_; _classDefinitions) {
            if (class_.name == mangledName && (class_.fileId == fileId || class_.isPublic
                    || isPublic))
                return class_;
        }
        const mangledTuple = findSplitBefore(mangledName, "$");
        string name = mangledTuple[0];
        GrType[] templateTypes = grUnmangleSignature(mangledTuple[1]);
        foreach (class_; _abstractClassDefinitions) {
            if (class_.name == name && class_.templateVariables.length == templateTypes.length
                && (class_.fileId == fileId || class_.isPublic || isPublic)) {
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
    GrTypeAliasDefinition getTypeAlias(string name, uint fileId) {
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
    bool isPrimitiveDeclared(string mangledName) {
        foreach (primitive; _primitives) {
            if (primitive.mangledName == mangledName)
                return true;
        }
        return false;
    }

    /**
    Returns the declared primitive definition.
    */
    GrPrimitive getPrimitive(string mangledName) {
        import std.conv : to;

        foreach (primitive; _primitives) {
            if (primitive.mangledName == mangledName)
                return primitive;
        }
        return null;
    }

    /// Ditto
    package GrPrimitive getCompatiblePrimitive(string name, GrType[] signature) {
        foreach (GrPrimitive primitive; _primitives) {
            if (primitive.name == name) {
                if (isSignatureCompatible(signature, primitive.inSignature, 0, true))
                    return primitive;
            }
        }
        foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                if (isSignatureCompatible(signature, primitive.inSignature, 0, true)) {
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
    package GrPrimitive getAbstractPrimitive(string name, GrType[] signature) {
        foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                _anyData = new GrAnyData;
                if (isAbstractSignatureCompatible(signature, primitive.inSignature, 0, true)) {
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
    package GrPrimitive getPrimitive(string name, GrType[] signature) {
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
        foreach (GrPrimitive primitive; _abstractPrimitives) {
            if (primitive.name == name) {
                _anyData = new GrAnyData;
                if (isAbstractSignatureCompatible(signature, primitive.inSignature, 0, true)) {
                    assert(name.length == 0);
                    GrPrimitive reifiedPrimitive = reifyPrimitive(primitive);
                    if (!reifiedPrimitive)
                        continue;
                    return reifiedPrimitive;
                }
            }
        }
        return null;
    }

    package GrPrimitive reifyPrimitive(GrPrimitive templatePrimitive) {
        // We assume the signature was already validated with `isSignatureCompatible` to be fully compatible with the primitive
        GrPrimitive primitive = new GrPrimitive(templatePrimitive);
        for (int i; i < primitive.inSignature.length; ++i) {
            if (primitive.inSignature[i].isAny) {
                primitive.inSignature[i] = _anyData.get(primitive.inSignature[i].mangledType);
                if (primitive.inSignature[i].base == GrType.Base.void_)
                    throw new Exception("`" ~ getPrettyPrimitive(primitive) ~ "` can't be reified");
            }
            checkUnknownClasses(primitive.inSignature[i]);
        }
        for (int i; i < primitive.outSignature.length; ++i) {
            if (primitive.outSignature[i].isAny) {
                primitive.outSignature[i] = _anyData.get(primitive.outSignature[i].mangledType);
                if (primitive.outSignature[i].base == GrType.Base.void_)
                    throw new Exception("`" ~ getPrettyPrimitive(primitive) ~ "` can't be reified");
            }
            checkUnknownClasses(primitive.outSignature[i]);
        }
        primitive.mangledName = grMangleComposite(primitive.name, primitive.inSignature);
        primitive.index = cast(uint) _primitives.length;
        if (isPrimitiveDeclared(primitive.mangledName))
            throw new Exception("`" ~ getPrettyPrimitive(primitive) ~ "` is already declared");
        _primitives ~= primitive;
        return primitive;
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
        case array:
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
    package bool isSignatureCompatible(GrType[] first, GrType[] second,
        uint fileId, bool isPublic = false) {
        if (first.length != second.length)
            return false;
        __signatureLoop: for (int i; i < first.length; ++i) {
            if (first[i].base == GrType.Base.null_
                && (second[i].base == GrType.Base.foreign
                    || second[i].base == GrType.Base.class_))
                continue;
            if (first[i].base == GrType.Base.foreign && second[i].base == GrType.Base.foreign) {
                for (;;) {
                    if (first[i] == second[i])
                        continue __signatureLoop;
                    const GrForeignDefinition foreignType = getForeign(first[i].mangledType);
                    if (!foreignType.parent.length)
                        return false;
                    first[i].mangledType = foreignType.parent;
                }
            }
            else if (first[i].base == GrType.Base.class_
                && second[i].base == GrType.Base.class_) {
                for (;;) {
                    if (first[i] == second[i])
                        continue __signatureLoop;
                    const GrClassDefinition classType = getClass(first[i].mangledType,
                        fileId, isPublic);
                    if (!classType.parent.length)
                        return false;
                    first[i].mangledType = classType.parent;
                }
            }
            else if (first[i] != second[i]) {
                return false;
            }
        }
        return true;
    }
    /// Ditto
    private bool isAbstractSignatureCompatible(GrType[] first, GrType[] second, uint fileId, bool isPublic = false) {
        if (first.length != second.length)
            return false;
        __signatureLoop: for (int i; i < first.length; ++i) {
            if (second[i].isAny) {
                const GrType registeredType = _anyData.get(second[i].mangledType);
                if (registeredType.base == GrType.Base.void_) {
                    _anyData.set(second[i].mangledType, first[i]);
                }
                else {
                    if (registeredType != first[i])
                        return false;
                }
                if (!second[i].predicate)
                    return false;
                if (!second[i].predicate(first[i], _anyData))
                    return false;
                continue;
            }
            if (first[i].base == GrType.Base.null_
                && (second[i].base == GrType.Base.foreign
                    || second[i].base == GrType.Base.class_))
                continue;
            if (first[i].base == GrType.Base.foreign && second[i].base == GrType.Base.foreign) {
                for (;;) {
                    if (first[i] == second[i])
                        continue __signatureLoop;
                    const GrForeignDefinition foreignType = getForeign(first[i].mangledType);
                    if (!foreignType.parent.length)
                        return false;
                    first[i].mangledType = foreignType.parent;
                }
            }
            else if (first[i].base == GrType.Base.class_
                && second[i].base == GrType.Base.class_) {
                for (;;) {
                    if (first[i] == second[i])
                        continue __signatureLoop;
                    const GrClassDefinition classType = getClass(first[i].mangledType,
                        fileId, isPublic);
                    if (!classType.parent.length)
                        return false;
                    first[i].mangledType = classType.parent;
                }
            }
            else if (first[i] != second[i]) {
                return false;
            }
        }
        return true;
    }

    /**
    Prettify a primitive signature.
    */
    private string getPrimitiveDisplayById(uint id) {
        if (id >= _primitives.length)
            throw new Exception("invalid primitive id");
        return getPrettyPrimitive(_primitives[id]);
    }

    private string getPrettyPrimitive(GrPrimitive primitive) {
        import std.conv : to;

        string result = primitive.name;
        auto nbParameters = primitive.inSignature.length;
        if (primitive.name == "@as")
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
