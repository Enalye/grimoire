/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.conv : to;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.runtime.task, grimoire.runtime.array, grimoire.runtime.object,
    grimoire.runtime.channel;

/// Primitive type.
alias GrCallback = void function(GrCall);

/// Primitive task.
final class GrCall {
    private {
        GrTask _task;
        GrCallback _callback;

        uint[] _parameters;
        int _params;
        int _results;
        bool _isInitialized;
        string[] _inSignature, _outSignature;
    }

    @property {
        /// Current task running the primitive.
        GrTask task() {
            return _task;
        }

        /// Extra type compiler information.
        string meta() const {
            return _task.engine.meta;
        }
    }

    package(grimoire) this(GrCallback callback, const ref GrBytecode.PrimitiveReference primRef) {
        _callback = callback;

        _parameters = primRef.parameters.dup;

        _params = cast(int) primRef.params;

        _inSignature = primRef.inSignature.dup;
        _outSignature = primRef.outSignature.dup;
    }

    /// The actual runtime call to the primitive.
    void call(GrTask task) {
        _results = 0;
        _hasError = false;
        _task = task;

        _callback(this);

        _task.stackPos -= (_params - _results);

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
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        static if (is(T == GrInt)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an int");
            return _task.stack[(_task.stackPos - _params) + (_parameters[index] & 0xFFFF) + 1]
                .ivalue;
        }
        else static if (is(T == GrBool)) {
            if ((_parameters[index] & 0x10000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a bool");
            return _task.stack[(_task.stackPos - _params) + (
                    _parameters[index] & 0xFFFF) + 1].ivalue > 0;
        }
        else static if (is(T == GrReal)) {
            if ((_parameters[index] & 0x20000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a GrReal");
            return _task.stack[(_task.stackPos - _params) + (_parameters[index] & 0xFFFF) + 1]
                .rvalue;
        }
        else static if (is(T == GrString)) {
            if ((_parameters[index] & 0x40000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not a string");
            return _task.stack[(_task.stackPos - _params) + (_parameters[index] & 0xFFFF) + 1]
                .svalue;
        }
        else static if (is(T == GrPtr)) {
            if ((_parameters[index] & 0x80000) == 0)
                throw new Exception("parameter " ~ to!string(index) ~ " is not an object");
            return _task.stack[(_task.stackPos - _params) + (_parameters[index] & 0xFFFF) + 1]
                .ovalue;
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
            _results++;
            const size_t idx = (_task.stackPos - _params) + _results;
            if (idx >= _task.stack.length)
                _task.stack.length *= 2;
            _task.stack[idx].ivalue = value;
        }
        else static if (is(T == GrBool)) {
            _results++;
            const size_t idx = (_task.stackPos - _params) + _results;
            if (idx >= _task.stack.length)
                _task.stack.length *= 2;
            _task.stack[idx].ivalue = value ? 1 : 0;
        }
        else static if (is(T == GrReal)) {
            _results++;
            const size_t idx = (_task.stackPos - _params) + _results;
            if (idx >= _task.stack.length)
                _task.stack.length *= 2;
            _task.stack[idx].rvalue = value;
        }
        else static if (is(T == GrString)) {
            _results++;
            const size_t idx = (_task.stackPos - _params) + _results;
            if (idx >= _task.stack.length)
                _task.stack.length *= 2;
            _task.stack[idx].svalue = value;
        }
        else static if (is(T == GrPtr)) {
            _results++;
            const size_t idx = (_task.stackPos - _params) + _results;
            if (idx >= _task.stack.length)
                _task.stack.length *= 2;
            _task.stack[idx].ovalue = value;
        }
    }

    GrBool getBoolVariable(string name) {
        return _task.engine.getBoolVariable(name);
    }

    GrInt getIntVariable(string name) {
        return _task.engine.getIntVariable(name);
    }

    GrReal getRealVariable(string name) {
        return _task.engine.getRealVariable(name);
    }

    GrString getStringVariable(string name) {
        return _task.engine.getStringVariable(name);
    }

    GrPtr getPtrVariable(string name) {
        return _task.engine.getPtrVariable(name);
    }

    GrObject getObjectVariable(string name) {
        return _task.engine.getObjectVariable(name);
    }

    GrIntArray getIntArrayVariable(string name) {
        return _task.engine.getIntArrayVariable(name);
    }

    GrRealArray getRealArrayVariable(string name) {
        return _task.engine.getRealArrayVariable(name);
    }

    GrStringArray getStringArrayVariable(string name) {
        return _task.engine.getStringArrayVariable(name);
    }

    GrObjectArray getObjectArrayVariable(string name) {
        return _task.engine.getObjectArrayVariable(name);
    }

    GrIntChannel getIntChannelVariable(string name) {
        return _task.engine.getIntChannelVariable(name);
    }

    GrRealChannel getRealChannelVariable(string name) {
        return _task.engine.getRealChannelVariable(name);
    }

    GrStringChannel getStringChannelVariable(string name) {
        return _task.engine.getStringChannelVariable(name);
    }

    GrObjectChannel getObjectChannelVariable(string name) {
        return _task.engine.getObjectChannelVariable(name);
    }

    T getEnumVariable(T)(string name) {
        return _task.engine.getEnumVariable(T)(name);
    }

    T getForeignVariable(T)(string name) {
        return _task.engine.getForeignVariable(T)(name);
    }

    void setBoolVariable(string name, GrBool value) {
        _task.engine.setBoolVariable(name, value);
    }

    void setIntVariable(string name, GrInt value) {
        _task.engine.setIntVariable(name, value);
    }

    void setRealVariable(string name, GrReal value) {
        _task.engine.setRealVariable(name, value);
    }

    void setStringVariable(string name, GrString value) {
        _task.engine.setStringVariable(name, value);
    }

    void setPtrVariable(string name, GrPtr value) {
        _task.engine.setPtrVariable(name, value);
    }

    void setObjectVariable(string name, GrObject value) {
        _task.engine.setObjectVariable(name, value);
    }

    void setIntArrayVariable(string name, GrIntArray value) {
        _task.engine.setIntArrayVariable(name, value);
    }

    void setRealArrayVariable(string name, GrRealArray value) {
        _task.engine.setRealArrayVariable(name, value);
    }

    void setStringArrayVariable(string name, GrStringArray value) {
        _task.engine.setStringArrayVariable(name, value);
    }

    void setObjectArrayVariable(string name, GrObjectArray value) {
        _task.engine.setObjectArrayVariable(name, value);
    }

    void setIntChannelVariable(string name, GrIntChannel value) {
        _task.engine.setIntChannelVariable(name, value);
    }

    void setRealChannelVariable(string name, GrRealChannel value) {
        _task.engine.setRealChannelVariable(name, value);
    }

    void setStringChannelVariable(string name, GrStringChannel value) {
        _task.engine.setStringChannelVariable(name, value);
    }

    void setObjectChannelVariable(string name, GrObjectChannel value) {
        _task.engine.setObjectChannelVariable(name, value);
    }

    void setEnumVariable(T)(string name, T value) {
        _task.engine.setEnumVariable(name, value);
    }

    void setForeignVariable(T)(string name, T value) {
        _task.engine.setForeignVariable(name, value);
    }

    private {
        string _message;
        bool _hasError;
    }

    /// Does not actually send the error to the task.
    /// Because the stacks would be in an undefined state.
    /// So we wait until the primitive is finished before calling dispatchError().
    void raise(string message) {
        _message = message;
        _hasError = true;
    }

    private void dispatchError() {
        _task.engine.raise(_task, _message);

        //The task is still in a primitive call
        //and will increment the pc, so we prevent that.
        _task.pc--;
    }

    /// Create a new object of type `typeName`.
    GrObject createObject(string name) {
        return _task.engine.createObject(name);
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
    GrTask callEvent(string mangledName) {
        return _task.engine.callEvent(mangledName);
    }

    /**
	Spawn a new coroutine at an arbitrary address. \
	The address needs to correspond to the start of a task, else the VM will crash. \
	*/
    GrTask callAddress(uint pc) {
        return _task.engine.callAddress(pc);
    }

    /// Pause the current task.
    void block(GrBlocker blocker) {
        _task.block(blocker);
    }
}
