/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.stdio : writeln;
import std.conv : to;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.array,
    grimoire.runtime.object, grimoire.runtime.channel;

/// Primitive type.
alias GrCallback = void function(GrCall);

/// Primitive context.
final class GrCall {
    private {
        GrContext _context;
        GrCallback _callback;

        uint[] _parameters;
        int _iparams, _fparams, _sparams, _oparams;
        int _iresults, _fresults, _sresults, _oresults;
        bool _isInitialized;
    }

    @property {
        /// Current task running the primitive.
        GrContext context() {
            return _context;
        }

        /// Extra type compiler information.
        string meta() const {
            return _context.engine.meta;
        }
    }

    package(grimoire) this(GrCallback callback, const ref GrBytecode.PrimitiveReference primRef) {
        _callback = callback;

        _parameters = primRef.parameters.dup;

        _iparams = cast(int) primRef.iparams;
        _fparams = cast(int) primRef.fparams;
        _sparams = cast(int) primRef.sparams;
        _oparams = cast(int) primRef.oparams;
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

        if (_hasError)
            dispatchError();
    }

    alias getBool = getParameter!bool;
    alias getInt = getParameter!int;
    alias getFloat = getParameter!float;
    alias getString = getParameter!string;
    alias getPtr = getParameter!(void*);

    GrObject getObject(uint index) {
        return cast(GrObject) getParameter!(void*)(index);
    }

    GrIntArray getIntArray(uint index) {
        return cast(GrIntArray) getParameter!(void*)(index);
    }

    GrFloatArray getFloatArray(uint index) {
        return cast(GrFloatArray) getParameter!(void*)(index);
    }

    GrStringArray getStringArray(uint index) {
        return cast(GrStringArray) getParameter!(void*)(index);
    }

    GrObjectArray getObjectArray(uint index) {
        return cast(GrObjectArray) getParameter!(void*)(index);
    }

    GrIntChannel getIntChannel(uint index) {
        return cast(GrIntChannel) getParameter!(void*)(index);
    }

    GrFloatChannel getFloatChannel(uint index) {
        return cast(GrFloatChannel) getParameter!(void*)(index);
    }

    GrStringChannel getStringChannel(uint index) {
        return cast(GrStringChannel) getParameter!(void*)(index);
    }

    GrObjectChannel getObjectChannel(uint index) {
        return cast(GrObjectChannel) getParameter!(void*)(index);
    }

    T getEnum(T)(immutable string parameter) {
        return cast(T) getInt(parameter);
    }

    T getForeign(T)(uint parameter) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getParameter!(void*)(parameter);
    }

    private T getParameter(T)(uint index) {
        if (index >= _parameters.length)
            throw new Exception("parameter index `" ~ to!string(
                    index) ~ "` exceeds the number of parameters");

        static if (is(T == int)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an int");
            return _context.istack[(_context.istackPos - _iparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == bool)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a bool");
            return _context.istack[(_context.istackPos - _iparams) + (
                        _parameters[index] & 0xFFFF) + 1] > 0;
        }
        else static if (is(T == float)) {
            if ((_parameters[index] & 0x20000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a float");
            return _context.fstack[(_context.fstackPos - _fparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == string)) {
            if ((_parameters[index] & 0x40000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a string");
            return _context.sstack[(_context.sstackPos - _sparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == void*)) {
            if ((_parameters[index] & 0x80000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an object");
            return _context.ostack[(_context.ostackPos - _oparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
    }

    alias setBool = setResult!bool;
    alias setInt = setResult!int;
    alias setFloat = setResult!float;
    alias setString = setResult!string;
    alias setPtr = setResult!(void*);

    void setObject(GrObject value) {
        setResult!(void*)(cast(void*) value);
    }

    void setIntArray(GrIntArray value) {
        setResult!(void*)(cast(void*) value);
    }

    void setFloatArray(GrFloatArray value) {
        setResult!(void*)(cast(void*) value);
    }

    void setStringArray(GrStringArray value) {
        setResult!(void*)(cast(void*) value);
    }

    void setObjectArray(GrObjectArray value) {
        setResult!(void*)(cast(void*) value);
    }

    void setIntChannel(GrIntChannel value) {
        setResult!(void*)(cast(void*) value);
    }

    void setFloatChannel(GrFloatChannel value) {
        setResult!(void*)(cast(void*) value);
    }

    void setStringChannel(GrStringChannel value) {
        setResult!(void*)(cast(void*) value);
    }

    void setObjectChannel(GrObjectChannel value) {
        setResult!(void*)(cast(void*) value);
    }

    void setEnum(T)(T value) {
        setInt(cast(int) value);
    }

    void setForeign(T)(T value) {
        setResult!(void*)(cast(void*) value);
    }

    private void setResult(T)(T value) {
        static if (is(T == int)) {
            _iresults++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if (idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value;
        }
        else static if (is(T == bool)) {
            _iresults++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if (idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value ? 1 : 0;
        }
        else static if (is(T == float)) {
            _fresults++;
            const size_t idx = (_context.fstackPos - _fparams) + _fresults;
            if (idx >= _context.fstack.length)
                _context.fstack.length *= 2;
            _context.fstack[idx] = value;
        }
        else static if (is(T == string)) {
            _sresults++;
            const size_t idx = (_context.sstackPos - _sparams) + _sresults;
            if (idx >= _context.sstack.length)
                _context.sstack.length *= 2;
            _context.sstack[idx] = value;
        }
        else static if (is(T == void*)) {
            _oresults++;
            const size_t idx = (_context.ostackPos - _oparams) + _oresults;
            if (idx >= _context.ostack.length)
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
        _context.pc--;
    }

    /// Create a new object of type `typeName`.
    GrObject createObject(string name) {
        return _context.engine.createObject(name);
    }
}
