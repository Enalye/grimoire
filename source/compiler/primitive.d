/**
    Primitives are hard-coded grimoire's functions, they are used the same as any other function.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import runtime.all;
import compiler.parser;
import compiler.type;
import compiler.mangle;


GrPrimitive[] primitives;

alias GrCallback = void function(GrCall);

/**
    Primitive.
*/
class GrPrimitive {
	GrCallback callback;
	GrType[] signature;
	GrType returnType;
    dstring[] parameters;
	dstring name, mangledName;
	uint index;
    bool isExplicit;
    GrCall callObject;

    //alias call = callObject.call;
}

class GrCall {
    private {
        GrEngine _vm;
        GrContext _context;

        GrPrimitive _primitive;
        GrCallback _callback;

        dstring[] _locals;
        int _iparams, _fparams, _sparams, _dparams, _nparams;
        bool _hasResult;
    }

    @property {
        bool hasResult(bool newHasResult) { return _hasResult = newHasResult; }
    }

    package this(GrPrimitive primitive) {
        _primitive = primitive;
        _callback = _primitive.callback;
    }

    package void setup() {
        auto signature =  _primitive.signature;
        if(_primitive.name == "@as")
            signature.length = 1;
        
        setupLocals("", _primitive.parameters, signature);
    }

    private void setupLocals(dstring prefix, dstring[] parameters, GrType[] signature) {
        if(signature.length != parameters.length) {
            writeln("Err: ", signature, ", ", parameters);
            throw new Exception("Setup locals error");
        }

        for(int i; i < signature.length; i ++) {
            GrType type = signature[i];
            dstring name = prefix ~ parameters[i];
            switch(type.baseType) with(GrBaseType) {
            case BoolType:
            case IntType:
                _iparams ++;
                _locals ~= name;
                break;
            case FloatType:
                _fparams ++;
                _locals ~= name;
                break;
            case StringType:
                _sparams ++;
                _locals ~= name;
                break;
            case DynamicType:
                _dparams ++;
                _locals ~= name;
                break;
            case ArrayType:
                _nparams ++;
                _locals ~= name;
                break;
            case StructType:
                auto structure = grType_getStructure(type.mangledType);
                setupLocals(name ~ ".", structure.fields, structure.signature);
                break;
            default:
                throw new Exception("Type Error or smthing like that");
            }
        
        }
    }

    void call(GrContext context) {
        _context = context;
        _callback(this);

        _context.istackPos -= _iparams;
        _context.fstackPos -= _fparams;
        _context.sstackPos -= _sparams;
        _context.astackPos -= _dparams;
        _context.nstackPos -= _nparams;
    }

    alias getString = getParameter!dstring;
    alias getBool = getParameter!bool;
    alias getInt = getParameter!int;
    alias getFloat = getParameter!float;
    alias getDynamic = getParameter!GrDynamicValue;
    alias getArray = getParameter!(GrDynamicValue[]);

    private T getParameter(T)(dstring parameter) {
        int index;
        for(; index < _locals.length; index ++) {
            if(parameter == _locals[index])
                break;
        }
        if(index == _locals.length)
            throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
        
        static if(is(T == int)) {
            return _context.istack[(_context.istackPos - _iparams) + index + 1];
        }
        else static if(is(T == bool)) {
            return _context.istack[(_context.istackPos - _iparams) + index + 1] > 0;
        }
        else static if(is(T == float)) {
            return _context.fstack[(_context.fstackPos - _fparams) + index + 1];
        }
        else static if(is(T == dstring)) {
            return _context.sstack[(_context.sstackPos - _sparams) + index + 1];
        }
        else static if(is(T == GrDynamicValue)) {
            return _context.astack[(_context.astackPos - _dparams) + index + 1];
        }
        else static if(is(T == GrDynamicValue[])) {
            return _context.nstack[(_context.nstackPos - _nparams) + index + 1];
        }
    }

    alias setString = setResult!dstring;
    alias setBool = setResult!bool;
    alias setInt = setResult!int;
    alias setFloat = setResult!float;
    alias setDynamic = setResult!GrDynamicValue;
    alias setArray = setResult!(GrDynamicValue[]);

