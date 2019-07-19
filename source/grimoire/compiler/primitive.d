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
	GrType[] inSignature;
	GrType[] outSignature;
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

        dstring[] _ilocals, _flocals, _slocals, _vlocals, _olocals;
        int _iparams, _fparams, _sparams, _vparams, _oparams;
        int _iresults, _fresults, _sresults, _vresults, _oresults;
        bool _hasResult, _isInitialized;
    }

    @property {
        bool hasResult(bool newHasResult) { return _hasResult = newHasResult; }

        /// Current task running the primitive.
        GrContext context() { return _context; }

        /// Extra type compiler information.
        dstring meta() const { return _context.engine.meta; }
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
        _vparams = 0;
        _oparams = 0;

        auto inSignature =  _primitive.inSignature;
        if(_primitive.name == "@as")
            inSignature.length = 1;
        
        setupLocals("", _primitive.parameters, inSignature);
    }

    private void setupLocals(dstring prefix, dstring[] parameters, GrType[] inSignature) {
        if(inSignature.length != parameters.length) {
            writeln("Err: ", inSignature, ", ", parameters);
            throw new Exception("Setup locals error");
        }

        for(int i; i < inSignature.length; i ++) {
            GrType type = inSignature[i];
            dstring name = prefix ~ parameters[i];
            switch(type.baseType) with(GrBaseType) {
            case BoolType:
            case IntType:
            case FunctionType:
            case TaskType:
            case ChanType:
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
            case VariantType:
                _vparams ++;
                _vlocals ~= name;
                break;
            case TupleType:
                auto structure = grGetTuple(type.mangledType);
                setupLocals(name ~ ".", structure.fields, structure.signature);
                break;
            case ArrayType:
            case UserType:
                _oparams ++;
                _olocals ~= name;
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
        _vresults = 0;
        _oresults = 0;
        _hasError = false;

        _context = context;
        _callback(this);
        
        _context.istackPos -= (_iparams - _iresults);
        _context.fstackPos -= (_fparams - _fresults);
        _context.sstackPos -= (_sparams - _sresults);
        _context.vstackPos -= (_vparams - _vresults);
        _context.ostackPos -= (_oparams - _oresults);

        if(_hasError)
            dispatchError();
    }

    alias getString = getParameter!dstring;
    alias getBool = getParameter!bool;
    alias getInt = getParameter!int;
    alias getFloat = getParameter!float;
    alias getVariant = getParameter!GrVariantValue;
    alias getArray = getUserData!GrArray;

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
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
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
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
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
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
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
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.sstack[(_context.sstackPos - _sparams) + index + 1];
        }
        else static if(is(T == GrVariantValue)) {
            int index;
            for(; index < _vlocals.length; index ++) {
                if(parameter == _vlocals[index])
                    break;
            }
            if(index == _vlocals.length)
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.vstack[(_context.vstackPos - _vparams) + index + 1];
        }
        else static if(is(T == void*)) {
            int index;
            for(; index < _olocals.length; index ++) {
                if(parameter == _olocals[index])
                    break;
            }
            if(index == _olocals.length)
                throw new Exception("Primitive \'" ~ grGetPrimitiveDisplayById(_primitive.index, true)
                    ~ "\' do not have a parameter called \'" ~ to!string(parameter) ~ "\'");
            return _context.ostack[(_context.ostackPos - _oparams) + index + 1];
        }
    }

    alias setString = setResult!dstring;
    alias setBool = setResult!bool;
    alias setInt = setResult!int;
    alias setFloat = setResult!float;
    alias setVariant = setResult!GrVariantValue;
    alias setArray = setUserData!GrArray;
    
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
        else static if(is(T == GrVariantValue)) {
            _vresults ++;
            _context.vstack[(_context.vstackPos - _vparams) + _vresults] = value;
        }
        else static if(is(T == void*)) {
            _oresults ++;
            _context.ostack[(_context.ostackPos - _oparams) + _oresults] = value;
        }
    }

    private {
        dstring _message;
        bool _hasError;
    }

    /// Does not actually send the error to the context.
    /// Because the stacks would be in an undefined state.
    /// So we wait until the primitive is finished before calling dispatchError().
    void raise(dstring message) {
        _message = message;
        _hasError = true;
    }

    private void dispatchError() {
        _context.engine.raise(_context, _message);

        //The context is still in a primitive call
        //and will increment the pc, so we prevent that.
        _context.pc --;
    }
}

/**
    Define a new primitive.
*/
GrPrimitive grAddPrimitive(GrCallback callback, dstring name, dstring[] parameters, GrType[] inSignature, GrType[] outSignature = []) {
	GrPrimitive primitive = new GrPrimitive;
	primitive.callback = callback;
	primitive.inSignature = inSignature;
	primitive.parameters = parameters;
	primitive.outSignature = outSignature;
	primitive.name = name;
	primitive.mangledName = grMangleNamedFunction(name, inSignature);
	primitive.index = cast(uint)primitives.length;
    primitive.callObject = new GrCall(primitive);
	primitives ~= primitive;
    return primitive;
}

/**
    An operator is a function that replace a binary or unary grimoire operator such as `+`, `==`, etc
    The name of the function must be that of the operator like "+", "-", "or", etc.
*/
GrPrimitive grAddOperator(GrCallback callback, dstring name, dstring[] parameters, GrType[] inSignature, GrType outType) {
    if(inSignature.length > 2uL)
        throw new Exception("The operator \'" ~ to!string(name) ~ "\' cannot take more than 2 parameters: " ~ to!string(to!dstring(parameters)));
	return grAddPrimitive(callback, "@op_" ~ name, parameters, inSignature, [outType]);
}

/**
    A cast operator allows to convert from one type to another.
    It have to have only one parameter and return the casted value.
*/
GrPrimitive grAddCast(GrCallback callback, dstring parameter, GrType srcType, GrType dstType, bool isExplicit = false) {
	auto primitive = grAddPrimitive(callback, "@as", [parameter], [srcType, dstType], [dstType]);
    primitive.isExplicit = isExplicit;
    return primitive;
}

bool grIsPrimitiveDeclared(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return true;
	}
	return false;
}

GrPrimitive grGetPrimitive(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return primitive;
	}
	throw new Exception("Undeclared primitive " ~ to!string(mangledName));
}

string grGetPrimitiveDisplayById(uint id, bool showParameters = false) {
    if(id >= primitives.length)
        throw new Exception("Invalid primitive id.");
    GrPrimitive primitive = primitives[id];
    
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

void grResolvePrimitiveSignature() {
    foreach(primitive; primitives) {
        primitive.callObject.setup();
    }
}