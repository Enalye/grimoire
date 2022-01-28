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
        int _iparams, _rparams, _sparams, _oparams;
        int _iresults, _rresults, _sresults, _oresults;
        bool _isInitialized;
        string[] _inSignature, _outSignature;
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
        _rparams = cast(int) primRef.fparams;
        _sparams = cast(int) primRef.sparams;
        _oparams = cast(int) primRef.oparams;

        _inSignature = primRef.inSignature.dup;
        _outSignature = primRef.outSignature.dup;
    }

    /// The actual runtime call to the primitive.
    void call(GrContext context) {
        _iresults = 0;
        _rresults = 0;
        _sresults = 0;
        _oresults = 0;
        _hasError = false;
        _context = context;

        _callback(this);

        _context.istackPos -= (_iparams - _iresults);
        _context.rstackPos -= (_rparams - _rresults);
        _context.sstackPos -= (_sparams - _sresults);
        _context.ostackPos -= (_oparams - _oresults);

        if (_hasError)
            dispatchError();
    }

    string getInType(uint index) {
        return _inSignature[index];
    }

    string getOutType(uint index) {
        return _outSignature[index];
    }

    alias getBool = getParameter!GrBool;
    alias getInt = getParameter!GrInt;
    alias getReal = getParameter!GrReal;
    alias getString = getParameter!GrString;
    alias getPtr = getParameter!GrPtr;

    int getInt32(uint index) {
        return cast(int) getParameter!GrInt(index);
    }

    long getInt64(uint index) {
        return cast(long) getParameter!GrInt(index);
    }

    real getReal32(uint index) {
        return cast(real) getParameter!GrReal(index);
    }

    double getReal64(uint index) {
        return cast(double) getParameter!GrReal(index);
    }

    GrObject getObject(uint index) {
        return cast(GrObject) getParameter!GrPtr(index);
    }

    GrArray!T getArray(T)(uint index) {
        return cast(GrArray!T) getParameter!GrPtr(index);
    }

    GrIntArray getIntArray(uint index) {
        return cast(GrIntArray) getParameter!GrPtr(index);
    }

    GrRealArray getRealArray(uint index) {
        return cast(GrRealArray) getParameter!GrPtr(index);
    }

    GrStringArray getStringArray(uint index) {
        return cast(GrStringArray) getParameter!GrPtr(index);
    }

    GrObjectArray getObjectArray(uint index) {
        return cast(GrObjectArray) getParameter!GrPtr(index);
    }

    GrIntChannel getIntChannel(uint index) {
        return cast(GrIntChannel) getParameter!GrPtr(index);
    }

    GrRealChannel getRealChannel(uint index) {
        return cast(GrRealChannel) getParameter!GrPtr(index);
    }

    GrStringChannel getStringChannel(uint index) {
        return cast(GrStringChannel) getParameter!GrPtr(index);
    }

    GrObjectChannel getObjectChannel(uint index) {
        return cast(GrObjectChannel) getParameter!GrPtr(index);
    }

    T getEnum(T)(uint index) {
        return cast(T) getParameter!GrInt(index);
    }

    T getForeign(T)(uint parameter) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getParameter!GrPtr(parameter);
    }

    private T getParameter(T)(uint index)
    in (index < _parameters.length, "parameter index `" ~ to!string(
            index) ~ "` exceeds the number of parameters") {
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
        else static if (is(T == GrReal)) {
            if ((_parameters[index] & 0x20000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a GrReal");
            return _context.rstack[(_context.rstackPos - _rparams) + (_parameters[index] & 0xFFFF)
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
    alias setReal = setResult!GrReal;
    alias setString = setResult!GrString;
    alias setPtr = setResult!GrPtr;

    void setInt32(int value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setInt64(long value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setReal32(real value) {
        setResult!GrReal(cast(GrReal) value);
    }

    void setReal64(double value) {
        setResult!GrReal(cast(GrReal) value);
    }

    void setObject(GrObject value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setArray(T)(GrArray!T value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setIntArray(GrIntArray value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setRealArray(GrRealArray value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setStringArray(GrStringArray value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setObjectArray(GrObjectArray value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setIntChannel(GrIntChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setRealChannel(GrRealChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setStringChannel(GrStringChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setObjectChannel(GrObjectChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setEnum(T)(T value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setForeign(T)(T value) {
        setResult!GrPtr(cast(GrPtr) value);
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
        else static if (is(T == GrReal)) {
            _rresults++;
            const size_t idx = (_context.rstackPos - _rparams) + _rresults;
            if (idx >= _context.rstack.length)
                _context.rstack.length *= 2;
            _context.rstack[idx] = value;
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

    GrReal getRealVariable(string name) {
        return _context.engine.getRealVariable(name);
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

    GrRealArray getRealArrayVariable(string name) {
        return _context.engine.getRealArrayVariable(name);
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

    GrRealChannel getRealChannelVariable(string name) {
        return _context.engine.getRealChannelVariable(name);
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

    void setRealVariable(string name, GrReal value) {
        _context.engine.setRealVariable(name, value);
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

    void setRealArrayVariable(string name, GrRealArray value) {
        _context.engine.setRealArrayVariable(name, value);
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

    void setRealChannelVariable(string name, GrRealChannel value) {
        _context.engine.setRealChannelVariable(name, value);
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

    /**
	Spawn a new coroutine registered as an event. \
	The event's name must be mangled with its signature.
	---
	event myEvent() {
		trace("myEvent was created !");
	}
	---
	*/
    GrContext callEvent(string mangledName) {
        return _context.engine.callEvent(mangledName);
    }

    /**
	Spawn a new coroutine at an arbitrary address. \
	The address needs to correspond to the start of a task, else the VM will crash. \
	*/
    GrContext callAddress(uint pc) {
        return _context.engine.callAddress(pc);
    }

    /// Pause the current context.
    void block(GrBlocker blocker) {
        _context.block(blocker);
    }
}
