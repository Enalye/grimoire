/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.conv : to;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.runtime.context, grimoire.runtime.list,
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
        _fparams = cast(int) primRef.fparams;
        _sparams = cast(int) primRef.sparams;
        _oparams = cast(int) primRef.oparams;

        _inSignature = primRef.inSignature.dup;
        _outSignature = primRef.outSignature.dup;
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

    string getInType(uint index) {
        return _inSignature[index];
    }

    string getOutType(uint index) {
        return _outSignature[index];
    }

    alias getBool = getParameter!GrBool;
    alias getInt = getParameter!GrInt;
    alias getFloat = getParameter!GrFloat;
    alias getString = getParameter!GrString;
    alias getPtr = getParameter!GrPtr;

    int getInt32(uint index) {
        return cast(int) getParameter!GrInt(index);
    }

    long getInt64(uint index) {
        return cast(long) getParameter!GrInt(index);
    }

    float getFloat32(uint index) {
        return cast(float) getParameter!GrFloat(index);
    }

    double getFloat64(uint index) {
        return cast(double) getParameter!GrFloat(index);
    }

    GrObject getObject(uint index) {
        return cast(GrObject) getParameter!GrPtr(index);
    }

    GrList!T getList(T)(uint index) {
        return cast(GrList!T) getParameter!GrPtr(index);
    }

    GrIntList getIntList(uint index) {
        return cast(GrIntList) getParameter!GrPtr(index);
    }

    GrFloatList getFloatList(uint index) {
        return cast(GrFloatList) getParameter!GrPtr(index);
    }

    GrStringList getStringList(uint index) {
        return cast(GrStringList) getParameter!GrPtr(index);
    }

    GrObjectList getObjectList(uint index) {
        return cast(GrObjectList) getParameter!GrPtr(index);
    }

    GrIntChannel getIntChannel(uint index) {
        return cast(GrIntChannel) getParameter!GrPtr(index);
    }

    GrFloatChannel getFloatChannel(uint index) {
        return cast(GrFloatChannel) getParameter!GrPtr(index);
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
    alias setPtr = setResult!GrPtr;

    void setInt32(int value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setInt64(long value) {
        setResult!GrInt(cast(GrInt) value);
    }

    void setFloat32(float value) {
        setResult!GrFloat(cast(GrFloat) value);
    }

    void setFloat64(double value) {
        setResult!GrFloat(cast(GrFloat) value);
    }

    void setObject(GrObject value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setList(T)(GrList!T value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setIntList(GrIntList value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setFloatList(GrFloatList value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setStringList(GrStringList value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setObjectList(GrObjectList value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setIntChannel(GrIntChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    void setFloatChannel(GrFloatChannel value) {
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

    GrIntList getIntListVariable(string name) {
        return _context.engine.getIntListVariable(name);
    }

    GrFloatList getFloatListVariable(string name) {
        return _context.engine.getFloatListVariable(name);
    }

    GrStringList getStringListVariable(string name) {
        return _context.engine.getStringListVariable(name);
    }

    GrObjectList getObjectListVariable(string name) {
        return _context.engine.getObjectListVariable(name);
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

    void setIntListVariable(string name, GrIntList value) {
        _context.engine.setIntListVariable(name, value);
    }

    void setFloatListVariable(string name, GrFloatList value) {
        _context.engine.setFloatListVariable(name, value);
    }

    void setStringListVariable(string name, GrStringList value) {
        _context.engine.setStringListVariable(name, value);
    }

    void setObjectListVariable(string name, GrObjectList value) {
        _context.engine.setObjectListVariable(name, value);
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

    /**
	Spawn a new coroutine registered as an action. \
	The action's name must be mangled with its signature.
	---
	action myAction() {
		trace("myAction was created !");
	}
	---
	*/
    GrContext callAction(string mangledName) {
        return _context.engine.callAction(mangledName);
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
