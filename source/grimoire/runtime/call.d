/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.stdio: writeln;
import std.conv: to;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.array, grimoire.runtime.object, grimoire.runtime.channel;

/// Primitive type.
alias GrCallback = void function(GrCall);

/// Primitive context.
class GrCall {
    private {
        GrData _data;
        GrContext _context;
        GrPrimitive _primitive;
        GrCallback _callback;

        string[] _ilocals, _flocals, _slocals, _vlocals, _olocals;
        int _iparams, _fparams, _sparams, _oparams;
        int _iresults, _fresults, _sresults, _vresults, _oresults;
        bool _isInitialized;
    }

    @property {
        /// Current task running the primitive.
        GrContext context() { return _context; }

        /// Extra type compiler information.
        string meta() const { return _context.engine.meta; }
    }

    package(grimoire) this(GrData data, GrPrimitive primitive) {
        _data = data;
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
        _oparams = 0;

        auto inSignature =  _primitive.inSignature;
        if(_primitive.name == "@as")
            inSignature.length = 1;
        
        setupLocals("", _primitive.parameters, inSignature);
    }

    private void setupLocals(string prefix, string[] parameters, GrType[] inSignature) {
        if(inSignature.length != parameters.length) {
            throw new Exception(
                "Locals mismatch in " ~
                grGetPrettyFunctionCall(_primitive.name, inSignature) ~
                "\nThe signature does not match " ~
                to!string(parameters));
        }

        for(int i; i < inSignature.length; i ++) {
            const GrType type = inSignature[i];
            string name = prefix ~ parameters[i];
            final switch(type.baseType) with(GrBaseType) {
            case bool_:
            case int_:
            case function_:
            case task:
            case enum_:
            case chan:
                _iparams ++;
                _ilocals ~= name;
                break;
            case float_:
                _fparams ++;
                _flocals ~= name;
                break;
            case string_:
                _sparams ++;
                _slocals ~= name;
                break;
            case array_:
            case class_:
            case foreign:
                _oparams ++;
                _olocals ~= name;
                break;
            case void_:
            case internalTuple:
            case reference:
            case null_:
                throw new Exception(
                    "Invalid parameter type in " ~
                    grGetPrettyFunctionCall(_primitive.name, inSignature) ~
                    "\nThe type cannot be " ~
                    grGetPrettyType(type));
            }
        }
    }

    /// The actual runtime call to the primitive.
    void call(GrContext context) {
        _iresults = 0;
        _fresults = 0;
        _sresults = 0;
        _oresults = 0;
        _hasError = false;
        _context = context;

        _callback(this);
        
        _context.istackPos -= (_iparams - _iresults);
        _context.fstackPos -= (_fparams - _fresults);
        _context.sstackPos -= (_sparams - _sresults);
        _context.ostackPos -= (_oparams - _oresults);

        if(_hasError)
            dispatchError();
    }

    alias getBool = getParameter!bool;
    alias getInt = getParameter!int;
    alias getFloat = getParameter!float;
    alias getString = getParameter!string;
    alias getPtr = getParameter!(void*);
    alias getObject = getUserData!GrObject;
    alias getIntArray = getUserData!GrIntArray;
    alias getFloatArray = getUserData!GrFloatArray;
    alias getStringArray = getUserData!GrStringArray;
    alias getObjectArray = getUserData!GrObjectArray;
    alias getIntChannel = getUserData!GrIntChannel;
    alias getFloatChannel = getUserData!GrFloatChannel;
    alias getStringChannel = getUserData!GrStringChannel;
    alias getObjectChannel = getUserData!GrObjectChannel;

    T getEnum(T)(string parameter) {
        return cast(T) getInt(parameter);
    }

    T getUserData(T)(string parameter) {
        return cast(T) getParameter!(void*)(parameter);
    }

