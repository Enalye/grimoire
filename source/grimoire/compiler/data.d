module grimoire.compiler.data;

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
        dstring[] _userTypes;
        /// Object types.
        GrObjectDefinition[] _objectTypes;
        /// Tuples types.
        GrTupleDefinition[dstring] _tupleTypes;

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

    /// Define an opaque pointer type.
    GrType addUserType(dstring name) {
        bool isDeclared;
        foreach(usertype; _userTypes) {
            if(usertype == name)
                isDeclared = true;
        }

        if(!isDeclared)
            _userTypes ~= name;

        GrType type = GrBaseType.UserType;
        type.mangledType = name;
        return type;
    }

    /// Is the user-type defined ?
    bool isUserType(dstring name) {
        foreach(usertype; _userTypes) {
            if(usertype == name)
                return true;
        }
        return false;
    }

    /// Define a tuple type.
    GrType addTuple(dstring name, dstring[] fields, GrType[] signature) {
        assert(fields.length == signature.length, "GrTupleDefinition signature mismatch");
        GrTupleDefinition tuple = new GrTupleDefinition;
        tuple.signature = signature;
        tuple.fields = fields;
        _tupleTypes[name] = tuple;

        GrType stType = GrBaseType.TupleType;
        stType.mangledType = name;
        return stType;
    }

    /// Is the tuple defined ?
    bool isTuple(dstring name) {
        if(name in _tupleTypes)
            return true;
        return false;
    }

    /// Return the tuple definition.
    GrTupleDefinition getTuple(dstring name) {
        import std.conv: to;
        auto tuple = (name in _tupleTypes);
        assert(tuple !is null, "Undefined tuple \'" ~ to!string(name) ~ "\'");
        return *tuple;
    }

    /// Defined a struct type.
    GrType addObject(dstring name, dstring[] fields, GrType[] signature) {
        assert(fields.length == signature.length, "GrObjectDefinition signature mismatch");
        GrObjectDefinition object = new GrObjectDefinition;
        object.name = name;
        object.signature = signature;
        object.fields = fields;
        object.index = _objectTypes.length;
        _objectTypes ~= object;

        GrType stType = GrBaseType.ObjectType;
        stType.mangledType = name;
        return stType;
    }

    /// Is the struct defined ?
    bool isObject(dstring name) {
        foreach(object; _objectTypes) {
            if(object.name == name)
                return true;
        }
        return false;
    }

    /// Return the struct definition.
    GrObjectDefinition getObject(dstring name) {
        import std.conv: to;
        foreach(object; _objectTypes) {
            if(object.name == name)
                return object;
        }
        assert(false, "Undefined object \'" ~ to!string(name) ~ "\'");
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
        _primitives ~= primitive;
        return primitive;
    }

    /**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
    */
    GrPrimitive addOperator(GrCallback callback, dstring name, dstring[] parameters, GrType[] inSignature, GrType outType) {
        import std.conv: to;
        assert(inSignature.length <= 2uL, "The operator \'" ~ to!string(name) ~ "\' cannot take more than 2 parameters: " ~ to!string(to!dstring(parameters)));
        return addPrimitive(callback, "@op_" ~ name, parameters, inSignature, [outType]);
    }

    /**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
    */
    GrPrimitive addCast(GrCallback callback, dstring parameter, GrType srcType, GrType dstType, bool isExplicit = false) {
        auto primitive = addPrimitive(callback, "@as", [parameter], [srcType, dstType], [dstType]);
        primitive.isExplicit = isExplicit;
        return primitive;
    }

    bool isPrimitiveDeclared(dstring mangledName) {
        foreach(primitive; _primitives) {
            if(primitive.mangledName == mangledName)
                return true;
        }
        return false;
    }

    GrPrimitive getPrimitive(dstring mangledName) {
        import std.conv: to;
        foreach(primitive; _primitives) {
            if(primitive.mangledName == mangledName)
                return primitive;
        }
        assert(false, "Undeclared primitive " ~ to!string(mangledName));
    }

    string getPrimitiveDisplayById(uint id, bool showParameters = false) {
        import std.conv: to;
        assert(id < _primitives.length, "Invalid primitive id");
        GrPrimitive primitive = _primitives[id];
        
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

    /// Resolve signatures
    package void resolveSignatures() {
        //Resolve all unresolved field types
        resolveTupleSignatures();
        resolveObjectSignatures();

        //Then we can resolve _primitives' signature
        resolvePrimitiveSignatures();
    }

    /// Resolve tuple fields that couldn't be defined beforehand.
    private void resolveTupleSignatures() {
        foreach(tuple; _tupleTypes) {
            for(int i; i < tuple.signature.length; i ++) {
                if(tuple.signature[i].baseType == GrBaseType.VoidType) {
                    assert(isTuple(tuple.signature[i].mangledType), "Cannot resolve tuple field");
                    tuple.signature[i].baseType = GrBaseType.TupleType;
                }
            }
        }
    }

    /// Resolve struct fields that couldn't be defined beforehand.
    private void resolveObjectSignatures() {
        foreach(object; _objectTypes) {
            for(int i; i < object.signature.length; i ++) {
                if(object.signature[i].baseType == GrBaseType.VoidType) {
                    assert(isObject(object.signature[i].mangledType), "Cannot resolve object field");
                    object.signature[i].baseType = GrBaseType.ObjectType;
                }
            }
        }
    }

    /// Initialize every primitives.
    private void resolvePrimitiveSignatures() {
        foreach(primitive; _primitives) {
            primitive.callObject.setup();
        }
    }
}