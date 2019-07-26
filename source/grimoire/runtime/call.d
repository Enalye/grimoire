module grimoire.runtime.call;

import std.stdio: writeln;
import std.conv: to;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.variant, grimoire.runtime.array;

alias GrCallback = void function(GrCall);

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

    package(grimoire) this(GrPrimitive primitive) {
        _primitive = primitive;
        _callback = _primitive.callback;
    }

    package(grimoire) void setup() {
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
                setupLocals(name ~ ":", structure.fields, structure.signature);
                break;
            case ArrayType:
            case StructType:
            case UserType:
                _oparams ++;
                _olocals ~= name;
                break;
            default:
                throw new Exception("Call object: invalid type during setup");
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
    alias getVariant = getParameter!GrVariant;
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
        else static if(is(T == GrVariant)) {
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
    alias setVariant = setResult!GrVariant;
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
        else static if(is(T == GrVariant)) {
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