    private void setResult(T)(T value) {
        static if(is(T == int)) {
            _context.istackPos ++;
            _context.istack[_context.istackPos] = value;
        }
        else static if(is(T == bool)) {
            _context.istackPos ++;
            _context.istack[_context.istackPos] = value ? 1 : 0;
        }
        else static if(is(T == float)) {
            _context.fstackPos ++;
            _context.fstack[_context.fstackPos] = value;
        }
        else static if(is(T == dstring)) {
            _context.sstackPos ++;
            _context.sstack[_context.sstackPos] = value;
        }
        else static if(is(T == GrDynamicValue)) {
            _context.astackPos ++;
            _context.astack[_context.astackPos] = value;
        }
        else static if(is(T == GrDynamicValue[])) {
            _context.nstackPos ++;
            _context.nstack[_context.nstackPos] = value;
        }
    }

    private T getParameterDbg(T)() {
        int index;
        /*for(; index < _locals.length; index ++) {
            if(parameter == _locals[index])
                break;
        }
        if(index == _locals.length)
            throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
        */
        static if(is(T == int)) {
            return _context.istack[($ - _iparams) + index];
        }
        else static if(is(T == bool)) {
            return _context.istack[($ - _iparams) + index] > 0;
        }
        else static if(is(T == float)) {
            return _context.fstack[($ - _fparams) + index];
        }
        else static if(is(T == dstring)) {
            return _context.sstack[($ - _sparams) + index];
        }
        else static if(is(T == GrDynamicValue)) {
            return _context.astack[($ - _dparams) + index];
        }
        else static if(is(T == GrDynamicValue[])) {
            return _context.nstack[($ - _nparams) + index];
        }
    }
}

/**
    Define a new primitive.
*/
GrPrimitive grType_addPrimitive(GrCallback callback, dstring name, dstring[] parameters, GrType[] signature, GrType retType = grVoid) {
	GrPrimitive primitive = new GrPrimitive;
	primitive.callback = callback;
	primitive.signature = signature;
	primitive.parameters = parameters;
	primitive.returnType = retType;
	primitive.name = name;
	primitive.mangledName = grType_mangleNamedFunction(name, signature);
	primitive.index = cast(uint)primitives.length;
    primitive.callObject = new GrCall(primitive);
	primitives ~= primitive;
    return primitive;
}

/**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
*/
GrPrimitive grType_addOperator(GrCallback callback, dstring name, dstring[] parameters, GrType[] signature, GrType retType) {
	return grType_addPrimitive(callback, "@op_" ~ name, parameters, signature, retType);
}

/**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
*/
GrPrimitive grType_addCast(GrCallback callback, dstring parameter, GrType srcType, GrType dstType, bool isExplicit = false) {
	auto primitive = grType_addPrimitive(callback, "@as", [parameter], [srcType, dstType], dstType);
    primitive.isExplicit = isExplicit;
    return primitive;
}

bool isPrimitiveDeclared(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return true;
	}
	return false;
}

GrPrimitive grType_getPrimitive(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return primitive;
	}
	throw new Exception("Undeclared primitive " ~ to!string(mangledName));
}

string grType_getPrimitiveDisplayById(uint id, bool showParameters = false) {
    if(id >= primitives.length)
        throw new Exception("Invalid primitive id.");
    GrPrimitive primitive = primitives[id];
    
    string result = to!string(primitive.name);
    auto nbParameters = primitive.signature.length;
    if(primitive.name == "@as")
        nbParameters = 1;
    result ~= "(";
    for(int i; i < nbParameters; i ++) {
        result ~= grType_getDisplay(primitive.signature[i]);
        if(showParameters)
            result ~= " " ~ to!string(primitive.parameters[i]);
        if((i + 2) <= nbParameters)
            result ~= ", ";
    }
    result ~= ")";
    if(primitive.returnType != GrBaseType.VoidType) {
        result ~= " " ~ grType_getDisplay(primitive.returnType);
    }
    return result;
}

void grType_resolvePrimitiveSignature() {
    foreach(primitive; primitives) {
        primitive.callObject.setup();
    }
}