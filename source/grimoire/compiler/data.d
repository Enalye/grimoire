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
        dstring[] _userTypes;
        GrStruct[] _structures;
        GrTuple[dstring] _tuples;

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
        assert(fields.length == signature.length, "GrTuple signature mismatch");
        GrTuple st = new GrTuple;
        st.signature = signature;
        st.fields = fields;
        _tuples[name] = st;

        GrType stType = GrBaseType.TupleType;
        stType.mangledType = name;
        return stType;
    }

    /// Is the tuple defined ?
    bool isTuple(dstring name) {
        if(name in _tuples)
            return true;
        return false;
    }

    /// Return the tuple definition.
    GrTuple getTuple(dstring name) {
        import std.conv: to;
        auto tuple = (name in _tuples);
        assert(tuple !is null, "Undefined tuple \'" ~ to!string(name) ~ "\'");
        return *tuple;
    }

    /// Defined a struct type.
    GrType addStruct(dstring name, dstring[] fields, GrType[] signature) {
        assert(fields.length == signature.length, "GrStruct signature mismatch");
        GrStruct st = new GrStruct;
        st.name = name;
        st.signature = signature;
        st.fields = fields;
        st.index = _structures.length;
        _structures ~= st;

        GrType stType = GrBaseType.StructType;
        stType.mangledType = name;
        return stType;
    }

    /// Is the struct defined ?
    bool isStruct(dstring name) {
        foreach(structure; _structures) {
            if(structure.name == name)
                return true;
        }
        return false;
    }

    /// Return the struct definition.
    GrStruct getStruct(dstring name) {
        import std.conv: to;
        foreach(structure; _structures) {
            if(structure.name == name)
                return structure;
        }
        assert(false, "Undefined structure \'" ~ to!string(name) ~ "\'");
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

    /// Resolve tuple fields that couldn't be defined beforehand.
    void resolveTupleSignature() {
        foreach(tuple; _tuples) {
            for(int i; i < tuple.signature.length; i ++) {
                if(tuple.signature[i].baseType == GrBaseType.VoidType) {
                    assert(isTuple(tuple.signature[i].mangledType), "Cannot resolve tuple field");
                    tuple.signature[i].baseType = GrBaseType.TupleType;
                }
            }
        }
    }

    /// Resolve struct fields that couldn't be defined beforehand.
    void resolveStructSignature() {
        foreach(structure; _structures) {
            for(int i; i < structure.signature.length; i ++) {
                if(structure.signature[i].baseType == GrBaseType.VoidType) {
                    assert(isStruct(structure.signature[i].mangledType), "Cannot resolve structure field");
                    structure.signature[i].baseType = GrBaseType.StructType;
                }
            }
        }
    }

    /// Initialize every primitives.
    void resolvePrimitiveSignature() {
        foreach(primitive; _primitives) {
            primitive.callObject.setup();
        }
    }
}