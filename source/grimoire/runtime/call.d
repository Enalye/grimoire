/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.call;

import std.conv : to;

import grimoire.assembly, grimoire.compiler;

import grimoire.runtime.task;
import grimoire.runtime.event;
import grimoire.runtime.value;
import grimoire.runtime.object;
import grimoire.runtime.string;
import grimoire.runtime.list;
import grimoire.runtime.channel;

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
        GrStringValue meta() const {
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
    alias getFloat = getParameter!GrFloat;
    alias getPointer = getParameter!GrPointer;

    pragma(inline) GrBool isNull(uint index)
    in (index < _parameters.length,
        "parameter index `" ~ to!string(index) ~ "` exceeds the number of parameters") {
        return _inputs[index].isNull();
    }

    pragma(inline) T getEnum(T)(uint index) const {
        return cast(T) getParameter!GrInt(index);
    }

    pragma(inline) GrObject getObject(uint index) const {
        return cast(GrObject) getParameter!GrPointer(index);
    }

    pragma(inline) GrString getString(uint index) const {
        return cast(GrString) getParameter!GrPointer(index);
    }

    pragma(inline) GrList getList(uint index) const {
        return cast(GrList) getParameter!GrPointer(index);
    }

    pragma(inline) GrChannel getChannel(uint index) const {
        return cast(GrChannel) getParameter!GrPointer(index);
    }

    pragma(inline) GrEvent getEvent(uint index) const {
        return _task.engine.getEvent(getParameter!GrInt(index));
    }

    pragma(inline) T getNative(T)(uint index) const {
        // We cast to object first to avoid a crash when casting to a parent class
        return cast(T) cast(Object) getParameter!GrPointer(index);
    }

    pragma(inline) private T getParameter(T)(uint index) const
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
        else static if (is(T == GrFloat)) {
            return _inputs[index].getFloat();
        }
        else static if (is(T == GrPointer)) {
            return _inputs[index].getPointer();
        }
    }

    alias setValue = setResult!GrValue;
    alias setBool = setResult!GrBool;
    alias setInt = setResult!GrInt;
    alias setFloat = setResult!GrFloat;
    alias setPointer = setResult!GrPointer;

    pragma(inline) void setNull() {
        _outputs[_results].setNull();
        _results++;
    }

    pragma(inline) void setEnum(T)(T value) {
        setResult!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setString(GrString value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(GrStringValue value) {
        setResult!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setList(GrList value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setList(GrValue[] value) {
        setResult!GrPointer(cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannel(GrChannel value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setObject(GrObject value) {
        setResult!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setNative(T)(T value) {
        setResult!GrPointer(cast(GrPointer) value);
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
        else static if (is(T == GrFloat)) {
            _outputs[_results].setFloat(value);
        }
        else static if (is(T == GrString)) {
            _outputs[_results].setString(value);
        }
        else static if (is(T == GrPointer)) {
            _outputs[_results].setPointer(value);
        }
        _results++;
    }

    GrBool getBoolVariable(string name) const {
        return _task.engine.getBoolVariable(name);
    }

    GrInt getIntVariable(string name) const {
        return _task.engine.getIntVariable(name);
    }

    T getEnumVariable(T)(string name) const {
        return cast(T) _task.engine.getEnumVariable(T)(name);
    }

    GrFloat getFloatVariable(string name) const {
        return _task.engine.getFloatVariable(name);
    }

    GrPointer getPointerVariable(string name) const {
        return cast(GrPointer) _task.engine.getPointerVariable(name);
    }

    GrString getStringVariable(string name) const {
        return cast(GrString) _task.engine.getStringVariable(name);
    }

    GrList getListVariable(string name) const {
        return cast(GrList) _task.engine.getListVariable(name);
    }

    GrChannel getChannelVariable(string name) const {
        return cast(GrChannel) _task.engine.getChannelVariable(name);
    }

    GrObject getObjectVariable(string name) const {
        return cast(GrObject) _task.engine.getObjectVariable(name);
    }

    T getNativeVariable(T)(string name) const {
        return cast(T) _task.engine.getNativeVariable(T)(name);
    }

    void setBoolVariable(string name, GrBool value) {
        _task.engine.setBoolVariable(name, value);
    }

    void setIntVariable(string name, GrInt value) {
        _task.engine.setIntVariable(name, value);
    }

    void setFloatVariable(string name, GrFloat value) {
        _task.engine.setFloatVariable(name, value);
    }

    void setStringVariable(string name, GrStringValue value) {
        _task.engine.setStringVariable(name, value);
    }

    void setListVariable(string name, GrValue[] value) {
        _task.engine.setListVariable(name, value);
    }

    void setPointerVariable(string name, GrPointer value) {
        _task.engine.setPointerVariable(name, value);
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

    void setNativeVariable(T)(string name, T value) {
        _task.engine.setNativeVariable(name, value);
    }

    private {
        GrStringValue _message;
        bool _hasError;
    }

    /// Does not actually send the error to the task.
    /// Because the stacks would be in an undefined state.
    /// So we wait until the primitive is finished before calling dispatchError().
    void raise(GrString message) {
        _message = message.data;
        _hasError = true;
    }
    /// Ditto
    void raise(GrStringValue message) {
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
    GrTask callEvent(const string name, const GrType[] signature = [], GrValue[] parameters = [
        ]) {
        return _task.engine.callEvent(name, signature, parameters);
    }
    /// Ditto
    GrTask callEvent(const GrEvent event, GrValue[] parameters = []) {
        return _task.engine.callEvent(event, parameters);
    }

    /// Pause the current task.
    void block(GrBlocker blocker) {
        _task.block(blocker);
    }
}
