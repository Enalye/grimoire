/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.conv : to;
import grimoire.assembly;
import grimoire.compiler;
import grimoire.runtime.task, grimoire.runtime.object, grimoire.runtime.channel;

/// Primitive type.
alias GrCallback = void function(GrCall);
private GrValue[128] _outputs;

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
        GrValue[] _inputs;
    }

    @property {
        /// Current task running the primitive.
        GrTask task() {
            return _task;
        }

        /// Extra type compiler information.
        GrString meta() const {
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

        const int stackIndex = (_task.stackPos + 1) - _params;
        _inputs = _task.stack[stackIndex .. _task.stackPos + 1];
        _callback(this);

        _task.stack.length = stackIndex + _results + 1;
        _task.stack[stackIndex .. stackIndex + _results] = _outputs[0 .. _results];
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

    alias getValue = getParameter!GrValue;
    alias getBool = getParameter!GrBool;
    alias getInt = getParameter!GrInt;
    alias getReal = getParameter!GrReal;
    alias getPtr = getParameter!GrPtr;

    pragma(inline) GrBool isNull(uint index)
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        return _inputs[index].isNull();
    }

    pragma(inline) int getInt32(uint index) {
        return cast(int) getParameter!GrInt(index);
    }

    pragma(inline) long getInt64(uint index) {
        return cast(long) getParameter!GrInt(index);
    }

    pragma(inline) float getReal32(uint index) {
        return cast(float) getParameter!GrReal(index);
    }

    pragma(inline) double getReal64(uint index) {
        return cast(double) getParameter!GrReal(index);
    }

    pragma(inline) GrObject getObject(uint index) {
        return cast(GrObject) getParameter!GrPtr(index);
    }

    pragma(inline) GrString getString(uint index) {
        return (cast(GrStringWrapper) getParameter!GrPtr(index)).data;
    }

    pragma(inline) GrArray getArray(uint index) {
        return (cast(GrArrayWrapper) getParameter!GrPtr(index)).data;
    }

    pragma(inline) GrChannel getChannel(uint index) {
        return cast(GrChannel) getParameter!GrPtr(index);
    }

    pragma(inline) T getEnum(T)(uint index) {
        return cast(T) getParameter!GrInt(index);
    }

    pragma(inline) T getForeign(T)(uint parameter) {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getParameter!GrPtr(parameter);
    }

    pragma(inline) private T getParameter(T)(uint index)
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        static if (is(T == GrValue)) {
            return _inputs[index];
        }
        else static if (is(T == GrInt)) {
            return _inputs[index].getInt();
        }
        else static if (is(T == GrBool)) {
            return _inputs[index].getInt() > 0;
        }
        else static if (is(T == GrReal)) {
            return _inputs[index].getReal();
        }
        else static if (is(T == GrPtr)) {
            return _inputs[index].getPtr();
        }
    }

    alias setValue = setResult!GrValue;
    alias setBool = setResult!GrBool;
    alias setInt = setResult!GrInt;
    alias setReal = setResult!GrReal;
    alias setPtr = setResult!GrPtr;

    pragma(inline) void setNull() {
        _outputs[_results].setNull();
    }

    pragma(inline) void setInt32(int value) {
        setResult!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setInt64(long value) {
        setResult!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setReal32(float value) {
        setResult!GrReal(cast(GrReal) value);
    }

    pragma(inline) void setReal64(double value) {
        setResult!GrReal(cast(GrReal) value);
    }

    pragma(inline) void setObject(GrObject value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    pragma(inline) void setString(GrString value) {
        setResult!GrPtr(cast(GrPtr) new GrStringWrapper(value));
    }

    pragma(inline) void setArray(GrArray value) {
        setResult!GrPtr(cast(GrPtr) new GrArrayWrapper(value));
    }

    pragma(inline) void setChannel(GrChannel value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    pragma(inline) void setEnum(T)(T value) {
        setResult!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setForeign(T)(T value) {
        setResult!GrPtr(cast(GrPtr) value);
    }

    pragma(inline) private void setResult(T)(T value) {
        static if (is(T == GrValue)) {
            _outputs[_results] = value;
        }
        else static if (is(T == GrInt)) {
            _outputs[_results].setInt(value);
        }
        else static if (is(T == GrBool)) {
            _outputs[_results].setInt(cast(GrInt) value);
        }
        else static if (is(T == GrReal)) {
            _outputs[_results].setReal(value);
        }
        else static if (is(T == GrStringWrapper)) {
            _outputs[_results].setString(value);
        }
        else static if (is(T == GrPtr)) {
            _outputs[_results].setPtr(value);
        }
        _results++;
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

    GrArray getArrayVariable(string name) {
        return _task.engine.getArrayVariable(name);
    }

    GrPtr getPtrVariable(string name) {
        return _task.engine.getPtrVariable(name);
    }

    GrObject getObjectVariable(string name) {
        return _task.engine.getObjectVariable(name);
    }

    GrChannel getChannelVariable(string name) {
        return _task.engine.getChannelVariable(name);
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

    void setArrayVariable(string name, GrArray value) {
        _task.engine.setArrayVariable(name, value);
    }

    void setPtrVariable(string name, GrPtr value) {
        _task.engine.setPtrVariable(name, value);
    }

    void setObjectVariable(string name, GrObject value) {
        _task.engine.setObjectVariable(name, value);
    }

    void setChannelVariable(string name, GrChannel value) {
        _task.engine.setChannelVariable(name, value);
    }

    void setEnumVariable(T)(string name, T value) {
        _task.engine.setEnumVariable(name, value);
    }

    void setForeignVariable(T)(string name, T value) {
        _task.engine.setForeignVariable(name, value);
    }

    private {
        GrString _message;
        bool _hasError;
    }

    /// Does not actually send the error to the task.
    /// Because the stacks would be in an undefined state.
    /// So we wait until the primitive is finished before calling dispatchError().
    void raise(GrString message) {
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
