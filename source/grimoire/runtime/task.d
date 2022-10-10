/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.task;

import grimoire.assembly;

import grimoire.runtime.engine;
import grimoire.runtime.value;
import grimoire.runtime.string;
import grimoire.runtime.list;
import grimoire.runtime.channel;
import grimoire.runtime.object;

/**
Represents a single function task in the callStack.
*/
struct GrStackFrame {
    /// Size of the locals in the calling function.
    uint localStackSize;
    /// PC to jumps back to.
    uint retPosition;
    /// All current function deferred blocks.
    uint[] deferStack;
    /// All current function exception handling blocks.
    uint[] exceptionHandlers;
}

/**
Snapshot of the task's state. \
Used when we need to restore the task to a previous state.
*/
struct GrTaskState {
    /// Current expression stack top
    int stackPos;

    /// Callstack
    GrStackFrame stackFrame;

    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackFramePos;

    /// Local variables: Access with locals[localsPos + variableIndex]
    uint localsPos;
}

/**
Pause the associated task.
*/
abstract class GrBlocker {
    /// Update the state, returns true if the task is still paused.
    bool run();
}

/**
Coroutines are tasks that hold local data.
*/
final class GrTask {
    /// Default ctor.
    this(GrEngine engine_) {
        engine = engine_;
        setupCallStack(4);
        setupStack(8);
        setupLocals(2);
    }

    /// Parent engine where the task is running.
    GrEngine engine;

    /// Local variables
    GrValue[] locals;

    /// Callstack
    GrStackFrame[] callStack;

    /// Expression stack.
    GrValue[] stack;

    /// Operation pointer.
    uint pc;
    /// Local variables: Access with locals[localsPos + variableIndex]
    uint localsPos;
    /// Stack frame pointer for the current function.
    /// Each function takes 2 integer: the return pc, and the local variable size.
    uint stackFramePos;

    /// Current expression stack top
    int stackPos = -1;

    /// Kill state, unwind the call stack and call all registered deferred statements.
    bool isKilled;

    /// An exception has been raised an is not caught.
    bool isPanicking;

    /// Set when the task is in a select/case statement.
    /// Then, the task is not stopped by a blocking channel.
    bool isEvaluatingChannel;

    /// Set when the task is forced to yield by a blocking channel.
    /// Release only when the channel is ready.
    bool isLocked;

    /// When evaluating, a blocking jump to this position will occur instead of blocking.
    uint selectPositionJump;

    /// The task will block until the blocker is cleared.
    GrBlocker blocker;

    /// Backup to restore stack state after select evaluation.
    GrTaskState[] states;

    /// Current callstack max depth.
    uint callStackLimit;
    /// Current max local variable available.
    uint localsLimit;

    /// Initialize the call stacks.
    void setupCallStack(uint size) {
        callStackLimit = size;
        callStack = new GrStackFrame[callStackLimit];
    }

    /// Initialize the expression stacks.
    void setupStack(uint size) {
        stack = new GrValue[size];
    }

    /// Initialize the local variable stacks.
    void setupLocals(uint size) {
        localsLimit = size;
        locals = new GrValue[localsLimit];
    }

    /// Double the current callstack size.
    void doubleCallStackSize() {
        callStackLimit <<= 1;
        callStack.length = callStackLimit;
    }

    /// Double the current integer locals stacks' size.
    void doubleLocalsStackSize(uint localsStackSize) {
        while (localsStackSize >= localsLimit)
            localsLimit <<= 1;
        locals.length = localsLimit;
    }

    alias setValue = setParameter!GrValue;
    alias setBool = setParameter!GrBool;
    alias setInt = setParameter!GrInt;
    alias setReal = setParameter!GrReal;
    alias setPointer = setParameter!GrPointer;

    pragma(inline) void setObject(GrObject value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(GrString value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setString(GrStringValue value) {
        setParameter!GrPointer(cast(GrPointer) new GrString(value));
    }

    pragma(inline) void setList(GrList value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setList(GrValue[] value) {
        setParameter!GrPointer(cast(GrPointer) new GrList(value));
    }

    pragma(inline) void setChannel(GrChannel value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) void setEnum(T)(T value) {
        setParameter!GrInt(cast(GrInt) value);
    }

    pragma(inline) void setForeign(T)(T value) {
        setParameter!GrPointer(cast(GrPointer) value);
    }

    pragma(inline) private void setParameter(T)(T value) {
        static if (is(T == GrInt) || is(T == GrBool)) {
            stackPos++;
            stack[stackPos].setInt(value);
        }
        else static if (is(T == GrReal)) {
            stackPos++;
            stack[stackPos].setReal(value);
        }
        else static if (is(T == GrPointer)) {
            stackPos++;
            stack[stackPos].setPointer(value);
        }
    }

    /// Register the current state of the task
    void pushState() {
        GrTaskState state;
        state.stackPos = stackPos;
        state.stackFramePos = stackFramePos;
        state.stackFrame = callStack[stackFramePos];
        state.localsPos = localsPos;
        states ~= state;
    }

    /// Restore the last state of the task
    void restoreState() {
        if (!states.length)
            throw new Exception("Fatal error: pop task state");
        GrTaskState state = states[$ - 1];
        stackPos = state.stackPos;
        stackFramePos = state.stackFramePos;
        localsPos = state.localsPos;
        callStack[stackFramePos] = state.stackFrame;
    }

    /// Remove last state of the task
    void popState() {
        states.length--;
    }

    /// Lock the task until the blocker is cleared
    void block(GrBlocker blocker_) {
        blocker = blocker_;
    }

    /// Unlock the task from the blocker
    void unblock() {
        blocker = null;
    }

    /// Dump stacks info
    string dump() {
        import std.conv : to;

        string result = "Task Dump:";
        result ~= "\nfstack: " ~ to!string(stack[0 .. (stackPos + 1)]);
        result ~= "\nistack: " ~ to!string(stack[0 .. (stackPos + 1)]);
        result ~= "\nsstack: " ~ to!string(stack[0 .. (stackPos + 1)]);
        result ~= "\nostack: " ~ to!string(stack[0 .. (stackPos + 1)]);
        return result;
    }
}
