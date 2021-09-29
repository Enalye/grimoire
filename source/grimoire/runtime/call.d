/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

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

    alias getBool = getParameter!GrBool;
    alias getInt = getParameter!GrInt;
    alias getFloat = getParameter!GrFloat;
    alias getString = getParameter!GrString;
    alias getPtr = getParameter!GrPtr;

    GrObject getObject(uint index) {
        return cast(GrObject) getParameter!(GrPtr)(index);
    }

    GrArray!T getArray(T)(uint index) {
        return cast(GrArray!T) getParameter!(GrPtr)(index);
    }

    GrIntArray getIntArray(uint index) {
        return cast(GrIntArray) getParameter!(GrPtr)(index);
    }

    GrFloatArray getFloatArray(uint index) {
        return cast(GrFloatArray) getParameter!(GrPtr)(index);
    }

    GrStringArray getStringArray(uint index) {
        return cast(GrStringArray) getParameter!(GrPtr)(index);
    }

    GrObjectArray getObjectArray(uint index) {
        return cast(GrObjectArray) getParameter!(GrPtr)(index);
    }

    GrIntChannel getIntChannel(uint index) {
        return cast(GrIntChannel) getParameter!(GrPtr)(index);
    }

    GrFloatChannel getFloatChannel(uint index) {
        return cast(GrFloatChannel) getParameter!(GrPtr)(index);
    }

    GrStringChannel getStringChannel(uint index) {
        return cast(GrStringChannel) getParameter!(GrPtr)(index);
    }

    GrObjectChannel getObjectChannel(uint index) {
        return cast(GrObjectChannel) getParameter!(GrPtr)(index);
    }

    T getEnum(T)(uint index) {
        return cast(T) getParameter!GrInt(index);
    }

    T getForeign(T)(uint parameter) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getParameter!(GrPtr)(parameter);
    }

    private T getParameter(T)(uint index) {
        if (index >= _parameters.length)
            throw new Exception("parameter index `" ~ to!string(
                    index) ~ "` exceeds the number of parameters");

        static if (is(T == GrInt)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an int");
            return _context.istack[(_context.istackPos - _iparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == GrBool)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a bool");
            return _context.istack[(_context.istackPos - _iparams) + (
                        _parameters[index] & 0xFFFF) + 1] > 0;
        }
        else static if (is(T == GrFloat)) {
            if ((_parameters[index] & 0x20000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a GrFloat");
            return _context.fstack[(_context.fstackPos - _fparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == GrString)) {
            if ((_parameters[index] & 0x40000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a string");
            return _context.sstack[(_context.sstackPos - _sparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
        else static if (is(T == GrPtr)) {
            if ((_parameters[index] & 0x80000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an object");
            return _context.ostack[(_context.ostackPos - _oparams) + (_parameters[index] & 0xFFFF)
                + 1];
        }
    }

    alias setBool = setResult!GrBool;
    alias setInt = setResult!GrInt;
    alias setFloat = setResult!GrFloat;
    alias setString = setResult!GrString;
    alias setPtr = setResult!(GrPtr);

    void setObject(GrObject value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setArray(T)(GrArray!T value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setIntArray(GrIntArray value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setFloatArray(GrFloatArray value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setStringArray(GrStringArray value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setObjectArray(GrObjectArray value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setIntChannel(GrIntChannel value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setFloatChannel(GrFloatChannel value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setStringChannel(GrStringChannel value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setObjectChannel(GrObjectChannel value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    void setEnum(T)(T value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setForeign(T)(T value) {
        setResult!(GrPtr)(cast(GrPtr) value);
    }

    private void setResult(T)(T value) {
        static if (is(T == GrInt)) {
            _iresults++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if (idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value;
        }
        else static if (is(T == GrBool)) {
            _iresults++;
            const size_t idx = (_context.istackPos - _iparams) + _iresults;
            if (idx >= _context.istack.length)
                _context.istack.length *= 2;
            _context.istack[idx] = value ? 1 : 0;
        }
        else static if (is(T == GrFloat)) {
            _fresults++;
            const size_t idx = (_context.fstackPos - _fparams) + _fresults;
            if (idx >= _context.fstack.length)
                _context.fstack.length *= 2;
            _context.fstack[idx] = value;
        }
        else static if (is(T == GrString)) {
            _sresults++;
            const size_t idx = (_context.sstackPos - _sparams) + _sresults;
            if (idx >= _context.sstack.length)
                _context.sstack.length *= 2;
            _context.sstack[idx] = value;
        }
        else static if (is(T == GrPtr)) {
            _oresults++;
            const size_t idx = (_context.ostackPos - _oparams) + _oresults;
            if (idx >= _context.ostack.length)
                _context.ostack.length *= 2;
            _context.ostack[idx] = value;
        }
    }

    GrBool getBoolVariable(string name) {
        return _context.engine.getBoolVariable(name);
    }

    GrInt getIntVariable(string name) {
        return _context.engine.getIntVariable(name);
    }

    GrFloat getFloatVariable(string name) {
        return _context.engine.getFloatVariable(name);
    }

    GrString getStringVariable(string name) {
        return _context.engine.getStringVariable(name);
    }

    GrPtr getPtrVariable(string name) {
        return _context.engine.getPtrVariable(name);
    }

    GrObject getObjectVariable(string name) {
        return _context.engine.getObjectVariable(name);
    }

    GrIntArray getIntArrayVariable(string name) {
        return _context.engine.getIntArrayVariable(name);
    }

    GrFloatArray getFloatArrayVariable(string name) {
        return _context.engine.getFloatArrayVariable(name);
    }

    GrStringArray getStringArrayVariable(string name) {
        return _context.engine.getStringArrayVariable(name);
    }

    GrObjectArray getObjectArrayVariable(string name) {
        return _context.engine.getObjectArrayVariable(name);
    }

    GrIntChannel getIntChannelVariable(string name) {
        return _context.engine.getIntChannelVariable(name);
    }

    GrFloatChannel getFloatChannelVariable(string name) {
        return _context.engine.getFloatChannelVariable(name);
    }

    GrStringChannel getStringChannelVariable(string name) {
        return _context.engine.getStringChannelVariable(name);
    }

    GrObjectChannel getObjectChannelVariable(string name) {
        return _context.engine.getObjectChannelVariable(name);
    }

    T getEnumVariable(T)(string name) {
        return _context.engine.getEnumVariable(T)(name);
    }

    T getForeignVariable(T)(string name) {
        return _context.engine.getForeignVariable(T)(name);
    }

    void setBoolVariable(string name, GrBool value) {
        _context.engine.setBoolVariable(name, value);
    }

    void setIntVariable(string name, GrInt value) {
        _context.engine.setIntVariable(name, value);
    }

    void setFloatVariable(string name, GrFloat value) {
        _context.engine.setFloatVariable(name, value);
    }

    void setStringVariable(string name, GrString value) {
        _context.engine.setStringVariable(name, value);
    }

    void setPtrVariable(string name, GrPtr value) {
        _context.engine.setPtrVariable(name, value);
    }

    void setObjectVariable(string name, GrObject value) {
        _context.engine.setObjectVariable(name, value);
    }

    void setIntArrayVariable(string name, GrIntArray value) {
        _context.engine.setIntArrayVariable(name, value);
    }

    void setFloatArrayVariable(string name, GrFloatArray value) {
        _context.engine.setFloatArrayVariable(name, value);
    }

    void setStringArrayVariable(string name, GrStringArray value) {
        _context.engine.setStringArrayVariable(name, value);
    }

    void setObjectArrayVariable(string name, GrObjectArray value) {
        _context.engine.setObjectArrayVariable(name, value);
    }

    void setIntChannelVariable(string name, GrIntChannel value) {
        _context.engine.setIntChannelVariable(name, value);
    }

    void setFloatChannelVariable(string name, GrFloatChannel value) {
        _context.engine.setFloatChannelVariable(name, value);
    }

    void setStringChannelVariable(string name, GrStringChannel value) {
        _context.engine.setStringChannelVariable(name, value);
    }

    void setObjectChannelVariable(string name, GrObjectChannel value) {
        _context.engine.setObjectChannelVariable(name, value);
    }

    void setEnumVariable(T)(string name, T value) {
        _context.engine.setEnumVariable(name, value);
    }

    void setForeignVariable(T)(string name, T value) {
        _context.engine.setForeignVariable(name, value);
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

    /// Pause the current context.
    void block(GrBlocker blocker) {
        _context.block(blocker);
    }
}
