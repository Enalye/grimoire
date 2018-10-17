/**
    Primitives are hard-coded grimoire's functions, they are used the same as any other function.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module grimoire.compiler.primitive;

import std.exception;
import std.conv;
import std.stdio;

import grimoire.runtime;
import grimoire.compiler.parser;
import grimoire.compiler.type;
import grimoire.compiler.mangle;

/// All primitives, used for both the compiler and the runtime.
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
        GrContext _context;
        GrPrimitive _primitive;
        GrCallback _callback;

        dstring[] _ilocals, _flocals, _slocals, _dlocals, _nlocals, _ulocals;
        int _iparams, _fparams, _sparams, _dparams, _nparams, _uparams;
        int _iresults, _fresults, _sresults, _dresults, _nresults, _uresults;
        bool _hasResult, _isInitialized;
    }

    @property {
        bool hasResult(bool newHasResult) { return _hasResult = newHasResult; }

        GrContext context() { return _context; }
    }

    package this(GrPrimitive primitive) {
        _primitive = primitive;
        _callback = _primitive.callback;
    }

    package void setup() {
        if(_isInitialized)
            return;
        _isInitialized = true;

        _iparams = 0;
        _fparams = 0;
        _sparams = 0;
        _dparams = 0;
        _nparams = 0;
        _uparams = 0;

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
                _ilocals ~= name;
                break;
            case FloatType:
                _fparams ++;
                _flocals ~= name;
                break;
            case StringType:
                _sparams ++;
                _slocals ~= name;
                break;
            case DynamicType:
                _dparams ++;
                _dlocals ~= name;
                break;
            case ArrayType:
                _nparams ++;
                _nlocals ~= name;
                break;
            case StructType:
                auto structure = grType_getStructure(type.mangledType);
                setupLocals(name ~ ".", structure.fields, structure.signature);
                break;
            case UserType:
                _uparams ++;
                _ulocals ~= name;
                break;
            default:
                throw new Exception("Type Error or smthing like that");
            }
        }
    }

    void call(GrContext context) {
        _iresults = 0;
        _fresults = 0;
        _sresults = 0;
        _dresults = 0;
        _nresults = 0;
        _uresults = 0;

        _context = context;
        _callback(this);
        
        _context.istackPos -= (_iparams - _iresults);
        _context.fstackPos -= (_fparams - _fresults);
        _context.sstackPos -= (_sparams - _sresults);
        _context.astackPos -= (_dparams - _dresults);
        _context.nstackPos -= (_nparams - _nresults);
        _context.ustackPos -= (_uparams - _uresults);
    }

    alias getString = getParameter!dstring;
    alias getBool = getParameter!bool;
    alias getInt = getParameter!int;
    alias getFloat = getParameter!float;
    alias getDynamic = getParameter!GrDynamicValue;
    alias getArray = getParameter!(GrDynamicValue[]);

    T getUserData(T)(dstring parameter) {
        return cast(T)getParameter!(void*)(parameter);
    }

    private T getParameter(T)(dstring parameter) {
        static if(is(T == int)) {
            int index;
            for(; index < _ilocals.length; index ++) {
                if(parameter == _ilocals[index])
                    break;
            }
            if(index == _ilocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.istack[(_context.istackPos - _iparams) + index + 1];
        }
        else static if(is(T == bool)) {
            int index;
            for(; index < _ilocals.length; index ++) {
                if(parameter == _ilocals[index])
                    break;
            }
            if(index == _ilocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.istack[(_context.istackPos - _iparams) + index + 1] > 0;
        }
        else static if(is(T == float)) {
            int index;
            for(; index < _flocals.length; index ++) {
                if(parameter == _flocals[index])
                    break;
            }
            if(index == _flocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.fstack[(_context.fstackPos - _fparams) + index + 1];
        }
        else static if(is(T == dstring)) {
            int index;
            for(; index < _slocals.length; index ++) {
                if(parameter == _slocals[index])
                    break;
            }
            if(index == _slocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.sstack[(_context.sstackPos - _sparams) + index + 1];
        }
        else static if(is(T == GrDynamicValue)) {
            int index;
            for(; index < _dlocals.length; index ++) {
                if(parameter == _dlocals[index])
                    break;
            }
            if(index == _dlocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.astack[(_context.astackPos - _dparams) + index + 1];
        }
        else static if(is(T == GrDynamicValue[])) {
            int index;
            for(; index < _nlocals.length; index ++) {
                if(parameter == _nlocals[index])
                    break;
            }
            if(index == _nlocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.nstack[(_context.nstackPos - _nparams) + index + 1];
        }
        else static if(is(T == void*)) {
            int index;
            for(; index < _ulocals.length; index ++) {
                if(parameter == _ulocals[index])
                    break;
            }
            if(index == _ulocals.length)
                throw new Exception("Primitive \'" ~ grType_getPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.ustack[(_context.ustackPos - _uparams) + index + 1];
        }
    }

    alias setString = setResult!dstring;
    alias setBool = setResult!bool;
    alias setInt = setResult!int;
    alias setFloat = setResult!float;
    alias setDynamic = setResult!GrDynamicValue;
    alias setArray = setResult!(GrDynamicValue[]);
    
    void setUserData(T)(T value) {
        setResult!(void*)(cast(void*)value);
    }

    private void setResult(T)(T value) {
        static if(is(T == int)) {
            _iresults ++;
            _context.istack[(_context.istackPos - _iparams) + _iresults] = value;
        }
        else static if(is(T == bool)) {
            _iresults ++;
            _context.istack[(_context.istackPos - _iparams) + _iresults] = value ? 1 : 0;
        }
        else static if(is(T == float)) {
            _fresults ++;
            _context.fstack[(_context.fstackPos - _fparams) + _fresults] = value;
        }
        else static if(is(T == dstring)) {
            _sresults ++;
            _context.sstack[(_context.sstackPos - _sparams) + _sresults] = value;
        }
        else static if(is(T == GrDynamicValue)) {
            _dresults ++;
            _context.astack[(_context.astackPos - _dparams) + _dresults] = value;
        }
        else static if(is(T == GrDynamicValue[])) {
            _nresults ++;            
            _context.nstack[(_context.nstackPos - _nparams) + _nresults] = value;
        }
        else static if(is(T == void*)) {
            _uresults ++;
            _context.ustack[(_context.ustackPos - _uparams) + _uresults] = value;
        }
    }

    void raise(dstring message) {
        _context.engine.raise(_context, message);

        //The context is still in a primitive call
        //and will increment the pc, so we prevent that.
        _context.pc --;
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