    private T getParameter(T)(string parameter) {
        static if(is(T == int)) {
            int index;
            for(; index < _ilocals.length; index ++) {
                if(parameter == _ilocals[index])
                    break;
            }
            if(index == _ilocals.length)
                throw new Exception("primitive `" ~ _data.getPrimitiveDisplayById(_primitive.index, true)
                    ~ "` do not have a int parameter called `" ~ parameter ~ "`");
            return _context.istack[(_context.istackPos - _iparams) + index + 1];
        }
        else static if(is(T == bool)) {
            int index;
            for(; index < _ilocals.length; index ++) {
                if(parameter == _ilocals[index])
                    break;
            }
            if(index == _ilocals.length)
                throw new Exception("primitive `" ~ _data.getPrimitiveDisplayById(_primitive.index, true)
                    ~ "` do not have a bool parameter called `" ~ parameter ~ "`");
            return _context.istack[(_context.istackPos - _iparams) + index + 1] > 0;
        }
        else static if(is(T == float)) {
            int index;
            for(; index < _flocals.length; index ++) {
                if(parameter == _flocals[index])
                    break;
            }
            if(index == _flocals.length)
                throw new Exception("primitive `" ~ _data.getPrimitiveDisplayById(_primitive.index, true)
                    ~ "` do not have a float parameter called `" ~ parameter ~ "`");
            return _context.fstack[(_context.fstackPos - _fparams) + index + 1];
        }
        else static if(is(T == string)) {
            int index;
            for(; index < _slocals.length; index ++) {
                if(parameter == _slocals[index])
                    break;
            }
            if(index == _slocals.length)
                throw new Exception("primitive `" ~ _data.getPrimitiveDisplayById(_primitive.index, true)
                    ~ "` do not have a string parameter called `" ~ parameter ~ "`");
            return _context.sstack[(_context.sstackPos - _sparams) + index + 1];
        }
        else static if(is(T == void*)) {
            int index;
            for(; index < _olocals.length; index ++) {
                if(parameter == _olocals[index])
                    break;
            }
            if(index == _olocals.length)
                throw new Exception("primitive `" ~ _data.getPrimitiveDisplayById(_primitive.index, true)
                    ~ "` do not have an object parameter called `" ~ parameter ~ "`");
            return _context.ostack[(_context.ostackPos - _oparams) + index + 1];
        }
    }

    alias setBool = setResult!bool;
    alias setInt = setResult!int;
    alias setFloat = setResult!float;
    alias setString = setResult!string;
    alias setPtr = setResult!(void*);
    alias setObject = setUserData!GrObject;
    alias setIntArray = setUserData!GrIntArray;
    alias setFloatArray = setUserData!GrFloatArray;
    alias setStringArray = setUserData!GrStringArray;
    alias setObjectArray = setUserData!GrObjectArray;
    alias setIntChannel = setUserData!GrIntChannel;
    alias setFloatChannel = setUserData!GrFloatChannel;
    alias setStringChannel = setUserData!GrStringChannel;
    alias setObjectChannel = setUserData!GrObjectChannel;

    void setEnum(T)(T value) {
        setInt(cast(int) value);
    }
    
    void setUserData(T)(T value) {
        setResult!(void*)(cast(void*) value);
    }

    private void setResult(T)(T value) {
        static if(is(T == int)) {
            _iresults ++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if(idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value;
        }
        else static if(is(T == bool)) {
            _iresults ++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if(idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value ? 1 : 0;
        }
        else static if(is(T == float)) {
            _fresults ++;
            const size_t idx = (_context.fstackPos - _fparams) + _fresults;
            if(idx >= _context.fstack.length)
                _context.fstack.length *= 2;
            _context.fstack[idx] = value;
        }
        else static if(is(T == string)) {
            _sresults ++;
            const size_t idx = (_context.sstackPos - _sparams) + _sresults;
            if(idx >= _context.sstack.length)
                _context.sstack.length *= 2;
            _context.sstack[idx] = value;
        }
        else static if(is(T == void*)) {
            _oresults ++;
            const size_t idx = (_context.ostackPos - _oparams) + _oresults;
            if(idx >= _context.ostack.length)
                _context.ostack.length *= 2;
            _context.ostack[idx] = value;
        }
    }

    private {
        string _message;
        bool _hasError;
    }

    /// Does not actually send the error to the context.
    /// Because the stacks would be in an undefined state.
    /// So we wait until the primitive is finished before calling dispatchError().
    void raise(string message) {
        _message = message;
        _hasError = true;
    }

    private void dispatchError() {
        _context.engine.raise(_context, _message);

        //The context is still in a primitive call
        //and will increment the pc, so we prevent that.
        _context.pc --;
    }

    /// Create a new object of type `typeName`.
    GrObject createObject(string typeName) {
        int index;
        for(; index < _data._classTypes.length; index ++) {
            if(typeName == _data._classTypes[index].name)
                return new GrObject(_data._classTypes[index]);
        }
        return null;
    }
}