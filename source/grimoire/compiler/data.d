/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.data;

import std.conv: to;
import grimoire.runtime;
import grimoire.compiler.primitive;
import grimoire.compiler.type;
import grimoire.compiler.mangle;

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
        GrForeignDefinition[] _foreigns;
        /// Type aliases
        GrTypeAliasDefinition[] _typeAliases;
        /// Enum types.
        GrEnumDefinition[] _enumTypes;
        /// Object types.
        GrClassDefinition[] _classTypes;

        /// All primitives, used for both the compiler and the runtime.
        GrPrimitive[] _primitives;
    }

    /// Primitive global constants, call registerIntConstant at the start of the parser. \
    /// Not used for now.
    GrType addIntConstant(dstring name, int value) {
        if(value + 1 > value)
            assert(false, "TODO: Implement later");
        return grVoid;
    }

    /// Is a type already declared in this file
    package bool isTypeDeclared(dstring name, uint fileId, bool isPublic) {
        if(isEnum(name, fileId, isPublic))
            return true;
        if(isClass(name, fileId, isPublic))
            return true;
        if(isTypeAlias(name, fileId, isPublic))
            return true;
        if(isForeign(name))
            return true;
        return false;
    }

    /// Is a type already declared in this file
    private bool isTypeDeclared(dstring name) {
        if(isEnum(name))
            return true;
        if(isClass(name))
            return true;
        if(isTypeAlias(name))
            return true;
        if(isForeign(name))
            return true;
        return false;
    }

    /// Define an enum type.
    package GrType addEnum(dstring name, dstring[] fields, uint fileId, bool isPublic) {
        GrEnumDefinition enumDef = new GrEnumDefinition;
        enumDef.name = name;
        enumDef.fields = fields;
        enumDef.index = _enumTypes.length;
        enumDef.fileId = fileId;
        enumDef.isPublic = isPublic;
        _enumTypes ~= enumDef;

        GrType stType = GrBaseType.enum_;
        stType.mangledType = name;
        return stType;
    }

    /// Ditto
    GrType addEnum(dstring name, dstring[] fields) {
        assert(!isTypeDeclared(name), to!string(name) ~ "is already declared");
        GrEnumDefinition enumDef = new GrEnumDefinition;
        enumDef.name = name;
        enumDef.fields = fields;
        enumDef.index = _enumTypes.length;
        enumDef.isPublic = true;
        _enumTypes ~= enumDef;

        GrType stType = GrBaseType.enum_;
        stType.mangledType = name;
        return stType;
    }

    /// Define a class type.
    package GrType addClass(dstring name, dstring parent,
            dstring[] fields, GrType[] signature, bool[] scopes,
            uint fileId, bool isPublic,
            uint position, uint[] fieldsPosition) {
        GrClassDefinition class_ = new GrClassDefinition;
        class_.name = name;
        class_.parent = parent;
        class_.signature = signature;
        class_.fields = fields;
        class_.index = _classTypes.length;
        class_.fileId = fileId;
        class_.isPublic = isPublic;
        class_.position = position;
        _classTypes ~= class_;

        class_.fieldsInfo.length = fields.length;
        for(int i; i < class_.fieldsInfo.length; ++ i) {
            class_.fieldsInfo[i].fileId = fileId;
            class_.fieldsInfo[i].isPublic = scopes[i];
            class_.fieldsInfo[i].position = fieldsPosition[i];
        }

        GrType stType = GrBaseType.class_;
        stType.mangledType = name;
        return stType;
    }

    /// Ditto
    GrType addClass(dstring name, dstring[] fields, GrType[] signature, dstring parent = "") {
        assert(fields.length == signature.length, "Class signature mismatch");
        assert(!isTypeDeclared(name), to!string(name) ~ "is already declared");
        GrClassDefinition class_ = new GrClassDefinition;
        class_.name = name;
        class_.parent = parent;
        class_.signature = signature;
        class_.fields = fields;
        class_.index = _classTypes.length;
        class_.isPublic = true;
        _classTypes ~= class_;

        class_.fieldsInfo.length = fields.length;
        for(int i; i < class_.fieldsInfo.length; ++ i) {
            class_.fieldsInfo[i].fileId = 0;
            class_.fieldsInfo[i].isPublic = true;
            class_.fieldsInfo[i].position = 0;
        }

        GrType stType = GrBaseType.class_;
        stType.mangledType = name;
        return stType;
    }

    /// Define an alias of another type.
    package GrType addTypeAlias(dstring name, GrType type, uint fileId, bool isPublic) {
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.fileId = fileId;
        typeAlias.isPublic = isPublic;
        _typeAliases ~= typeAlias;
        return type;
    }

    /// Ditto
    GrType addTypeAlias(dstring name, GrType type) {
        assert(!isTypeDeclared(name), to!string(name) ~ "is already declared");
        GrTypeAliasDefinition typeAlias = new GrTypeAliasDefinition;
        typeAlias.name = name;
        typeAlias.type = type;
        typeAlias.isPublic = true;
        _typeAliases ~= typeAlias;
        return type;
    }

    /// Define an opaque pointer type.
    GrType addForeign(dstring name, dstring parent = "") {
        assert(!isTypeDeclared(name), to!string(name) ~ "is already declared");
        assert(name != parent, to!string(name) ~ ", you can't be your own parent");
        GrForeignDefinition foreign = new GrForeignDefinition;
        foreign.name = name;
        foreign.parent = parent;
        _foreigns ~= foreign;
        GrType type = GrBaseType.foreign;
        type.mangledType = name;
        return type;
    }

    /// Is the enum defined ?
    package bool isEnum(dstring name, uint fileId, bool isPublic) {
        foreach(enumType; _enumTypes) {
            if(enumType.name == name && (enumType.fileId == fileId || enumType.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isEnum(dstring name) {
        foreach(enumType; _enumTypes) {
            if(enumType.name == name)
                return true;
        }
        return false;
    }

    /// Is the class defined ?
    package bool isClass(dstring name, uint fileId, bool isPublic) {
        foreach(class_; _classTypes) {
            if(class_.name == name && (class_.fileId == fileId || class_.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isClass(dstring name) {
        foreach(class_; _classTypes) {
            if(class_.name == name)
                return true;
        }
        return false;
    }

    /// Is the type alias defined ?
    package bool isTypeAlias(dstring name, uint fileId, bool isPublic) {
        foreach(typeAlias; _typeAliases) {
            if(typeAlias.name == name && (typeAlias.fileId == fileId || typeAlias.isPublic || isPublic))
                return true;
        }
        return false;
    }

    /// Ditto
    private bool isTypeAlias(dstring name) {
        foreach(typeAlias; _typeAliases) {
            if(typeAlias.name == name)
                return true;
        }
        return false;
    }

    /// Is the user-type defined ?
    package bool isForeign(dstring name) {
        foreach(foreign; _foreigns) {
            if(foreign.name == name)
                return true;
        }
        return false;
    }

    /// Return the user-type definition.
    GrForeignDefinition getForeign(dstring name) {
        foreach(foreign; _foreigns) {
            if(foreign.name == name)
                return foreign;
        }
        assert(false, "Undefined foreign \'" ~ to!string(name) ~ "\'");
    }

    /// Return the enum definition.
    GrEnumDefinition getEnum(dstring name, uint fileId) {
        import std.conv: to;
        foreach(enumType; _enumTypes) {
            if(enumType.name == name && (enumType.fileId == fileId || enumType.isPublic))
                return enumType;
        }
        assert(false, "Undefined enum \'" ~ to!string(name) ~ "\'");
    }

    /// Return the class definition.
    package GrClassDefinition getClass(dstring name, uint fileId, bool isPublic = false) {
        import std.conv: to;
        foreach(class_; _classTypes) {
            if(class_.name == name && (class_.fileId == fileId || class_.isPublic || isPublic))
                return class_;
        }
        return null;
    }

    /// Return the type alias definition.
    GrTypeAliasDefinition getTypeAlias(dstring name, uint fileId) {
        import std.conv: to;
        foreach(typeAlias; _typeAliases) {
            if(typeAlias.name == name && (typeAlias.fileId == fileId || typeAlias.isPublic))
                return typeAlias;
        }
        assert(false, "Undefined  \'" ~ to!string(name) ~ "\'");
    }

    /**
    Define a new primitive.
    */
    GrPrimitive addPrimitive(GrCallback callback, dstring name,
        dstring[] parameters, GrType[] inSignature, GrType[] outSignature = []) {
        GrPrimitive primitive = new GrPrimitive;
        primitive.callback = callback;
        primitive.inSignature = inSignature;
        primitive.parameters = parameters;
        primitive.outSignature = outSignature;
        primitive.name = name;
        primitive.mangledName = grMangleNamedFunction(name, inSignature);
        primitive.index = cast(uint)_primitives.length;
        primitive.callObject = new GrCall(this, primitive);
        assert(!isPrimitiveDeclared(primitive.mangledName),
            "\'" ~ getPrettyPrimitive(primitive, true) ~ "\' is already declared");
        _primitives ~= primitive;
        return primitive;
    }

    /**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
    */
    GrPrimitive addOperator(GrCallback callback, dstring name,
        dstring[] parameters, GrType[] inSignature, GrType outType) {
        import std.conv: to;
        assert(inSignature.length <= 2uL,
            "The operator \'" ~ to!string(name) ~
            "\' cannot take more than 2 parameters: " ~
            to!string(to!dstring(parameters)));
        return addPrimitive(callback, "@op_" ~ name, parameters, inSignature, [outType]);
    }

    /**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
    */
    GrPrimitive addCast(GrCallback callback, dstring parameter,
        GrType srcType, GrType dstType, bool isExplicit = false) {
        auto primitive = addPrimitive(callback, "@as", [parameter], [srcType, dstType], [dstType]);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    /**
    Is the primitive already declared ?
    */
    bool isPrimitiveDeclared(dstring mangledName) {
        foreach(primitive; _primitives) {
            if(primitive.mangledName == mangledName)
                return true;
        }
        return false;
    }

    /**
    Returns the declared primitive definition.
    */
    GrPrimitive getPrimitive(dstring mangledName) {
        import std.conv: to;
        foreach(primitive; _primitives) {
            if(primitive.mangledName == mangledName)
                return primitive;
        }
        assert(false, "Undeclared primitive " ~ to!string(mangledName));
    }

    /// Ditto
    package GrPrimitive getPrimitive(dstring name, GrType[] signature) {
        const dstring mangledName = grMangleNamedFunction(name, signature);
        foreach(GrPrimitive primitive; _primitives) {
            if(primitive.name == name) {
                if(primitive.mangledName == mangledName)
                    return primitive;
            }
        }
        foreach(GrPrimitive primitive; _primitives) {
            if(primitive.name == name) {
                if(isSignatureCompatible(signature, primitive.inSignature, 0, true))
                    return primitive;
            }
        }
        return null;
    }

    /// Check if the first signature match or can be upgraded (by inheritance) to the second one.
    package bool isSignatureCompatible(GrType[] first, GrType[] second, uint fileId, bool isPublic = false) {
        if (first.length != second.length)
            return false;
        __signatureLoop: for (int i; i < first.length; ++ i) {
            if(first[i].baseType == GrBaseType.foreign && second[i].baseType == GrBaseType.foreign) {
                for(;;) {
                    if(first[i] == second[i])
                        continue __signatureLoop;
                    const GrForeignDefinition foreignType = getForeign(first[i].mangledType);
                    if(!foreignType.parent.length)
                        return false;
                    first[i].mangledType = foreignType.parent;
                }
            }
            else if(first[i].baseType == GrBaseType.class_ && second[i].baseType == GrBaseType.class_) {
                for(;;) {
                    if(first[i] == second[i])
                        continue __signatureLoop;
                    const GrClassDefinition classType = getClass(first[i].mangledType, fileId, isPublic);
                    if(!classType.parent.length)
                        return false;
                    first[i].mangledType = classType.parent;
                }
            }
            else if(first[i] != second[i]) {
                return false;
            }
        }
        return true;
    }

    /**
    Prettify a primitive signature.
    */
    string getPrimitiveDisplayById(uint id, bool showParameters = false) {
        assert(id < _primitives.length, "Invalid primitive id");
        return getPrettyPrimitive(_primitives[id], showParameters);
    }

    private string getPrettyPrimitive(GrPrimitive primitive, bool showParameters = false) {
        import std.conv: to;
        string result = to!string(primitive.name);
        auto nbParameters = primitive.inSignature.length;
        if(primitive.name == "@as")
            nbParameters = 1;
        result ~= "(";
        for(int i; i < nbParameters; i ++) {
            result ~= grGetPrettyType(primitive.inSignature[i]);
            if(showParameters)
                result ~= " " ~ to!string(primitive.parameters[i]);
            if((i + 2) <= nbParameters)
                result ~= ", ";
        }
        result ~= ")";
        for(int i; i < primitive.outSignature.length; i ++) {
            result ~= i ? ", " : " ";
            result ~= grGetPrettyType(primitive.outSignature[i]);
        }
        return result;
    }
}